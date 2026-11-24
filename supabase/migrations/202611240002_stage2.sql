alter table public.authorizations
  drop constraint initial_status_active,
  add column revoked_at timestamptz,
  add column updated_at timestamptz not null default now(),
  add constraint revoked_at_matches_status check (
    (status = 'revoked' and revoked_at is not null)
    or (status <> 'revoked' and revoked_at is null)
  );

create table public.authorization_events (
  id bigint generated always as identity primary key,
  authorization_id uuid not null references public.authorizations(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('accepted', 'revoked', 'expired', 'data_accessed')),
  occurred_at timestamptz not null default now(),
  details jsonb not null default '{}'::jsonb,
  constraint details_is_object check (jsonb_typeof(details) = 'object')
);

create index authorization_events_authorization_idx
  on public.authorization_events(authorization_id, occurred_at desc);
create index authorization_events_owner_idx
  on public.authorization_events(owner_id);

alter table public.authorization_events enable row level security;
create policy "owners can view their authorization events"
on public.authorization_events for select to authenticated
using ((select auth.uid()) = owner_id);

revoke all on public.authorization_events from anon, authenticated;
grant select on public.authorization_events to authenticated;

insert into public.authorization_events
  (authorization_id, owner_id, event_type, occurred_at, details)
select id, owner_id, 'accepted', accepted_at,
  jsonb_build_object('terms_version', terms_version)
from public.authorizations;

create or replace function public.audit_authorization_acceptance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.authorization_events
    (authorization_id, owner_id, event_type, occurred_at, details)
  values
    (new.id, new.owner_id, 'accepted', new.accepted_at,
     jsonb_build_object('terms_version', new.terms_version));
  return new;
end;
$$;

create trigger authorization_acceptance_audit
after insert on public.authorizations
for each row execute function public.audit_authorization_acceptance();

create or replace function public.refresh_my_authorization_expirations()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_count integer;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  with expired as (
    update public.authorizations
       set status = 'expired', updated_at = now()
     where owner_id = auth.uid()
       and status = 'active'
       and valid_until <= now()
    returning id, owner_id, valid_until
  ), logged as (
    insert into public.authorization_events
      (authorization_id, owner_id, event_type, details)
    select id, owner_id, 'expired', jsonb_build_object('valid_until', valid_until)
    from expired
    returning 1
  )
  select count(*) into changed_count from logged;

  return changed_count;
end;
$$;

create or replace function public.revoke_authorization(p_authorization_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed public.authorizations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  update public.authorizations
     set status = 'revoked', revoked_at = now(), updated_at = now()
   where id = p_authorization_id
     and owner_id = auth.uid()
     and status = 'active'
     and valid_until > now()
  returning * into changed;

  if changed.id is null then
    raise exception 'authorization is unavailable for revocation' using errcode = 'P0001';
  end if;

  insert into public.authorization_events
    (authorization_id, owner_id, event_type, details)
  values (changed.id, changed.owner_id, 'revoked', '{}'::jsonb);
end;
$$;

create or replace function public.get_simulated_financial_data(p_authorization_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed public.authorizations;
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;

  select * into allowed
  from public.authorizations
  where id = p_authorization_id
    and owner_id = auth.uid()
    and status = 'active'
    and valid_until > now();

  if allowed.id is null then
    raise exception 'active authorization not found' using errcode = 'P0001';
  end if;

  result := jsonb_build_object(
    'account_alias', 'Conta fictícia • 0001',
    'balance', 2450.75,
    'currency', 'BRL',
    'reference_at', now(),
    'categories', to_jsonb(allowed.data_categories)
  );

  insert into public.authorization_events
    (authorization_id, owner_id, event_type, details)
  values (allowed.id, allowed.owner_id, 'data_accessed',
          jsonb_build_object('source', 'simulated'));

  return result;
end;
$$;

revoke all on function public.refresh_my_authorization_expirations() from public;
revoke all on function public.revoke_authorization(uuid) from public;
revoke all on function public.get_simulated_financial_data(uuid) from public;
grant execute on function public.refresh_my_authorization_expirations() to authenticated;
grant execute on function public.revoke_authorization(uuid) to authenticated;
grant execute on function public.get_simulated_financial_data(uuid) to authenticated;
