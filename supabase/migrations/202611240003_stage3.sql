create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table private.field_keys (
  key_name text primary key,
  key_value bytea not null,
  created_at timestamptz not null default now()
);
revoke all on private.field_keys from public, anon, authenticated;
insert into private.field_keys (key_name, key_value)
values ('rights_request_details', gen_random_bytes(32))
on conflict (key_name) do nothing;

create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('support')),
  created_at timestamptz not null default now()
);
alter table public.user_roles enable row level security;
revoke all on public.user_roles from public, anon, authenticated;

create table public.rights_requests (
  id uuid primary key default gen_random_uuid(),
  protocol text not null unique,
  owner_id uuid not null references auth.users(id) on delete cascade,
  request_type text not null check (request_type in ('access', 'correction', 'deletion')),
  encrypted_details bytea not null,
  status text not null default 'submitted'
    check (status in ('submitted', 'in_review', 'completed', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint completion_matches_status check (
    (status = 'completed' and completed_at is not null)
    or (status <> 'completed' and completed_at is null)
  )
);
create index rights_requests_owner_idx
  on public.rights_requests(owner_id, created_at desc);
alter table public.rights_requests enable row level security;
create policy "owners can view their rights requests"
on public.rights_requests for select to authenticated
using ((select auth.uid()) = owner_id);
revoke all on public.rights_requests from public, anon, authenticated;
grant select (id, protocol, owner_id, request_type, status, created_at, updated_at, completed_at)
on public.rights_requests to authenticated;

create or replace function public.is_support()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role = 'support'
  );
$$;

create or replace function public.submit_rights_request(
  p_request_type text,
  p_details text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  encryption_key text;
  new_protocol text;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_request_type not in ('access', 'correction', 'deletion') then
    raise exception 'invalid request type' using errcode = '22023';
  end if;
  if char_length(trim(p_details)) not between 10 and 1000 then
    raise exception 'details must contain between 10 and 1000 characters'
      using errcode = '22023';
  end if;

  select encode(key_value, 'hex') into encryption_key
  from private.field_keys where key_name = 'rights_request_details';
  if encryption_key is null then
    raise exception 'encryption key unavailable';
  end if;

  new_protocol := 'FC-' || to_char(clock_timestamp(), 'YYYYMMDD') || '-'
    || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  insert into public.rights_requests
    (protocol, owner_id, request_type, encrypted_details)
  values (
    new_protocol,
    auth.uid(),
    p_request_type,
    extensions.pgp_sym_encrypt(trim(p_details), encryption_key, 'cipher-algo=aes256')
  );
  return new_protocol;
end;
$$;

create or replace function public.get_support_queue()
returns table (
  request_id uuid,
  protocol text,
  masked_owner text,
  request_type text,
  details text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  encryption_key text;
begin
  if not public.is_support() then
    raise exception 'support role required' using errcode = '42501';
  end if;
  select encode(key_value, 'hex') into encryption_key
  from private.field_keys where key_name = 'rights_request_details';

  return query
  select
    r.id,
    r.protocol,
    left(md5(r.owner_id::text), 6) || '***',
    r.request_type,
    extensions.pgp_sym_decrypt(r.encrypted_details, encryption_key),
    r.status,
    r.created_at
  from public.rights_requests r
  order by r.created_at;
end;
$$;

create or replace function public.update_rights_request_status(
  p_request_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed public.rights_requests%rowtype;
begin
  if not public.is_support() then
    raise exception 'support role required' using errcode = '42501';
  end if;
  if p_status not in ('in_review', 'completed', 'rejected') then
    raise exception 'invalid status transition' using errcode = '22023';
  end if;

  update public.rights_requests
  set status = p_status,
      updated_at = now(),
      completed_at = case when p_status = 'completed' then now() else null end
  where id = p_request_id and status in ('submitted', 'in_review')
  returning * into changed;

  if changed.id is null then
    raise exception 'request unavailable for transition' using errcode = 'P0001';
  end if;

  if changed.request_type = 'deletion' and p_status = 'completed' then
    delete from public.authorizations where owner_id = changed.owner_id;
  end if;
end;
$$;

revoke all on function public.is_support() from public;
revoke all on function public.submit_rights_request(text, text) from public;
revoke all on function public.get_support_queue() from public;
revoke all on function public.update_rights_request_status(uuid, text) from public;
grant execute on function public.is_support() to authenticated;
grant execute on function public.submit_rights_request(text, text) to authenticated;
grant execute on function public.get_support_queue() to authenticated;
grant execute on function public.update_rights_request_status(uuid, text) to authenticated;
