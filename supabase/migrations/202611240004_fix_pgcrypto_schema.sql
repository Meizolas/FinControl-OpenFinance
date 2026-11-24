-- Correção para projetos Supabase que instalam pgcrypto no schema extensions.
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
    extensions.pgp_sym_encrypt(
      trim(p_details), encryption_key, 'cipher-algo=aes256'
    )
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

revoke all on function public.submit_rights_request(text, text) from public;
revoke all on function public.get_support_queue() from public;
grant execute on function public.submit_rights_request(text, text) to authenticated;
grant execute on function public.get_support_queue() to authenticated;
