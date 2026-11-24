-- Execute somente no projeto acadêmico de teste depois de criar a conta de suporte.
-- Troque o e-mail abaixo caso tenha escolhido outro endereço fictício.
insert into public.user_roles (user_id, role)
select id, 'support'
from auth.users
where email = 'suporte.fincontrol@gmail.com'
on conflict (user_id) do update set role = excluded.role;

select u.email, r.role
from public.user_roles r
join auth.users u on u.id = r.user_id
where u.email = 'suporte.fincontrol@gmail.com';
