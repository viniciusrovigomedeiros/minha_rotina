create table if not exists public.user_data_snapshots (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  payload jsonb not null,
  revision bigint not null default 1,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.user_data_snapshots enable row level security;

drop policy if exists "Users manage own data snapshots" on public.user_data_snapshots;
create policy "Users manage own data snapshots"
on public.user_data_snapshots
for all
to authenticated
using (
  profile_id in (
    select id from public.profiles where auth_user_id = auth.uid()
  )
)
with check (
  profile_id in (
    select id from public.profiles where auth_user_id = auth.uid()
  )
);

create or replace function public.touch_user_data_snapshot()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = timezone('utc', now());
  new.revision = old.revision + 1;
  return new;
end;
$$;

drop trigger if exists touch_user_data_snapshot on public.user_data_snapshots;
create trigger touch_user_data_snapshot
before update on public.user_data_snapshots
for each row execute function public.touch_user_data_snapshot();
