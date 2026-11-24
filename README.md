# FinControl — Etapas 1, 2 e 3

MVP acadêmico Flutter para o titular autenticar-se, registrar e acompanhar uma autorização fictícia. A Etapa 2 acrescenta detalhes, revogação, expiração, histórico e sincronização financeira simulada.

## Pré-requisitos e segurança

- Flutter 3.41 ou compatível e Chrome ou Android configurado;
- projeto Supabase de teste;
- Supabase CLI apenas se quiser aplicar a migração pela linha de comando.

Nunca use `service_role` no aplicativo. Ele recebe apenas a URL e a chave pública `anon`/publishable. `.env.example` é uma referência sem segredos; o app não lê esse arquivo e usa valores compilados por `--dart-define`.

## Preparar o Supabase

1. Crie um projeto de teste.
2. No SQL Editor, execute integralmente `supabase/migrations/202611240001_stage1.sql`. Com a CLI, a alternativa é `supabase link --project-ref SEU_REF` e `supabase db push`.
   Se a Etapa 1 já estiver aplicada, execute em seguida `supabase/migrations/202611240002_stage2.sql`. As migrações devem ser aplicadas uma única vez e na ordem do nome do arquivo.
   Para a Etapa 3, execute depois `supabase/migrations/202611240003_stage3.sql`.
3. Em **Authentication > Users**, crie dois titulares fictícios. No ambiente usado nesta etapa foram criados `titular.a@gmail.com` e `titular.b@gmail.com`, com senhas distintas e e-mails confirmados. Não registre as senhas no repositório.
4. Em **Project Settings > API**, copie a URL e a chave pública, nunca uma chave secreta.

A migração cria Banco Alfa e valida finalidade, categorias, prazo, estado inicial e versão do aceite. RLS permite ler apenas registros com `owner_id = auth.uid()` e inserir apenas em nome da própria conta. Não há política de alteração ou exclusão nesta etapa.

A segunda migração remove a restrição de estado inicial que impediria mudanças legítimas e cria:

- histórico `authorization_events`, legível somente pelo titular;
- revogação atômica, que altera o estado e registra o evento na mesma transação;
- atualização de expirações pertencentes ao usuário autenticado;
- sincronização simulada que valida titular, estado ativo e prazo no backend antes de retornar saldo fictício;
- privilégios limitados às funções destinadas ao papel `authenticated`.

O painel atualiza silenciosamente a cada três segundos enquanto o aplicativo está ativo e também imediatamente ao voltar da criação ou dos detalhes. O temporizador é suspenso quando o aplicativo vai para segundo plano. A atualização manual por gesto ou pelo ícone permanece disponível como contingência.

## Executar

```powershell
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
```

Sem os valores, o app mostra uma orientação de configuração. O SDK do Supabase persiste a sessão, e o `AuthGate` reage à restauração e ao logout.

## Reproduzir o fluxo

1. Entre como A, crie uma autorização para Banco Alfa e confirme a revisão de instituição, finalidade, categorias, prazo e texto versão 1.0.
2. Confirme o registro no painel; saia, entre novamente como A e confira a persistência.
3. Entre como B e confirme que o painel não retorna o registro de A.
4. Para testar personificação, use um cliente autenticado como B (não SQL Editor/service role) e envie um `insert` em `authorizations` com o UUID de A. O esperado é `new row violates row-level security policy`.

O script abaixo automatiza esse teste sem imprimir ou armazenar a senha. Copie o UUID de A em **Authentication > Users** e execute:

```powershell
.\scripts\test_rls_impersonation.ps1 -UserAId 'UUID-DE-A'
```

Informe a senha fictícia de B quando solicitada. O resultado esperado é `APROVADO` com HTTP 401 ou 403. O script não cria nenhum registro quando a política está correta.

O SQL Editor normalmente ignora RLS por usar privilégios administrativos; não serve como evidência do bloqueio. Use o app, um cliente com JWT de usuário ou testes locais do Supabase.

## Verificações locais

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Resultados observados em 24/11/2026:

- `flutter analyze --no-pub`: concluído, nenhum problema encontrado;
- `flutter test --no-pub`: 2 testes executados, todos aprovados;
- `flutter build web --no-pub` com configuração pública fictícia: compilação concluída em `build/web`;
- conexão com o Supabase: `/auth/v1/settings` retornou HTTP 200 com a chave pública configurada;
- validação manual informada pelo responsável pelo projeto: A autenticou e criou uma autorização para Banco Alfa; após sair e entrar novamente, a autorização permaneceu no painel; ao autenticar como B, a autorização de A não foi exibida;
- validação manual informada pelo responsável pelo projeto: `scripts/test_rls_impersonation.ps1`, autenticado como B e tentando gravar com o UUID de A, retornou `APROVADO`; a política RLS bloqueou a criação em nome de outro titular;
- a tentativa inicial conjunta de análise/teste foi interrompida após ficar sem progresso; as verificações foram então repetidas separadamente com os resultados acima.

Os três cenários integrados previstos para a Etapa 1 foram validados. A migração foi aplicada externamente ao ambiente local e seu funcionamento foi observado pelo fluxo do aplicativo; a Supabase CLI local continua indisponível. A pasta também ainda não é um repositório Git, portanto nenhum commit foi criado.

## Estrutura

- `lib/screens`: login, painel e criação/revisão;
- `lib/services`: autenticação e persistência;
- `lib/models` e `lib/config`: dados e configuração pública;
- `supabase/migrations`: esquema, seed, validações e RLS.
- `docs/technical_documentation.md`: arquitetura, ciclo de vida, CID, PbD, RIPD, contingência, PRI e War Room;
- `docs/test_matrix.md`: rastreabilidade dos testes aprovados e pendentes;
- `docs/pitch_alignment.md`: correções necessárias no pitch.
- `docs/evidence_2026-11-24.md`: resultados realmente executados, sem segredos;
- `docs/FinControl_Bloco3_Pitch_corrigido.pptx`: cópia do pitch alinhada ao MVP comprovado.

## Etapa 3 — configuração e validação

A Etapa 3 implementa política de privacidade, pedidos de acesso/correção/exclusão, protocolo e situação, fila de suporte com RBAC e identificador mascarado. O texto livre do pedido é armazenado cifrado por AES-256 com `pgcrypto`. A chave é gerada no banco durante a migração, fica no schema `private` sem privilégios para `anon` ou `authenticated` e nunca é enviada ao Flutter.

Depois de aplicar a terceira migração:

1. Em **Authentication > Users**, crie a conta fictícia `suporte.fincontrol@gmail.com`, com e-mail confirmado e senha de teste não registrada no repositório.
2. Execute uma vez `supabase/tests/stage3_assign_support.sql` no SQL Editor para atribuir o papel.
3. Como titular A, abra **Meus pedidos**, crie um pedido de exclusão com texto fictício e anote o protocolo.
4. Entre como suporte, abra **Fila de suporte**, confirme que o titular aparece mascarado, passe o pedido para **Em análise** e depois conclua.
5. Entre novamente como A: o pedido deve estar **Concluído** e as autorizações devem ter sido removidas. O protocolo permanece como evidência do atendimento.
6. Como titular B, confirme que **Fila de suporte** não aparece. Uma chamada direta a `get_support_queue` também deve ser bloqueada pelo backend.

Validações locais em 24/11/2026:

- `flutter analyze --no-pub`: nenhum problema encontrado;
- `flutter test --no-pub`: 7 testes aprovados;
- `flutter build web --no-pub`: compilação concluída em `build/web`;
- endpoint configurado do Supabase: esquema HTTPS e resposta HTTP 200 em `/auth/v1/settings` confirmados;
- migração `202611240003_stage3.sql`: aplicada; as quatro RPCs foram confirmadas no schema exposto pela API;
- criptografia em repouso e exclusão até a conclusão: validadas pela API em 24/11/2026 após aplicar `202611240004_fix_pgcrypto_schema.sql`; o titular recebeu HTTP 403 ao solicitar `encrypted_details`, o suporte viu apenas identificador mascarado, e concluir o pedido removeu as 4 autorizações fictícias de A mantendo o protocolo concluído.
- RBAC do usuário comum: validado pela API em 24/11/2026; B recebeu `is_support=false` e HTTP 403 ao chamar a fila. A conta de suporte recebeu `is_support=true`.

## Próxima etapa (não implementada)

A Etapa 4 foi executada em 24/11/2026: reconstrução após `flutter clean`, restauração de dependências, análise sem problemas, 7 testes aprovados, build Web concluído, integridade do histórico bloqueada com HTTP 403, varredura sem segredo materializado e indisponibilidade seguida de retomada HTTP 200. A matriz detalhada está em `docs/test_matrix.md`.

A Etapa 5 possui documentação técnica e alinhamento do pitch em `docs/`. A cópia final do pitch deve usar somente os resultados aprovados na matriz.

## Etapa 2 — estado da validação

Implementação local em 24/11/2026:

- `flutter analyze --no-pub`: nenhum problema encontrado;
- `flutter test --no-pub`: 5 testes aprovados;
- migração `202611240002_stage2.sql`: aplicada externamente; as RPCs e a coluna `revoked_at` foram confirmadas no schema exposto pela API;
- revogação: validação manual informada pelo responsável pelo projeto; uma autorização ativa foi revogada e o novo estado foi observado no aplicativo;
- sincronização simulada: validação manual informada pelo responsável pelo projeto; dados fictícios foram retornados para uma autorização ativa, o acesso apareceu no histórico e a autorização revogada não permitiu nova sincronização;
- expiração: validação manual informada pelo responsável pelo projeto e comprovada visualmente; após vencer uma autorização ativa no ambiente de teste, o painel a atualizou automaticamente para **Expirada**.

Com esses resultados, os cenários integrados previstos para a Etapa 2 foram concluídos: acesso simulado permitido somente para autorização ativa, bloqueio após revogação, transição para expirada, histórico e atualização automática do painel.

Roteiro integrado após aplicar a migração:

1. Abra uma autorização ativa, sincronize e confira os dados marcados como simulados e o evento no histórico.
2. Revogue-a e confirme no painel o estado **Revogada** e, nos detalhes, que a sincronização não fica disponível.
3. Crie uma autorização de teste, ajuste `valid_until` para o passado em ambiente controlado, reabra o painel e confirme **Expirada** e o bloqueio da sincronização.
4. Entre como o outro titular e confirme que ele não vê a autorização nem seus eventos.

Para preparar o item 3 com dados de teste, execute uma única vez no SQL Editor o arquivo `supabase/tests/stage2_expiration_setup.sql`. Ele altera somente a autorização ativa mais recente de `titular.a@gmail.com`. Não use esse script em produção.
