create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'challenge_type') then
    create type public.challenge_type as enum (
      'cycle_duel',
      'weekly_short',
      'shared_mission',
      'shared_objective',
      'consistency_league'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'scoring_type') then
    create type public.scoring_type as enum (
      'percentage_progress',
      'completion_count',
      'consistency_score',
      'shared_okr_progress'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'objective_mode') then
    create type public.objective_mode as enum (
      'parallel_individual',
      'shared_goal_split_krs'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'ownership_mode') then
    create type public.ownership_mode as enum (
      'individual',
      'shared_visible_single_owner'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'check_in_type') then
    create type public.check_in_type as enum (
      'weekly_reflection',
      'kr_update',
      'activity_completion',
      'manual_progress'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'source_type') then
    create type public.source_type as enum (
      'manual',
      'local_sync',
      'system_generated'
    );
  end if;
end
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  username text unique,
  push_opt_in boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  fcm_token text not null unique,
  last_seen_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.social_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  group_type text not null default 'accountability',
  owner_profile_id uuid not null references public.profiles(id) on delete restrict,
  visibility text not null default 'invite_only',
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.social_group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.social_groups(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default timezone('utc', now()),
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (group_id, profile_id)
);

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.social_groups(id) on delete set null,
  created_by_profile_id uuid not null references public.profiles(id) on delete restrict,
  challenge_type public.challenge_type not null,
  title text not null,
  description text,
  scoring_type public.scoring_type not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  status text not null default 'draft',
  consequence_type text,
  consequence_text text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.challenge_members (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default timezone('utc', now()),
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (challenge_id, profile_id)
);

create table if not exists public.shared_objectives (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  title text not null,
  description text,
  objective_mode public.objective_mode not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.shared_key_results (
  id uuid primary key default gen_random_uuid(),
  shared_objective_id uuid not null references public.shared_objectives(id) on delete cascade,
  title text not null,
  measurement_type text not null,
  initial_value numeric not null default 0,
  target_value numeric not null default 0,
  unit text,
  weight numeric,
  ownership_mode public.ownership_mode not null default 'individual',
  owner_profile_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.member_goal_links (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  shared_objective_id uuid references public.shared_objectives(id) on delete cascade,
  shared_key_result_id uuid references public.shared_key_results(id) on delete cascade,
  local_objective_id text,
  local_key_result_id text,
  sync_mode text not null default 'manual',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.social_check_ins (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  shared_objective_id uuid references public.shared_objectives(id) on delete set null,
  shared_key_result_id uuid references public.shared_key_results(id) on delete set null,
  check_in_type public.check_in_type not null,
  value_numeric numeric,
  status_label text,
  advance_note text,
  blocker_note text,
  next_focus_note text,
  source_type public.source_type not null default 'manual',
  source_local_event_id text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.execution_proofs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  social_check_in_id uuid references public.social_check_ins(id) on delete cascade,
  proof_type text not null,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint,
  caption text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.challenge_scores (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  score_total numeric not null default 0,
  consistency_score numeric not null default 0,
  completion_score numeric not null default 0,
  check_in_score numeric not null default 0,
  current_streak integer not null default 0,
  rank_position integer,
  last_calculated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (challenge_id, profile_id)
);

create table if not exists public.buddy_rules (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  buddy_profile_id uuid not null references public.profiles(id) on delete cascade,
  group_id uuid references public.social_groups(id) on delete set null,
  challenge_id uuid references public.challenges(id) on delete set null,
  days_without_check_in_threshold integer not null default 3,
  weekly_risk_enabled boolean not null default true,
  streak_break_enabled boolean not null default true,
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  target_type text,
  target_id uuid,
  aggregation_key text,
  sent_at timestamptz,
  read_at timestamptz,
  status text not null default 'queued',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.social_invites (
  id uuid primary key default gen_random_uuid(),
  created_by_profile_id uuid not null references public.profiles(id) on delete cascade,
  invite_type text not null,
  target_type text not null,
  target_id uuid,
  token text not null unique,
  status text not null default 'pending',
  expires_at timestamptz not null,
  accepted_by_profile_id uuid references public.profiles(id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.current_profile_id()
returns uuid
language sql
stable
as $$
  select p.id
  from public.profiles p
  where p.auth_user_id = auth.uid()
  limit 1;
$$;

create or replace function public.is_group_member(target_group_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.social_group_members m
    where m.group_id = target_group_id
      and m.profile_id = public.current_profile_id()
      and m.status = 'active'
  );
$$;

create or replace function public.is_challenge_member(target_challenge_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.challenge_members m
    where m.challenge_id = target_challenge_id
      and m.profile_id = public.current_profile_id()
      and m.status = 'active'
  );
$$;

create index if not exists idx_device_tokens_profile_id on public.device_tokens(profile_id);
create index if not exists idx_social_group_members_group_id on public.social_group_members(group_id);
create index if not exists idx_social_group_members_profile_id on public.social_group_members(profile_id);
create index if not exists idx_challenge_members_challenge_id on public.challenge_members(challenge_id);
create index if not exists idx_challenge_members_profile_id on public.challenge_members(profile_id);
create index if not exists idx_challenges_group_id on public.challenges(group_id);
create index if not exists idx_social_check_ins_challenge_id on public.social_check_ins(challenge_id);
create index if not exists idx_social_check_ins_profile_id on public.social_check_ins(profile_id);
create index if not exists idx_execution_proofs_check_in_id on public.execution_proofs(social_check_in_id);
create index if not exists idx_notifications_profile_id on public.notifications(profile_id);
create index if not exists idx_social_invites_token on public.social_invites(token);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_device_tokens_updated_at on public.device_tokens;
create trigger set_device_tokens_updated_at before update on public.device_tokens
for each row execute function public.set_updated_at();

drop trigger if exists set_social_groups_updated_at on public.social_groups;
create trigger set_social_groups_updated_at before update on public.social_groups
for each row execute function public.set_updated_at();

drop trigger if exists set_social_group_members_updated_at on public.social_group_members;
create trigger set_social_group_members_updated_at before update on public.social_group_members
for each row execute function public.set_updated_at();

drop trigger if exists set_challenges_updated_at on public.challenges;
create trigger set_challenges_updated_at before update on public.challenges
for each row execute function public.set_updated_at();

drop trigger if exists set_challenge_members_updated_at on public.challenge_members;
create trigger set_challenge_members_updated_at before update on public.challenge_members
for each row execute function public.set_updated_at();

drop trigger if exists set_shared_objectives_updated_at on public.shared_objectives;
create trigger set_shared_objectives_updated_at before update on public.shared_objectives
for each row execute function public.set_updated_at();

drop trigger if exists set_shared_key_results_updated_at on public.shared_key_results;
create trigger set_shared_key_results_updated_at before update on public.shared_key_results
for each row execute function public.set_updated_at();

drop trigger if exists set_member_goal_links_updated_at on public.member_goal_links;
create trigger set_member_goal_links_updated_at before update on public.member_goal_links
for each row execute function public.set_updated_at();

drop trigger if exists set_social_check_ins_updated_at on public.social_check_ins;
create trigger set_social_check_ins_updated_at before update on public.social_check_ins
for each row execute function public.set_updated_at();

drop trigger if exists set_execution_proofs_updated_at on public.execution_proofs;
create trigger set_execution_proofs_updated_at before update on public.execution_proofs
for each row execute function public.set_updated_at();

drop trigger if exists set_challenge_scores_updated_at on public.challenge_scores;
create trigger set_challenge_scores_updated_at before update on public.challenge_scores
for each row execute function public.set_updated_at();

drop trigger if exists set_buddy_rules_updated_at on public.buddy_rules;
create trigger set_buddy_rules_updated_at before update on public.buddy_rules
for each row execute function public.set_updated_at();

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at before update on public.notifications
for each row execute function public.set_updated_at();

drop trigger if exists set_social_invites_updated_at on public.social_invites;
create trigger set_social_invites_updated_at before update on public.social_invites
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.device_tokens enable row level security;
alter table public.social_groups enable row level security;
alter table public.social_group_members enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_members enable row level security;
alter table public.shared_objectives enable row level security;
alter table public.shared_key_results enable row level security;
alter table public.member_goal_links enable row level security;
alter table public.social_check_ins enable row level security;
alter table public.execution_proofs enable row level security;
alter table public.challenge_scores enable row level security;
alter table public.buddy_rules enable row level security;
alter table public.notifications enable row level security;
alter table public.social_invites enable row level security;

drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self" on public.profiles
for select using (auth.uid() = auth_user_id);

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
for insert with check (auth.uid() = auth_user_id);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
for update using (auth.uid() = auth_user_id);

drop policy if exists "device_tokens_owner" on public.device_tokens;
create policy "device_tokens_owner" on public.device_tokens
for all using (profile_id = public.current_profile_id())
with check (profile_id = public.current_profile_id());

drop policy if exists "social_groups_members_read" on public.social_groups;
create policy "social_groups_members_read" on public.social_groups
for select using (
  owner_profile_id = public.current_profile_id()
  or public.is_group_member(id)
);

drop policy if exists "social_groups_owner_write" on public.social_groups;
create policy "social_groups_owner_write" on public.social_groups
for all using (owner_profile_id = public.current_profile_id())
with check (owner_profile_id = public.current_profile_id());

drop policy if exists "social_group_members_read" on public.social_group_members;
create policy "social_group_members_read" on public.social_group_members
for select using (
  profile_id = public.current_profile_id()
  or public.is_group_member(group_id)
);

drop policy if exists "social_group_members_owner_manage" on public.social_group_members;
create policy "social_group_members_owner_manage" on public.social_group_members
for all using (
  profile_id = public.current_profile_id()
  or exists (
    select 1
    from public.social_groups g
    where g.id = group_id
      and g.owner_profile_id = public.current_profile_id()
  )
)
with check (
  profile_id = public.current_profile_id()
  or exists (
    select 1
    from public.social_groups g
    where g.id = group_id
      and g.owner_profile_id = public.current_profile_id()
  )
);

drop policy if exists "challenges_members_read" on public.challenges;
create policy "challenges_members_read" on public.challenges
for select using (
  created_by_profile_id = public.current_profile_id()
  or public.is_challenge_member(id)
  or (group_id is not null and public.is_group_member(group_id))
);

drop policy if exists "challenges_owner_write" on public.challenges;
create policy "challenges_owner_write" on public.challenges
for all using (created_by_profile_id = public.current_profile_id())
with check (created_by_profile_id = public.current_profile_id());

drop policy if exists "challenge_members_read" on public.challenge_members;
create policy "challenge_members_read" on public.challenge_members
for select using (
  profile_id = public.current_profile_id()
  or public.is_challenge_member(challenge_id)
);

drop policy if exists "challenge_members_manage" on public.challenge_members;
create policy "challenge_members_manage" on public.challenge_members
for all using (
  profile_id = public.current_profile_id()
  or exists (
    select 1
    from public.challenges c
    where c.id = challenge_id
      and c.created_by_profile_id = public.current_profile_id()
  )
)
with check (
  profile_id = public.current_profile_id()
  or exists (
    select 1
    from public.challenges c
    where c.id = challenge_id
      and c.created_by_profile_id = public.current_profile_id()
  )
);

drop policy if exists "shared_objectives_members_read" on public.shared_objectives;
create policy "shared_objectives_members_read" on public.shared_objectives
for select using (public.is_challenge_member(challenge_id));

drop policy if exists "shared_objectives_owner_write" on public.shared_objectives;
create policy "shared_objectives_owner_write" on public.shared_objectives
for all using (
  exists (
    select 1
    from public.challenges c
    where c.id = challenge_id
      and c.created_by_profile_id = public.current_profile_id()
  )
)
with check (
  exists (
    select 1
    from public.challenges c
    where c.id = challenge_id
      and c.created_by_profile_id = public.current_profile_id()
  )
);

drop policy if exists "shared_key_results_members_read" on public.shared_key_results;
create policy "shared_key_results_members_read" on public.shared_key_results
for select using (
  exists (
    select 1
    from public.shared_objectives o
    where o.id = shared_objective_id
      and public.is_challenge_member(o.challenge_id)
  )
);

drop policy if exists "shared_key_results_owner_write" on public.shared_key_results;
create policy "shared_key_results_owner_write" on public.shared_key_results
for all using (
  exists (
    select 1
    from public.shared_objectives o
    join public.challenges c on c.id = o.challenge_id
    where o.id = shared_objective_id
      and c.created_by_profile_id = public.current_profile_id()
  )
)
with check (
  exists (
    select 1
    from public.shared_objectives o
    join public.challenges c on c.id = o.challenge_id
    where o.id = shared_objective_id
      and c.created_by_profile_id = public.current_profile_id()
  )
);

drop policy if exists "member_goal_links_owner" on public.member_goal_links;
create policy "member_goal_links_owner" on public.member_goal_links
for all using (profile_id = public.current_profile_id())
with check (profile_id = public.current_profile_id());

drop policy if exists "social_check_ins_members_read" on public.social_check_ins;
create policy "social_check_ins_members_read" on public.social_check_ins
for select using (public.is_challenge_member(challenge_id));

drop policy if exists "social_check_ins_owner_write" on public.social_check_ins;
create policy "social_check_ins_owner_write" on public.social_check_ins
for all using (profile_id = public.current_profile_id())
with check (
  profile_id = public.current_profile_id()
  and public.is_challenge_member(challenge_id)
);

drop policy if exists "execution_proofs_members_read" on public.execution_proofs;
create policy "execution_proofs_members_read" on public.execution_proofs
for select using (public.is_challenge_member(challenge_id));

drop policy if exists "execution_proofs_owner_write" on public.execution_proofs;
create policy "execution_proofs_owner_write" on public.execution_proofs
for all using (profile_id = public.current_profile_id())
with check (
  profile_id = public.current_profile_id()
  and public.is_challenge_member(challenge_id)
);

drop policy if exists "challenge_scores_members_read" on public.challenge_scores;
create policy "challenge_scores_members_read" on public.challenge_scores
for select using (public.is_challenge_member(challenge_id));

drop policy if exists "buddy_rules_owner" on public.buddy_rules;
create policy "buddy_rules_owner" on public.buddy_rules
for all using (owner_profile_id = public.current_profile_id())
with check (owner_profile_id = public.current_profile_id());

drop policy if exists "notifications_owner" on public.notifications;
create policy "notifications_owner" on public.notifications
for select using (profile_id = public.current_profile_id());

drop policy if exists "notifications_owner_update" on public.notifications;
create policy "notifications_owner_update" on public.notifications
for update using (profile_id = public.current_profile_id());

drop policy if exists "social_invites_related_read" on public.social_invites;
create policy "social_invites_related_read" on public.social_invites
for select using (
  created_by_profile_id = public.current_profile_id()
  or accepted_by_profile_id = public.current_profile_id()
);

drop policy if exists "social_invites_creator_write" on public.social_invites;
create policy "social_invites_creator_write" on public.social_invites
for all using (created_by_profile_id = public.current_profile_id())
with check (created_by_profile_id = public.current_profile_id());

insert into storage.buckets (id, name, public)
values ('social-proofs', 'social-proofs', false)
on conflict (id) do nothing;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (auth_user_id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (auth_user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.create_profile_for_new_user();
