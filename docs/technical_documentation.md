# FinControl — documentação técnica do Bloco 3

Estado: MVP acadêmico com dados e instituições fictícias. Não integra o Open Finance real.

## 1. Objetivo e escopo

A FinControl permite ao titular visualizar autorizações de compartilhamento, finalidade, categorias, prazo e histórico; sincronizar dados fictícios enquanto a autorização estiver válida; revogar o consentimento; e solicitar acesso, correção ou exclusão. O backend aplica as decisões de acesso independentemente da interface.

Fora do escopo do MVP: biometria, mTLS/Open Finance, publicação em lojas, dados bancários reais, atendimento de produção, KMS externo, pentest e SLA.

## 2. Arquitetura

- Flutter/Dart: interface Web e Android.
- Supabase Auth: e-mail/senha, JWT e restauração de sessão.
- PostgREST/RPC: comunicação HTTPS com o backend.
- PostgreSQL: persistência, constraints, funções transacionais e auditoria.
- RLS/RBAC: isolamento por `auth.uid()` e papel `support` validado no servidor.
- `pgcrypto`: AES-256 para o texto livre de pedidos; chave gerada no banco e isolada no schema `private`.

O Flutter recebe somente URL e chave pública por `--dart-define`. Chaves administrativas e a chave de criptografia não são distribuídas ao cliente.

## 3. Ciclo de vida dos dados

1. Coleta: e-mail pelo Supabase Auth; finalidade, categorias, prazo e aceite pelo app; texto fictício em pedidos do titular.
2. Armazenamento: PostgreSQL, com vínculos ao usuário autenticado, constraints e texto de pedido cifrado.
3. Uso: apresentação no painel e validação backend antes de retornar dados financeiros simulados.
4. Compartilhamento: somente simulado com Banco Alfa; não há transmissão bancária real.
5. Retenção e descarte: autorizações e eventos permanecem para a demonstração; concluir pedido de exclusão remove autorizações e eventos em cascata, preservando protocolo/status como evidência do atendimento.

## 4. Papéis e responsabilidades

- Titular: concede, consulta e revoga autorizações; exerce direitos de acesso, correção e exclusão.
- Gestor de Dados: define qualidade, classificação, retenção e acesso aos dados do produto; mantém o catálogo e a matriz de controles.
- DPO/Encarregado: orienta conformidade, recebe comunicações, acompanha direitos dos titulares e incidentes.
- Suporte: atende pedidos pela fila, com identificador mascarado e papel concedido no backend.
- Desenvolvimento/Operação: implementa controles, monitora disponibilidade e preserva evidências técnicas sem segredos.

## 5. Consentimento e direitos

Antes do aceite são mostrados instituição, finalidade, categorias, prazo e versão do texto. O banco registra titular, instante, validade e versão. A revogação altera status e registra evento na mesma transação. Pedidos do titular recebem protocolo e situação `submitted`, `in_review`, `completed` ou `rejected`.

## 6. Tríade CID

- Confidencialidade: Auth, HTTPS, RLS, RBAC, ausência de chaves administrativas no cliente, mascaramento e cifra do texto livre.
- Integridade: PK/FK, constraints, funções transacionais, categorias permitidas, prazo posterior ao aceite e histórico de eventos.
- Disponibilidade: estado de carregamento/erro, tentativa novamente, atualização automática e procedimento de retomada. O MVP não possui SLA, redundância própria ou monitoramento de produção.

## 7. Privacy by Design

- Concepção: dados reais e integração bancária excluídos; categorias limitadas; separação de papéis; finalidade e prazo obrigatórios.
- Trânsito: endpoint HTTPS verificado; JWT enviado pelo SDK; nenhuma `service_role` no app.
- Repouso: controles do PostgreSQL, RLS e cifra AES-256 de `encrypted_details`; chave em schema privado. Limitação: o MVP não usa KMS/HSM externo.
- Padrão: usuário vê apenas seus registros; fila de suporte fica invisível e inacessível sem papel.
- Transparência: política dentro do app, revisão antes do aceite, histórico, protocolo e situação.

## 8. RIPD resumido

| Elemento | Avaliação |
|---|---|
| Operações | autenticação, consentimento, consulta simulada, revogação e direitos |
| Necessidade | demonstrar controle do titular e rastreabilidade acadêmica |
| Dados | identificador Auth, autorizações, eventos e pedido fictício |
| Titulares | contas fictícias A e B |
| Riscos principais | acesso entre contas, personificação, consentimento vencido, abuso do suporte, exposição do texto livre |
| Controles | RLS, `auth.uid()`, RBAC, constraints, RPCs, mascaramento, cifra e HTTPS |
| Risco residual | configuração incorreta do projeto, conta de suporte comprometida, ausência de KMS/pentest/monitoramento |
| Tratamento futuro | MFA/biometria, KMS, revisão LGPD, pentest, logs centralizados e alertas |

## 9. Contingência

1. Detectar indisponibilidade por erro do app ou monitoramento futuro.
2. Preservar sessão local sem registrar token em logs.
3. Informar falha compreensível e impedir ações parcialmente confirmadas.
4. Restaurar conectividade/serviço e usar atualização automática ou **Tentar novamente**.
5. Conferir no backend se a transação foi concluída antes de repetir.
6. Registrar horário, impacto, ação e resultado com dados fictícios.

Backups, RTO e RPO dependem do plano/ambiente Supabase e devem ser definidos antes de produção.

## 10. Plano de Resposta a Incidentes — seis fases

1. Preparação: responsáveis, contatos, acessos mínimos, backups e exercícios.
2. Identificação: validar alerta, escopo, dados e titulares afetados.
3. Contenção: bloquear credenciais/rotas e limitar propagação preservando evidências.
4. Erradicação: corrigir causa, remover acesso indevido e revisar configurações.
5. Recuperação: restaurar serviço, validar integridade e monitorar recorrência.
6. Lições aprendidas: relatório, ações corretivas, comunicação e atualização do RIPD.

## 11. War Room

- Líder do incidente: coordena prioridade, decisões e linha do tempo.
- Responsável técnico: investiga, contém, corrige e valida recuperação.
- DPO/Encarregado: avalia impacto aos titulares e obrigações regulatórias.
- Comunicação: mantém mensagens internas/externas consistentes e aprovadas.

Os quatro papéis podem ser acumulados no trabalho acadêmico, mas as responsabilidades devem permanecer explícitas.

## 12. Modelo de comunicado de crise

> Assunto: atualização sobre incidente de segurança na FinControl  
> Em [data/hora], identificamos [descrição objetiva]. Os dados potencialmente envolvidos são [categorias], afetando [escopo]. Contivemos [medida] e estamos investigando com prioridade. Recomendamos [ação do titular, se aplicável]. Novas informações serão publicadas até [prazo]. Canal: [contato do DPO/suporte].

Não especular causa, autoria ou quantidade antes da confirmação. Preservar evidências e alinhar comunicação ao DPO.

## 13. Testes e rastreabilidade

A matriz vigente está em `docs/test_matrix.md`. Migrações implementam controles no backend; telas e repositórios Flutter implementam o fluxo. Somente resultados marcados como aprovados podem ser usados no pitch.

## 14. Limitações e prontidão

O artefato é um protótipo acadêmico funcional com dados fictícios, compatível com TRL 4 e possivelmente TRL 5 após reprodução e contingência documentadas. Não está pronto para piloto com usuários/dados reais.

## 15. Referências essenciais

- BRASIL. Lei 13.709/2018 — LGPD.
- Banco Central do Brasil. Open Finance e autorizações de compartilhamento, 2025.
- DAMA International. DAMA-DMBOK2, 2017.
- OWASP. MASVS, 2024.
- Supabase. Documentação de Auth, RLS e Pricing.
- NASA. Technology Readiness Levels.
