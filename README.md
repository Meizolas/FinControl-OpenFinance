# FinControl Dados

MVP acadêmico de governança, consentimento e proteção de dados financeiros, desenvolvido em Flutter com backend Supabase e PostgreSQL.

A solução permite que o titular simule a conexão de uma instituição financeira, autorize categorias de dados para uma finalidade e prazo determinados, acompanhe a vigência, consulte o histórico e revogue o consentimento. O projeto também demonstra direitos do titular, controle de acesso por função, mascaramento, criptografia em repouso e descarte controlado.

> Todo o ambiente utiliza contas, instituições, saldos e transações fictícias. A biometria e a jornada Open Finance são simulações acadêmicas. Nenhuma instituição financeira real é acessada.

## Sumário

1. [Principais recursos](#principais-recursos)
2. [Tecnologias](#tecnologias)
3. [Arquitetura](#arquitetura)
4. [Estrutura do projeto](#estrutura-do-projeto)
5. [Pré-requisitos](#pré-requisitos)
6. [Configuração do Supabase](#configuração-do-supabase)
7. [Configuração local](#configuração-local)
8. [Execução](#execução)
9. [Contas de teste](#contas-de-teste)
10. [Testes e qualidade](#testes-e-qualidade)
11. [Cenários de validação](#cenários-de-validação)
12. [Segurança e privacidade](#segurança-e-privacidade)
13. [Deploy Web com Docker e EasyPanel](#deploy-web-com-docker-e-easypanel)
14. [Documentação acadêmica](#documentação-acadêmica)
15. [Limitações](#limitações)

## Principais recursos

### Autenticação e experiência

- Login real com e-mail e senha pelo Supabase Auth.
- Restauração automática da sessão.
- Biometria visual simulada antes da autenticação.
- Interface mobile first e responsiva para desktop.
- Feedback visual de carregamento, sucesso, erro e confirmação.
- Ícones Lucide e identidade visual baseada na marca FinControl.

### Jornada Open Finance simulada

- Seleção do Banco Alfa fictício.
- Simulação de redirecionamento, autorização, conexão segura e importação.
- Avisos visíveis de que nenhuma instituição real é acessada.
- Dados financeiros fictícios disponíveis somente após autorização válida.

### Consentimento e controle do titular

- Seleção de saldo, transações e dados da conta.
- Finalidade obrigatória.
- Prazo de validade configurável.
- Revisão das escolhas antes do aceite.
- Registro da versão do texto de consentimento.
- Painel com autorizações ativas, revogadas e expiradas.
- Atualização silenciosa do painel a cada três segundos.
- Atualização manual por gesto ou botão.
- Histórico de aceite, acesso, expiração e revogação.
- Revogação com confirmação e bloqueio de novos acessos.

### Direitos do titular

- Pedidos de acesso, correção e exclusão.
- Protocolo único para acompanhamento.
- Estados enviado, em análise, concluído e recusado.
- Política de privacidade disponível dentro do aplicativo.
- Exclusão das autorizações e eventos quando o pedido de exclusão é concluído.
- Preservação do protocolo como evidência mínima do atendimento.

### Suporte e governança

- Fila exclusiva para contas com papel `support`.
- Verificação do papel no backend.
- Identificador do titular mascarado.
- Texto livre dos pedidos cifrado com AES-256.
- Histórico protegido contra alteração e exclusão pelo cliente.

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Interface | Flutter e Dart |
| Design | Material 3 e Lucide Icons |
| Autenticação | Supabase Auth |
| API | PostgREST e funções RPC |
| Banco de dados | PostgreSQL |
| Autorização | Row Level Security e RBAC |
| Criptografia | `pgcrypto` com AES-256 |
| Hospedagem Web | Nginx em container Docker |
| Deploy previsto | EasyPanel em VPS |

## Arquitetura

```text
Navegador ou Android
        |
        v
Flutter e Dart
        |
        | HTTPS com JWT
        v
Supabase Auth e PostgREST
        |
        v
RLS, RBAC e funções RPC
        |
        v
PostgreSQL e schema privado
```

O Flutter recebe somente a URL pública do Supabase e a chave pública `anon` ou publishable. A segurança não depende de esconder essa chave, pois aplicações Web sempre expõem os valores compilados ao cliente. A proteção é aplicada por RLS, privilégios mínimos e validações nas funções do banco.

Nunca inclua no aplicativo:

- `service_role`;
- senha do PostgreSQL;
- URL direta do banco;
- segredo JWT;
- chave de criptografia;
- credenciais administrativas.

## Estrutura do projeto

```text
lib/
  config/       configuração pública e validações
  models/       modelos de domínio
  screens/      telas e fluxos da aplicação
  services/     autenticação, consultas e RPCs
  theme/        cores, tipografia e componentes
  widgets/      componentes reutilizáveis

supabase/
  migrations/   schema, RLS, RBAC, histórico e criptografia
  tests/        preparação controlada de cenários

scripts/        testes de segurança pela API
test/           testes automatizados Flutter
docs/           documentação, evidências e pitch
images/         identidade visual
```

Arquivos de deploy:

- `Dockerfile` compila o Flutter e publica com Nginx.
- `nginx.conf` configura SPA, cache, compactação e endpoint de saúde.
- `.dockerignore` reduz o contexto enviado ao Docker.
- `.gitignore` impede o versionamento de variáveis e arquivos sensíveis.

## Pré-requisitos

- Flutter 3.41 ou versão compatível.
- Dart incluído no Flutter.
- Chrome, Edge ou dispositivo Android.
- Projeto Supabase de teste, hospedado ou self-hosted.
- Git para controle de versão.
- Docker apenas para validar ou publicar o container.

Verifique o ambiente:

```powershell
flutter doctor
flutter devices
```

## Configuração do Supabase

### 1. Aplicar as migrações

Execute os arquivos no SQL Editor uma única vez e na ordem indicada:

1. `supabase/migrations/202611240001_stage1.sql`
2. `supabase/migrations/202611240002_stage2.sql`
3. `supabase/migrations/202611240003_stage3.sql`
4. `supabase/migrations/202611240004_fix_pgcrypto_schema.sql`

A primeira migração cria instituições, autorizações, validações e RLS. A segunda adiciona histórico, revogação, expiração e sincronização fictícia. A terceira adiciona pedidos do titular, RBAC, mascaramento e criptografia. A quarta garante compatibilidade com instalações em que `pgcrypto` fica no schema `extensions`.

O SQL Editor normalmente executa com privilégio administrativo e pode ignorar RLS. Ele deve ser usado para aplicar migrações, mas não como evidência de isolamento entre titulares.

### 2. Criar usuários fictícios

Em **Authentication > Users**, crie e confirme:

- uma conta para o titular A;
- uma conta para o titular B;
- uma conta de suporte.

Use senhas distintas e fictícias. Não registre senhas no código, documentação, repositório ou capturas.

### 3. Atribuir o papel de suporte

Revise o e-mail de teste no arquivo abaixo e execute-o uma única vez:

```text
supabase/tests/stage3_assign_support.sql
```

A conta comum deve receber `is_support=false`. A conta autorizada deve receber `is_support=true`.

## Configuração local

Instale as dependências:

```powershell
flutter pub get
```

Crie o arquivo `.env` a partir de `.env.example`:

```env
SUPABASE_URL=https://SEU-ENDERECO-PUBLICO
SUPABASE_ANON_KEY=SUA-CHAVE-PUBLICA
```

O aplicativo não carrega `.env` em tempo de execução. Os valores são enviados ao compilador por `--dart-define`.

Os arquivos `.env`, `.env.test` e demais variações locais estão ignorados pelo Git. Apenas `.env.example`, sem valores reais, deve ser versionado.

## Execução

### PowerShell com `.env`

```powershell
$finConfig = Get-Content .env | ConvertFrom-StringData

flutter run -d chrome `
  "--dart-define=SUPABASE_URL=$($finConfig.SUPABASE_URL)" `
  "--dart-define=SUPABASE_ANON_KEY=$($finConfig.SUPABASE_ANON_KEY)"
```

### Execução direta

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://SEU-ENDERECO-PUBLICO `
  --dart-define=SUPABASE_ANON_KEY=SUA-CHAVE-PUBLICA
```

Se a configuração estiver ausente ou inválida, o aplicativo apresenta uma orientação em vez de iniciar o cliente Supabase.

## Contas de teste

As contas abaixo foram criadas exclusivamente para avaliação acadêmica, com e-mails confirmados e dados fictícios:

| Perfil | E-mail | Senha | Finalidade |
|---|---|---|---|
| Titular A | `titular.a@gmail.com` | `senha123` | criar autorizações, sincronizar, revogar e abrir pedidos |
| Titular B | `titular.b@gmail.com` | `senha123` | validar o isolamento entre contas por RLS |
| Suporte | `suporte.fincontrol@gmail.com` | `senha123` | validar RBAC, fila, mascaramento e atendimento |

### Acesso do professor

As três contas utilizam a senha acadêmica comum `senha123`. Essas credenciais pertencem exclusivamente ao ambiente de demonstração e não podem ser reutilizadas em contas pessoais ou ambientes com dados reais.

Formato sugerido para o envio no Blackboard:

```text
FinControl Dados
URL: https://SEU-DOMINIO

Titular A
E-mail: titular.a@gmail.com
Senha: senha123

Titular B
E-mail: titular.b@gmail.com
Senha: senha123

Suporte
E-mail: suporte.fincontrol@gmail.com
Senha: senha123
```

Recomendações para a avaliação:

- utilizar Titular A no fluxo principal;
- utilizar Titular B para demonstrar que uma conta não visualiza os dados da outra;
- utilizar Suporte apenas para abrir a fila e alterar pedidos de teste;
- evitar concluir pedido de exclusão antes de finalizar a demonstração principal;
- trocar ou desativar as senhas após o encerramento da avaliação.

## Testes e qualidade

Execute:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

Gere o build Web:

```powershell
$finConfig = Get-Content .env | ConvertFrom-StringData

flutter build web --release --no-pub `
  "--dart-define=SUPABASE_URL=$($finConfig.SUPABASE_URL)" `
  "--dart-define=SUPABASE_ANON_KEY=$($finConfig.SUPABASE_ANON_KEY)"
```

Resultados consolidados em 24/11/2026:

- análise estática sem problemas;
- sete testes automatizados aprovados;
- build Web gerado com sucesso;
- conexão HTTPS com o Auth confirmada;
- 17 cenários funcionais e de segurança documentados.

Consulte os resultados detalhados em:

- `docs/test_matrix.md`
- `docs/evidence_2026-11-24.md`

## Cenários de validação

### Fluxo principal

1. Entre como titular A.
2. Execute a biometria simulada.
3. Conecte o Banco Alfa no fluxo Open Finance simulado.
4. Escolha categorias, finalidade e validade.
5. Revise e confirme.
6. Sincronize os dados fictícios.
7. Consulte o evento de acesso.
8. Revogue a autorização.
9. Confirme o estado revogado e o bloqueio da sincronização.

### Isolamento entre titulares

1. Crie uma autorização como titular A.
2. Saia e entre como titular B.
3. Confirme que B não recebe autorização ou evento de A.

Para testar tentativa de personificação pela API:

```powershell
.\scripts\test_rls_impersonation.ps1 -UserAId 'UUID-FICTICIO-DE-A'
```

O script solicita a senha fictícia de B de forma interativa. O resultado esperado é `APROVADO` com HTTP 401 ou 403. Nenhum registro deve ser criado.

### Expiração

O arquivo `supabase/tests/stage2_expiration_setup.sql` altera somente a autorização ativa mais recente do titular de teste configurado. Use apenas em ambiente acadêmico.

Depois da preparação:

1. Reabra ou atualize o painel.
2. Confirme o estado **Expirada**.
3. Confirme que a sincronização está bloqueada.
4. Consulte o evento de expiração.

### Direitos e suporte

1. Como titular, crie um pedido de acesso, correção ou exclusão.
2. Anote o protocolo.
3. Como usuário comum, confirme que a fila não aparece e a API retorna 403.
4. Como suporte, abra a fila e confirme o identificador mascarado.
5. Passe o pedido para análise.
6. Conclua somente quando desejar executar o efeito correspondente.

Um pedido de exclusão concluído remove autorizações e eventos do titular. Use esse cenário apenas quando a remoção fizer parte do teste.

## Segurança e privacidade

Controles implementados:

- autenticação e sessão por JWT;
- HTTPS entre cliente e backend;
- RLS por `owner_id`;
- RBAC para suporte;
- constraints de finalidade, categoria, prazo e estado;
- revogação e auditoria na mesma transação;
- histórico sem permissão de alteração pelo cliente;
- AES-256 no texto dos pedidos;
- chave em schema privado;
- mascaramento do identificador na fila;
- bloqueio do acesso após revogação ou expiração;
- arquivos sensíveis excluídos do Git e do contexto Docker.

O identificador mascarado é uma representação pseudonimizada. Ele reduz exposição, mas não deve ser tratado como anonimização irreversível, pois o backend mantém vínculo com o titular.

## Deploy Web com Docker e EasyPanel

### Build local do container

```powershell
$finConfig = Get-Content .env | ConvertFrom-StringData

docker build `
  --build-arg "SUPABASE_URL=$($finConfig.SUPABASE_URL)" `
  --build-arg "SUPABASE_ANON_KEY=$($finConfig.SUPABASE_ANON_KEY)" `
  -t fincontrol-web .

docker run --rm -p 8080:80 fincontrol-web
```

Acesse `http://localhost:8080`. O endpoint `http://localhost:8080/health` deve responder `ok`.

### EasyPanel

1. Crie um serviço do tipo App.
2. Conecte o repositório Git.
3. Selecione o builder Dockerfile.
4. Use `/` como caminho de build e `Dockerfile` como arquivo.
5. Configure `SUPABASE_URL` e `SUPABASE_ANON_KEY`.
6. Exponha a porta interna 80.
7. Associe o domínio e habilite HTTPS.
8. Atualize `SITE_URL`, `GOTRUE_SITE_URL` e URLs permitidas do Auth self-hosted.
9. Faça o deploy e valide `/health`.

O domínio deve possuir registro DNS do tipo A apontando para o IP público da VPS.

## Documentação acadêmica

| Documento | Conteúdo |
|---|---|
| `docs/technical_documentation.md` | arquitetura, ciclo de vida, privacidade, RIPD, contingência, PRI, reprodução e testes |
| `docs/test_matrix.md` | rastreabilidade dos 17 cenários |
| `docs/evidence_2026-11-24.md` | resultados executados sem segredos |
| `docs/pitch_alignment.md` | correções de compatibilidade entre MVP e pitch |
| `docs/FinControl_Bloco3_Pitch_corrigido.pptx` | versão corrigida da apresentação |

Antes da entrega, a documentação técnica deve receber nomes completos, matrículas, contribuições individuais, links, commit final e capturas indicadas na seção de evidências. O documento e os slides devem ser exportados em PDF conforme as instruções da atividade.

## Limitações

Este projeto não possui:

- biometria real;
- integração Open Finance real;
- dados bancários reais;
- publicação em lojas;
- KMS ou HSM externo;
- pentest independente;
- monitoramento e resposta 24 horas;
- SLA, RTO e RPO aprovados;
- homologação jurídica ou regulatória.

O MVP deve ser apresentado como protótipo acadêmico funcional com dados fictícios, classificado de forma conservadora como TRL 4 e potencialmente TRL 5 após reprodução em ambiente controlado.

## Equipe

Hélio, Kevilyn, Rodrigo, Thainá, Murillo e Marcelo.

Antes da publicação final, substitua os primeiros nomes por nomes completos e inclua as matrículas e contribuições verdadeiras na documentação técnica.
