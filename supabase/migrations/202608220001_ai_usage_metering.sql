create table if not exists public.ai_usage_monthly (
  user_id uuid not null references auth.users(id) on delete cascade,
  period_start date not null,
  analyses_used integer not null default 0 check (analyses_used >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, period_start)
);

alter table public.ai_usage_monthly enable row level security;

create policy "ai_usage_select_own"
on public.ai_usage_monthly
for select
using (auth.uid() = user_id);

create or replace function public.current_ai_usage()
returns table(period_start date, analyses_used integer)
language sql
security invoker
stable
set search_path = public
as $$
  select u.period_start, u.analyses_used
  from public.ai_usage_monthly u
  where u.user_id = auth.uid()
    and u.period_start = date_trunc('month', now())::date;
$$;

create or replace function public.consume_ai_analysis(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period date := date_trunc('month', now())::date;
  v_is_pro boolean := false;
  v_used integer := 0;
begin
  select true into v_is_pro
  from public.entitlements e
  where e.user_id = p_user_id
    and e.tier = 'pro'
    and e.status = 'active'
    and (e.expires_at is null or e.expires_at > now())
  limit 1;

  if coalesce(v_is_pro, false) then
    select analyses_used into v_used
    from public.ai_usage_monthly
    where user_id = p_user_id and period_start = v_period;
    return jsonb_build_object('allowed', true, 'tier', 'pro', 'used', coalesce(v_used, 0), 'limit', null);
  end if;

  insert into public.ai_usage_monthly(user_id, period_start, analyses_used, updated_at)
  values (p_user_id, v_period, 1, now())
  on conflict (user_id, period_start)
  do update set analyses_used = public.ai_usage_monthly.analyses_used + 1, updated_at = now()
  where public.ai_usage_monthly.analyses_used < 3
  returning analyses_used into v_used;

  if v_used is null then
    select analyses_used into v_used
    from public.ai_usage_monthly
    where user_id = p_user_id and period_start = v_period;
    return jsonb_build_object('allowed', false, 'tier', 'free', 'used', coalesce(v_used, 3), 'limit', 3);
  end if;

  return jsonb_build_object('allowed', true, 'tier', 'free', 'used', v_used, 'limit', 3);
end;
$$;

create or replace function public.refund_ai_analysis(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_period date := date_trunc('month', now())::date;
begin
  update public.ai_usage_monthly
  set analyses_used = greatest(0, analyses_used - 1), updated_at = now()
  where user_id = p_user_id and period_start = v_period;
end;
$$;

revoke all on function public.consume_ai_analysis(uuid) from public, anon, authenticated;
grant execute on function public.consume_ai_analysis(uuid) to service_role;
revoke all on function public.refund_ai_analysis(uuid) from public, anon, authenticated;
grant execute on function public.refund_ai_analysis(uuid) to service_role;
