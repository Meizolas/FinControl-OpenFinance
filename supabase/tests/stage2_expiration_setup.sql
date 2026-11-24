-- Preparação controlada do teste de expiração da Etapa 2.
-- Execute somente no projeto de teste, pelo SQL Editor do Supabase.
-- O script vence a autorização ativa mais recente do titular indicado.

with target as (
  select a.id
  from public.authorizations as a
  join auth.users as u on u.id = a.owner_id
  where u.email = 'titular.a@gmail.com'
    and a.status = 'active'
  order by a.accepted_at desc
  limit 1
)
update public.authorizations as a
set valid_until = a.accepted_at + interval '1 second',
    updated_at = now()
where a.id in (select id from target)
returning a.id, a.status, a.valid_until;

-- Resultado esperado neste momento: uma linha ainda com status "active" e
-- valid_until no passado. Ao abrir/atualizar o painel, o RPC do aplicativo
-- altera o status para "expired" e registra o evento de auditoria.
