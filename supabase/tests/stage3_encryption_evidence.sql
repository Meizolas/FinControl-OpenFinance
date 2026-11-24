-- Evidência de proteção em repouso. Execute no SQL Editor após criar um pedido
-- com texto inteiramente fictício. O resultado não revela o conteúdo original.
select
  protocol,
  pg_typeof(encrypted_details)::text as storage_type,
  octet_length(encrypted_details) as ciphertext_bytes,
  left(encode(encrypted_details, 'hex'), 24) || '…' as ciphertext_sample,
  encrypted_details is not null as encrypted
from public.rights_requests
order by created_at desc
limit 1;

-- Esperado: storage_type=bytea, ciphertext_bytes > 0 e amostra hexadecimal.
-- A chave fica em private.field_keys, sem grants para anon/authenticated.
