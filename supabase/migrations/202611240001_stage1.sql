create extension if not exists pgcrypto;

create table public.institutions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(trim(name)) between 2 and 120),
  created_at timestamptz not null default now()
);

create table public.authorizations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  institution_id uuid not null references public.institutions(id),
  purpose text not null check (char_length(trim(purpose)) between 5 and 240),
  data_categories text[] not null check (
    cardinality(data_categories) between 1 and 10
    and data_categories <@ array['Saldo', 'Transações', 'Dados da conta']::text[]
  ),
  accepted_at timestamptz not null default now(),
  valid_until timestamptz not null,
  status text not null default 'active' check (status in ('active', 'revoked', 'expired')),
  terms_version text not null check (char_length(trim(terms_version)) between 1 and 30),
  created_at timestamptz not null default now(),
  constraint validity_after_acceptance check (valid_until > accepted_at),
  constraint initial_status_active check (status = 'active')
);

create index authorizations_owner_id_idx on public.authorizations(owner_id);
create index authorizations_institution_id_idx on public.authorizations(institution_id);
alter table public.institutions enable row level security;
alter table public.authorizations enable row level security;

create policy "authenticated users can view institutions"
on public.institutions for select to authenticated using (true);
create policy "owners can view their authorizations"
on public.authorizations for select to authenticated using ((select auth.uid()) = owner_id);
create policy "owners can create their authorizations"
on public.authorizations for insert to authenticated with check ((select auth.uid()) = owner_id);

revoke all on public.institutions from anon;
revoke all on public.authorizations from anon;
grant select on public.institutions to authenticated;
grant select, insert on public.authorizations to authenticated;

insert into public.institutions (name) values ('Banco Alfa') on conflict (name) do nothing;
