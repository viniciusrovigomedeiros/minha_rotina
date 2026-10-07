-- These helpers are used by RLS on the same tables they query. Running them
-- with the caller's RLS creates a profiles -> members -> profiles recursion.
create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = ''
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
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.social_group_members m
    where m.group_id = target_group_id
      and m.profile_id = public.current_profile_id()
      and m.status = 'active'
  );
$$;

create or replace function public.is_challenge_member(target_challenge_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.challenge_members m
    where m.challenge_id = target_challenge_id
      and m.profile_id = public.current_profile_id()
      and m.status = 'active'
  );
$$;

revoke execute on function public.current_profile_id() from public, anon;
revoke execute on function public.is_group_member(uuid) from public, anon;
revoke execute on function public.is_challenge_member(uuid) from public, anon;
grant execute on function public.current_profile_id() to authenticated;
grant execute on function public.is_group_member(uuid) to authenticated;
grant execute on function public.is_challenge_member(uuid) to authenticated;

create or replace function public.create_social_challenge(
  p_title text,
  p_challenge_type public.challenge_type,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile_id uuid;
  v_challenge_id uuid;
  v_scoring_type public.scoring_type;
  v_duration_days integer;
  v_start_at timestamptz := now();
  v_end_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  v_profile_id := public.current_profile_id();
  if v_profile_id is null then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;
  if p_title is null or btrim(p_title) = '' then
    raise exception 'Challenge title is required' using errcode = '22023';
  end if;
  if p_challenge_type is null then
    raise exception 'Challenge type is required' using errcode = '22023';
  end if;

  case p_challenge_type
    when 'cycle_duel' then
      v_scoring_type := 'percentage_progress';
      v_duration_days := 90;
    when 'weekly_short' then
      v_scoring_type := 'completion_count';
      v_duration_days := 7;
    when 'shared_mission' then
      v_scoring_type := 'completion_count';
      v_duration_days := 30;
    when 'shared_objective' then
      v_scoring_type := 'shared_okr_progress';
      v_duration_days := 90;
    when 'consistency_league' then
      v_scoring_type := 'consistency_score';
      v_duration_days := 30;
  end case;
  v_end_at := v_start_at + v_duration_days * interval '1 day';

  insert into public.challenges (
    created_by_profile_id, challenge_type, title, description,
    scoring_type, start_at, end_at, status
  ) values (
    v_profile_id, p_challenge_type, btrim(p_title),
    nullif(btrim(p_description), ''), v_scoring_type,
    v_start_at, v_end_at, 'active'
  ) returning id into v_challenge_id;

  insert into public.challenge_members (challenge_id, profile_id, role)
  values (v_challenge_id, v_profile_id, 'owner');

  if p_challenge_type = 'shared_objective' then
    insert into public.shared_objectives (
      challenge_id, title, description, objective_mode, start_at, end_at
    ) values (
      v_challenge_id, btrim(p_title), nullif(btrim(p_description), ''),
      'shared_goal_split_krs', v_start_at, v_end_at
    );
  end if;

  return v_challenge_id;
end;
$$;

revoke execute on function public.create_social_challenge(text, public.challenge_type, text) from public, anon;
grant execute on function public.create_social_challenge(text, public.challenge_type, text) to authenticated;
