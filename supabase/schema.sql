-- Route Performance Tracker cloud schema
-- Run in a dedicated Supabase project.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  display_name text
);

create table if not exists public.routes (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  route_date timestamptz not null,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create index if not exists routes_user_date_idx on public.routes(user_id, route_date desc);

create table if not exists public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tier text not null default 'free' check (tier in ('free','pro')),
  provider text,
  product_id text,
  status text not null default 'inactive',
  started_at timestamptz,
  expires_at timestamptz,
  last_verified_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.routes enable row level security;
alter table public.entitlements enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
create policy "routes_select_own" on public.routes for select using (auth.uid() = user_id);
create policy "routes_insert_own" on public.routes for insert with check (auth.uid() = user_id);
create policy "routes_update_own" on public.routes for update using (auth.uid() = user_id);
create policy "routes_delete_own" on public.routes for delete using (auth.uid() = user_id);
create policy "entitlements_select_own" on public.entitlements for select using (auth.uid() = user_id);

-- Entitlement writes intentionally have no client RLS policy.
-- Only trusted backend/service-role code may grant or modify Pro access.
