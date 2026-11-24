# Matriz de testes — FinControl

Use somente dados fictícios. Para cada execução, salve captura sem senha, token ou chave.

| ID | Controle | Pré-condição | Ação | Resultado esperado | Estado em 24/11/2026 |
|---|---|---|---|---|---|
| T01 | Login e sessão | Conta A confirmada | Entrar, fechar/reabrir | Sessão restaurada | Aprovado manualmente |
| T02 | Persistência | A autenticado | Criar autorização e entrar novamente | Registro permanece | Aprovado manualmente |
| T03 | RLS leitura | Autorização de A | Entrar como B | Nenhuma linha de A | Aprovado manualmente |
| T04 | RLS inserção | UUID de A e sessão de B | Executar `test_rls_impersonation.ps1` | HTTP 401/403 | Aprovado manualmente |
| T05 | Sincronização ativa | Autorização ativa | Sincronizar | Dados fictícios e evento | Aprovado manualmente |
| T06 | Revogação | Autorização ativa | Confirmar revogação | Estado e evento revogado | Aprovado manualmente |
| T07 | Expiração | Autorização ativa vencida | Reabrir painel | Estado expirado e acesso bloqueado | Aprovado manualmente |
| T08 | Pedido do titular | Migração 3 aplicada | Criar pedido | Protocolo e estado enviado | Aprovado via API em 24/11/2026 |
| T09 | RBAC suporte | Conta B comum | Autenticar e chamar `is_support`/`get_support_queue` | `false` e HTTP 403 | Aprovado automaticamente em 24/11/2026 |
| T10 | Mascaramento | Conta support e pedido | Abrir fila | Identificador termina em `***` | Aprovado via API em 24/11/2026 |
| T11 | Exclusão | Pedido de exclusão em análise | Concluir como support | Autorizações/eventos removidos; protocolo concluído | Aprovado via API em 24/11/2026; 4 autorizações removidas |
| T12 | Criptografia | Pedido fictício existente | Ler metadados e tentar selecionar `encrypted_details` como titular | Metadados disponíveis e campo cifrado bloqueado | Aprovado via API em 24/11/2026; HTTP 403 no campo |
| T13 | HTTPS | `.env` configurado | Consultar `/auth/v1/settings` | HTTPS e HTTP 200 | Aprovado localmente |
| T14 | Logs | Login/revogação via API e código | Inspecionar saída e varrer padrões | Sem senha, JWT ou chave materializada | Aprovado em 24/11/2026; ocorrências eram apenas nomes de variáveis/documentação |
| T15 | Contingência | Endpoint indisponível simulado | Falhar conexão e repetir no serviço válido | Falha detectada e retomada HTTP 200 | Aprovado em 24/11/2026 |
| T16 | Reprodução | Artefatos Flutter removidos | `clean`, `pub get`, análise, testes e build | Build e testes aprovados | Aprovado em 24/11/2026 |
| T17 | Integridade do histórico | Evento de aceite de B | Tentar `DELETE` autenticado | HTTP 403 e evento preservado | Aprovado via API em 24/11/2026 |

As capturas e saídas devem registrar data, versão do código e responsável pela execução. “Pendente” não deve ser apresentado como aprovado no pitch.
