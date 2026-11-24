# FinControl — Documentação Técnica de Implementação, Privacidade e Testes

**Projeto semestral — Bloco 3 — Gestão e Proteção de Dados**  
**Curso/turma:** SIS923 — Unex Vitória da Conquista  
**Professor:** Wallas Froes de Oliveira  
**Integrantes:** Hélio, Kevilyn, Rodrigo, Thainá, Murillo e Marcelo  
**Data de consolidação:** 24 de novembro de 2026  
**Versão:** 1.0

> Antes da entrega, substituir os primeiros nomes pelos nomes completos, acrescentar matrículas, URL do repositório, URL pública do sistema e hash do commit usado nas evidências.

## Resumo executivo

A FinControl é um MVP acadêmico de governança e privacidade aplicado ao compartilhamento de dados financeiros. O titular autentica-se, simula a conexão de uma instituição, escolhe categorias, finalidade e prazo, registra uma autorização, acompanha sua vigência, consulta eventos e revoga o consentimento. O sistema também oferece política de privacidade, pedidos de acesso, correção e exclusão, protocolo e fila restrita ao suporte.

O aplicativo foi desenvolvido em Flutter/Dart e utiliza Supabase Auth, PostgREST e PostgreSQL. O backend aplica os controles críticos: Row Level Security (RLS) separa registros por titular; Role-Based Access Control (RBAC) restringe o suporte; funções transacionais registram revogação e histórico; o texto dos pedidos é cifrado com AES-256 por `pgcrypto`; e o identificador do titular é mascarado na fila.

O projeto utiliza exclusivamente contas, instituições, saldos e transações fictícias. Biometria e conexão Open Finance são jornadas visuais simuladas. Não existe acesso a conta bancária, biometria de dispositivo ou Open Finance real. Trata-se de protótipo acadêmico funcional, compatível com TRL 4 e potencialmente TRL 5 em ambiente controlado, não pronto para produção.

---

# 1. Objetivo, escopo e limitações

## 1.1 Objetivo

Demonstrar como governança, transparência, minimização, segurança e controle do titular podem ser incorporados desde a concepção de um produto financeiro. O problema abordado é a dificuldade de compreender quais dados foram autorizados, para quem, com qual finalidade, por quanto tempo e como revogar a decisão.

## 1.2 Funcionalidades implementadas

- autenticação por e-mail/senha e restauração da sessão;
- biometria visual simulada, sem capturar característica biométrica;
- conexão Open Finance simulada com Banco Alfa;
- autorização com instituição, finalidade, categorias, validade e revisão;
- registro da versão do texto de aceite;
- painel responsivo com estados ativa, revogada e expirada;
- atualização automática e manual;
- histórico de aceite, acesso, expiração e revogação;
- dados financeiros fictícios somente para autorização ativa e válida;
- revogação atômica com confirmação;
- política de privacidade;
- pedidos de acesso, correção e exclusão com protocolo;
- fila de suporte protegida por RBAC;
- identificador mascarado e texto do pedido cifrado;
- exclusão de autorizações/eventos ao concluir pedido de exclusão;
- interface mobile first e build Web preparado para EasyPanel.

## 1.3 Fora do escopo

- Open Finance real, mTLS e certificados regulatórios;
- biometria real ou template biométrico;
- dados e credenciais bancárias reais;
- publicação/validação nas lojas;
- KMS/HSM externo, pentest, SOC, SLA ou monitoramento 24x7;
- parecer jurídico de conformidade integral.

## 1.4 Enquadramento dos dados

E-mail, identificador, autorizações, eventos e pedidos são tratados como dados pessoais no cenário. Dados financeiros exigem proteção reforçada, mas não são automaticamente dados pessoais sensíveis pelo rol do art. 5º, II, da LGPD. Como o MVP usa dados fictícios, o consentimento representa uma simulação técnica dos arts. 7º, I, 8º e 9º, sem afirmar uma operação bancária real.

---

# 2. Arquitetura de implementação

## 2.1 Visão geral

```text
Usuário Web/Android
       │
       ▼
Flutter / Dart — telas, feedback, validações e navegação
       │ HTTPS + JWT
       ▼
Supabase Auth — autenticação e sessão
       │
       ▼
PostgREST / RPC — RLS, RBAC e funções protegidas
       │
       ▼
PostgreSQL — autorizações, eventos, pedidos, papéis e chave privada
```

O cliente recebe somente URL e chave pública `anon`/publishable por `--dart-define`. Senha do PostgreSQL, `service_role`, segredo JWT e chave de criptografia não entram no aplicativo. Em Web, URL e chave pública ficam visíveis no JavaScript; a proteção efetiva depende de RLS, privilégios e RPCs.

## 2.2 Organização do código

| Diretório | Responsabilidade |
|---|---|
| `lib/config` | valida configuração pública |
| `lib/models` | converte respostas em objetos de domínio |
| `lib/services` | concentra Auth, consultas, RPCs e erros |
| `lib/screens` | login, conexão, consentimento, painel, privacidade, pedidos e suporte |
| `lib/theme` | cores, tipografia e Material 3 |
| `lib/widgets` | logo, responsividade e estados de tela |
| `supabase/migrations` | tabelas, constraints, RLS, RBAC, cifra e funções |
| `supabase/tests` | preparações controladas de testes |
| `scripts` | testes de RLS/RBAC sem persistir senhas |
| `test` | testes automatizados de configuração/modelos |

As telas não acessam SQL diretamente. Repositórios usam o SDK Supabase, centralizando comunicação e erros; regras críticas permanecem no banco.

## 2.3 Modelo de dados

| Objeto | Finalidade e controle |
|---|---|
| `institutions` | catálogo; contém Banco Alfa fictício; leitura autenticada |
| `authorizations` | titular, instituição, finalidade, categorias, aceite, validade, estado e termos |
| `authorization_events` | `accepted`, `data_accessed`, `expired`, `revoked`; titular possui leitura |
| `user_roles` | papel `support`; sem leitura direta pelo cliente |
| `rights_requests` | protocolo, titular, tipo, texto cifrado, estado e datas |
| `private.field_keys` | chave aleatória de 32 bytes, inacessível ao cliente |

```text
auth.users 1 ── N authorizations N ── 1 institutions
     │                 │
     │                 └── 1:N authorization_events
     ├── 1:N rights_requests
     └── 0:1 user_roles

private.field_keys ── usada apenas pelas funções de cifra/decifra
```

## 2.4 Validações

- finalidade de 5 a 240 caracteres;
- 1 a 10 categorias limitadas a `Saldo`, `Transações`, `Dados da conta`;
- validade posterior ao aceite;
- estado limitado a `active`, `revoked`, `expired`;
- `revoked_at` coerente com o estado;
- pedido limitado a `access`, `correction`, `deletion`;
- estado do pedido limitado a `submitted`, `in_review`, `completed`, `rejected`;
- `completed_at` coerente com conclusão;
- exclusão em cascata entre autorização e eventos.

## 2.5 RLS, privilégios e RBAC

`authorizations` usa `auth.uid() = owner_id` para leitura e inserção. Eventos permitem somente leitura ao titular. Não há política de `UPDATE`/`DELETE` para o cliente; mudanças legítimas passam por funções controladas. `user_roles` não é exposta.

`is_support()` consulta o papel no servidor. `get_support_queue()` e `update_rights_request_status()` rejeitam não autorizados com `42501`. Esconder o menu melhora a experiência, mas não substitui o backend.

## 2.6 Funções principais

| Função | Regra aplicada |
|---|---|
| `refresh_my_authorization_expirations()` | expira somente registros do usuário e cria evento |
| `revoke_authorization(uuid)` | valida autenticação, titular, estado e prazo; revoga e audita na mesma transação |
| `get_simulated_financial_data(uuid)` | retorna fictícios apenas para autorização própria, ativa e válida |
| `is_support()` | verifica papel no servidor |
| `submit_rights_request(text,text)` | valida, gera protocolo e cifra antes da inserção |
| `get_support_queue()` | exige suporte, decifra internamente e mascara o dono |
| `update_rights_request_status(uuid,text)` | controla transição e executa descarte na exclusão concluída |

Funções `SECURITY DEFINER` usam `set search_path = ''` e nomes qualificados. Privilégios são revogados de `public` e concedidos somente quando necessários.

## 2.7 Fluxos

```text
Login → biometria simulada → conexão simulada → dados/finalidade/prazo
→ revisão → aceite → INSERT com RLS → evento accepted

Painel → atualizar expiradas → detalhes/histórico → confirmar revogação
→ RPC valida → UPDATE + evento revoked → acesso bloqueado

Pedido → validação → AES-256 → protocolo → fila com dono mascarado
→ análise → conclusão → descarte se o tipo for exclusão
```

---

# 3. Ciclo de vida e responsabilidades

| Fase | Dados/operação | Controle | Gestor de Dados | DPO/Encarregado |
|---|---|---|---|---|
| Coleta | e-mail, finalidade, categorias, prazo, aceite e pedido | campos limitados e revisão | define padrão, qualidade e catálogo | valida finalidade, necessidade e transparência |
| Armazenamento | PostgreSQL e pedido cifrado | constraints, RLS, RBAC e AES-256 | mantém integridade/acesso | fiscaliza retenção e minimização |
| Uso | painel, histórico, expiração e saldo fictício | RPC valida JWT, dono, estado e prazo | monitora uso e qualidade | verifica compatibilidade com finalidade |
| Compartilhamento | Banco Alfa simulado | categorias autorizadas; nenhum envio real | controla interface/rastreabilidade | fiscaliza consentimento específico |
| Retenção | registros durante a demonstração | datas, estados e eventos | aplica política | revisa necessidade/direitos |
| Descarte | exclusão concluída remove autorizações/eventos | RPC de suporte e cascata | executa/comprova | acompanha solicitação e exceções |

O Gestor responde por operação, qualidade, catálogo e retenção. O DPO orienta conformidade, fiscaliza finalidade e transparência, recebe titulares e participa de riscos/incidentes.

---

# 4. Política de privacidade e consentimento

**Controlador no cenário:** FinControl Dados — organização fictícia.  
**Canal acadêmico:** `suporte.fincontrol@example.test`.  
**Ambiente:** protótipo com contas e dados fictícios.

## 4.1 Dados tratados

- identificador e e-mail;
- instituição fictícia;
- finalidade, categorias, prazo, estado e termos;
- eventos e datas;
- tipo, protocolo, estado e texto dos pedidos;
- papel administrativo fictício.

## 4.2 Finalidades

- autenticar e manter sessão;
- demonstrar consentimento granular/revogável;
- exibir autorizações e fictícios;
- registrar decisões;
- atender pedidos simulados;
- testar privacidade e segurança.

## 4.3 Base considerada

O fluxo simula consentimento específico, informado e revogável (arts. 7º, I, 8º e 9º) e direitos do art. 18. Dados fictícios e finalidade acadêmica não equivalem a parecer jurídico ou conformidade de produção.

## 4.4 Compartilhamento, retenção e descarte

Banco Alfa, biometria e Open Finance são simulados; não há envio a banco real nem venda. Registros permanecem durante a avaliação. Ao concluir exclusão, autorizações/eventos são removidos e o protocolo/status permanece como evidência mínima. Produção exigiria tabela formal de temporalidade, fundamento, rotina, backup compatível e aprovação do DPO.

## 4.5 Direitos e prova do consentimento

O titular solicita acesso, correção ou exclusão, recebe protocolo e acompanha estado; também revoga autorização ativa. Antes do aceite, vê instituição, finalidade, categorias, prazo e termos `1.0`. O banco registra `owner_id`, `accepted_at`, `valid_until`, `terms_version`; um trigger cria o evento. Revogação é acessível, confirmada e registra data/evento.

---

# 5. Tríade CID e Privacy by Design

| Dimensão | Aplicação | Evidência |
|---|---|---|
| Confidencialidade | Auth, HTTPS, RLS, RBAC, cifra e máscara | B não leu A; fila retornou 403; campo cifrado bloqueado |
| Integridade | PK/FK, constraints e transações | revogação gerou estado/evento; DELETE do evento retornou 403 |
| Disponibilidade | erro, nova tentativa, atualização e build reproduzível | falha detectada e serviço retomado com 200 |

## 5.1 Concepção, trânsito e repouso

**Concepção:** dados fictícios, categorias limitadas, finalidade/prazo obrigatórios, privilégio mínimo, política, revisão, confirmação destrutiva e rotulagem das simulações.

**Trânsito:** HTTPS, JWT administrado pelo SDK, nenhum segredo administrativo ou credencial bancária no cliente/log.

**Repouso:** RLS, privilégios, `pgp_sym_encrypt` com `cipher-algo=aes256`, chave de 32 bytes em schema privado. Limitação: não há KMS/HSM ou rotação automática.

## 5.2 Mascaramento/pseudonimização

`get_support_queue()` devolve `left(md5(owner_id), 6) || '***'`, como `a1b2c3***`, em vez do UUID. É mascaramento com representação pseudonimizada: reduz exposição, mas não é anonimização irreversível, pois o backend mantém o vínculo. Isso atende ao requisito de anonimização, pseudonimização **e/ou** mascaramento.

---

# 6. RIPD/DPIA resumido

O tratamento simulado cobre autenticação, consentimento, histórico, fictícios e direitos. Titulares são contas A/B; suporte representa operador interno. Não há crianças, biometria capturada, dados reais ou decisão de crédito.

Escala: probabilidade (P) e impacto (I) de 1 a 3; `P × I`: 1–2 baixo, 3–4 médio, 6–9 alto.

| Risco | P | I | Inicial | Salvaguarda | Residual | Responsável |
|---|---:|---:|---:|---|---:|---|
| leitura entre titulares | 2 | 3 | 6 alto | RLS/JWT/teste | 2 baixo | Gestor técnico |
| inserir em nome de terceiro | 2 | 3 | 6 alto | `WITH CHECK` | 2 baixo | Backend/DBA |
| uso após revogação/expiração | 2 | 3 | 6 alto | RPC e expiração | 2 baixo | Backend |
| abuso do suporte | 2 | 3 | 6 alto | RBAC e máscara | 3 médio | Segurança/DPO |
| exposição do pedido | 2 | 3 | 6 alto | AES-256/schema privado | 2 baixo | DBA |
| segredo no cliente/log | 2 | 3 | 6 alto | somente `anon`, ignore e varredura | 2 baixo | DevOps |
| exclusão indevida | 2 | 3 | 6 alto | RBAC, confirmação e RPC | 3 médio | Suporte/Gestor |
| indisponibilidade | 2 | 2 | 4 médio | feedback e retomada | 3 médio | Operações |
| suporte comprometido | 1 | 3 | 3 médio | RBAC/minimização; sem MFA real | 3 médio | Segurança/DPO |
| configuração incorreta | 2 | 3 | 6 alto | migrações, testes e guia | 3 médio | DevOps/DBA |

**Conclusão:** risco residual aceitável apenas para ambiente acadêmico fictício. Produção exige revisão jurídica, MFA real, KMS/rotação, pentest, monitoramento, backup testado, RTO/RPO, retenção formal e integração regulatória. Revisar o RIPD em mudança de finalidade, categoria, integração, escala, fornecedor ou incidente.

---

# 7. Contingência

Contingência mantém/restaura operação e não pressupõe violação. Exemplo testado: endpoint indisponível, erro detectado e retomada após restauração.

1. Detectar falha e registrar início/impacto sem segredos.
2. Informar indisponibilidade de forma compreensível.
3. Impedir confirmação ambígua ou repetição insegura.
4. Preservar sessão local sem expor JWT.
5. Restaurar rede, serviço ou configuração.
6. Consultar se a transação anterior foi concluída.
7. Repetir apenas quando seguro e validar integridade.
8. Registrar encerramento.

Antes de produção: definir SLA, RTO, RPO, backup/retenção, responsável, testes, redundância e contatos.

---

# 8. Plano de Resposta a Incidentes — PRI

O PRI responde a acesso indevido, perda, alteração ou divulgação e exige investigação, evidência, avaliação a titulares e possível comunicação.

1. **Preparação:** inventário, responsáveis, contatos, acessos mínimos, backup, logs e exercícios.
2. **Detecção e análise:** validar alerta, severidade, linha do tempo, dados/sistemas/titulares.
3. **Contenção:** bloquear credenciais/rotas, isolar e preservar evidências.
4. **Erradicação:** remover causa, corrigir, rotacionar chaves e revisar acessos.
5. **Recuperação:** restaurar, validar integridade, monitorar e liberar gradualmente.
6. **Pós-incidente:** relatório, causa raiz, lições, correções, RIPD e comunicação.

**Cenário:** conta de suporte comprometida. O líder ativa War Room; técnico revoga sessão/papel e preserva logs; DPO avalia pedidos/titulares; causa é corrigida, credenciais rotacionadas e serviço recuperado sob monitoramento.

---

# 9. War Room / CSIRT

| Papel | Responsabilidades |
|---|---|
| Líder | severidade, convocação, prioridades e linha do tempo |
| Técnico | investigação, contenção, erradicação, restauração e evidência |
| DPO | impacto, direitos, ANPD/titulares e RIPD |
| Comunicação | mensagens aprovadas, canal oficial e atualizações |

## 9.1 Modelo de comunicado

> **Assunto: Atualização sobre incidente de segurança na FinControl**  
> Em **[data/hora]**, identificamos **[descrição confirmada]**. Os dados potencialmente envolvidos são **[categorias]**, afetando **[escopo confirmado/em análise]**. Adotamos **[contenção]** e investigamos com prioridade. Recomendamos **[ação, se aplicável]**. Próxima atualização até **[prazo]**. Canal: **[DPO/suporte]**.

Não atribuir autoria, causa, quantidade ou impacto antes da confirmação.

---

# 10. Guia de reprodução

## 10.1 Pré-requisitos e instalação

- Git, Flutter 3.41 ou compatível, Chrome/Android e Supabase de teste;
- dois titulares fictícios e uma conta de suporte;
- nunca usar dados ou senhas reais.

```powershell
git clone URL_DO_REPOSITORIO
cd "FinControl - Gestao de Dados"
flutter pub get
```

Aplicar uma vez, em ordem:

1. `202611240001_stage1.sql`;
2. `202611240002_stage2.sql`;
3. `202611240003_stage3.sql`;
4. `202611240004_fix_pgcrypto_schema.sql`.

Criar usuários confirmados. Para suporte, aplicar `stage3_assign_support.sql` com e-mail fictício. Não registrar senhas.

Copiar `.env.example` para `.env`:

```env
SUPABASE_URL=https://ENDERECO-PUBLICO
SUPABASE_ANON_KEY=CHAVE-PUBLICA
```

`.env`/`.env.test` são ignorados. Nunca inserir `service_role`, senha Postgres ou segredo JWT no Flutter.

## 10.2 Executar e verificar

```powershell
$finConfig = Get-Content .env | ConvertFrom-StringData
flutter run -d chrome `
  "--dart-define=SUPABASE_URL=$($finConfig.SUPABASE_URL)" `
  "--dart-define=SUPABASE_ANON_KEY=$($finConfig.SUPABASE_ANON_KEY)"

dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub
```

## 10.3 Reprodução dos controles

1. A cria autorização e confirma persistência.
2. B confirma ausência dos registros de A.
3. Executar `test_rls_impersonation.ps1` com UUID fictício de A e sessão B.
4. Sincronizar ativa, revogar e conferir bloqueio/evento.
5. Preparar expiração com `stage2_expiration_setup.sql` somente no teste.
6. Criar pedido e acompanhar protocolo.
7. Confirmar que B recebe 403 na fila.
8. Suporte observa máscara e conclui exclusão.
9. Confirmar descarte e protocolo preservado.

## 10.4 Deploy EasyPanel

O repositório contém `Dockerfile`, `nginx.conf` e `.dockerignore`. Criar App com builder Dockerfile, fornecer `SUPABASE_URL`/`SUPABASE_ANON_KEY`, expor porta 80 e domínio HTTPS. Atualizar `SITE_URL`/`GOTRUE_SITE_URL` do Auth. `/health` deve responder `ok`.

---

# 11. Testes e evidências

Foram combinados testes automatizados, jornadas manuais, API autenticada e testes negativos. Dados são fictícios; senhas interativas não são gravadas. SQL Editor não prova RLS por usar privilégio administrativo.

| ID | Controle | Resultado | Estado |
|---|---|---|---|
| T01 | login/sessão | restaurada | Aprovado manualmente |
| T02 | persistência | autorização permaneceu | Aprovado manualmente |
| T03 | RLS leitura | B não recebeu A | Aprovado manualmente |
| T04 | RLS inserção | personificação bloqueada 401/403 | Aprovado |
| T05 | sincronização | fictícios + evento | Aprovado |
| T06 | revogação | estado/evento; acesso bloqueado | Aprovado |
| T07 | expiração | expirada; acesso bloqueado | Aprovado |
| T08 | pedido | protocolo + `submitted` | Aprovado API |
| T09 | RBAC | B false e fila 403 | Aprovado API |
| T10 | máscara | identificador terminou `***` | Aprovado API |
| T11 | exclusão | 4 autorizações removidas; protocolo mantido | Aprovado API |
| T12 | cifra | `encrypted_details` bloqueado 403 | Aprovado API |
| T13 | HTTPS | endpoint respondeu 200 | Aprovado |
| T14 | logs | nenhum segredo materializado | Aprovado |
| T15 | contingência | falha e retomada 200 | Aprovado |
| T16 | reprodução | clean, análise, 7 testes e build | Aprovado |
| T17 | histórico | DELETE 403; evento preservado | Aprovado API |

Em 24/11/2026, `flutter analyze` terminou sem problemas, sete testes passaram e o build Web foi gerado. Detalhes: `docs/test_matrix.md` e `docs/evidence_2026-11-24.md`.

## 11.1 Figuras a inserir no PDF

| Evidência | Conteúdo | Teste |
|---|---|---|
| E01 | login/biometria marcada como simulação | T01 |
| E02 | conexão fictícia Banco Alfa | T02 |
| E03 | revisão de consentimento | T02 |
| E04 | painel e histórico | T02/T05 |
| E05 | revogada e acesso bloqueado | T06 |
| E06 | expirada | T07 |
| E07 | protocolo | T08 |
| E08 | fila com máscara | T09/T10 |
| E09 | bloqueio RLS | T03/T04 |
| E10 | análise, testes e build | T16 |
| E11 | bloqueios da cifra e DELETE | T12/T17 |
| E12 | falha e retomada | T15 |

Cada figura deve ter data, responsável, commit, esperado/observado e ocultar segredos.

---

# 12. Prontidão e evolução

Classificação conservadora: TRL 4; defensável como TRL 5 após reprodução em ambiente controlado, sempre com fictícios. Produção exige Open Finance homologado, autenticação forte real, revisão LGPD, pentest, KMS/rotação, observabilidade, backup/RTO/RPO, retenção, gestão de fornecedor, acessibilidade e carga.

---

# 13. Autoria e decisões do grupo

## 13.1 Decisões e aprendizados verificáveis

- RLS foi adotada para não depender da interface.
- SQL Editor foi descartado como prova de RLS por seu privilégio.
- Erro de schema do `pgcrypto` foi corrigido na migração `202611240004` com `extensions.pgp_sym_encrypt/decrypt`.
- Atualização manual foi substituída por atualização silenciosa a cada três segundos.
- Manifesto antigo de assets/fontes no Flutter Web foi corrigido com reinício e novo build.
- Biometria/Open Finance foram rotulados como simulações para evitar alegação falsa.
- Interface foi refeita mobile first e responsiva.
- Deploy Docker/Nginx foi preparado sem versionar `.env`.

## 13.2 Contribuição individual

> Preencher com informações verdadeiras; não atribuir atividade não realizada.

| Integrante/matrícula | Atividades | Arquivos, commits ou testes |
|---|---|---|
| Hélio — [matrícula] | [preencher] | [preencher] |
| Kevilyn — [matrícula] | [preencher] | [preencher] |
| Rodrigo — [matrícula] | [preencher] | [preencher] |
| Thainá — [matrícula] | [preencher] | [preencher] |
| Murillo — [matrícula] | [preencher] | [preencher] |
| Marcelo — [matrícula] | [preencher] | [preencher] |

**Repositório:** `[INSERIR URL]`  
**Sistema:** `[INSERIR URL]`  
**Commit:** `[INSERIR HASH]`

---

# 14. Referências

- BRASIL. **Lei nº 13.709/2018 — Lei Geral de Proteção de Dados Pessoais**. Disponível em: https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm. Acesso em: 24 nov. 2026.
- BRASIL. Governo Digital. **PPSI 2.0: Guia para elaboração de RIPD**. Disponível em: https://www.gov.br/governodigital/pt-br/privacidade-e-seguranca/ppsi-2.0. Acesso em: 24 nov. 2026.
- BANCO CENTRAL DO BRASIL. **Open Finance**. Disponível em: https://www.bcb.gov.br/estabilidadefinanceira/openfinance. Acesso em: 24 nov. 2026.
- DAMA INTERNATIONAL. **DAMA-DMBOK**. 2. ed. Technics Publications, 2017.
- FLUTTER. **Build and release a web app**. Disponível em: https://docs.flutter.dev/deployment/web. Acesso em: 24 nov. 2026.
- NIST. **Computer Security Incident Handling Guide — SP 800-61 Rev. 2**. Disponível em: https://csrc.nist.gov/pubs/sp/800/61/r2/final. Acesso em: 24 nov. 2026.
- OWASP FOUNDATION. **Mobile Application Security Verification Standard**. Disponível em: https://mas.owasp.org/MASVS/. Acesso em: 24 nov. 2026.
- POSTGRESQL. **Row Security Policies**. Disponível em: https://www.postgresql.org/docs/current/ddl-rowsecurity.html. Acesso em: 24 nov. 2026.
- SUPABASE. **Auth, Row Level Security and Self-Hosting Documentation**. Disponível em: https://supabase.com/docs. Acesso em: 24 nov. 2026.
- NASA. **Technology Readiness Levels**. Disponível em: https://www.nasa.gov/directorates/somd/space-communications-navigation-program/technology-readiness-levels/. Acesso em: 24 nov. 2026.

---

# Apêndice A — Checklist do PDF

- [ ] nomes completos e matrículas;
- [ ] contribuição individual verdadeira;
- [ ] URLs e hash do commit;
- [ ] capa, sumário e páginas;
- [ ] diagramas convertidos em figuras;
- [ ] E01 a E12 com legenda/data/responsável;
- [ ] revisão ortográfica;
- [ ] nenhum print com segredo;
- [ ] documento e slides exportados em PDF;
- [ ] todos os integrantes enviarem no Blackboard.
