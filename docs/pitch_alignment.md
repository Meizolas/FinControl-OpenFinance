# Ajustes obrigatórios do pitch

Use este arquivo ao revisar `FinControl Dados — Bloco 3 Pitch da Solução.pptx`.

| Slide | Substituir | Por |
|---|---|---|
| 1 | integrantes incompatíveis com autoria real | somente autores reais |
| 2 | “até set. 2025” | “até o início de ago. 2025” |
| 4 e 6 | biometria | e-mail e senha com restauração da sessão |
| 4 e 6 | conexão separada ao banco | seleção do Banco Alfa simulado na autorização |
| 5 | Android ou iOS | Web ou Android |
| 5 | gatilho bloqueia UPDATE/DELETE | RLS e privilégios impedem mutação pelo cliente |
| 5 | `auth.uid() = user_id` | `auth.uid() = owner_id` |
| 7 | `[ok / falha]` | resultados reais de `docs/test_matrix.md` |
| 8 | pronto para piloto real / TRL 6 | protótipo acadêmico com dados fictícios / TRL 4–5 |
| 12 | testes concluídos | separar aprovados e pendentes |

Custos são estimativas hipotéticas e devem trazer data/base. Não afirmar biometria, iOS, mTLS, logs inspecionados, pentest, KMS externo ou produção se não houver evidência.
