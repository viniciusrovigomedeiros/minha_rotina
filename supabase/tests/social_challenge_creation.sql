-- Run with psql -v ON_ERROR_STOP=1 after applying the social migrations.
-- All fixtures, triggers and writes are rolled back.
begin;

create temporary table social_creation_test_state (
  owner_auth_id uuid default gen_random_uuid(),
  peer_auth_id uuid default gen_random_uuid(),
  outsider_auth_id uuid default gen_random_uuid(),
  challenge_id uuid,
  invite_token text
);
insert into social_creation_test_state default values;
grant select, update on social_creation_test_state to authenticated;

insert into auth.users (id, raw_user_meta_data)
select owner_auth_id, '{"full_name":"Regression owner"}'::jsonb from social_creation_test_state
union all
select peer_auth_id, '{"full_name":"Regression peer"}'::jsonb from social_creation_test_state
union all
select outsider_auth_id, '{"full_name":"Regression outsider"}'::jsonb from social_creation_test_state;

create function public.fail_social_objective_regression()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.title = '__social_atomic_failure__' then
    raise exception 'Forced objective failure';
  end if;
  return new;
end;
$$;
create trigger fail_social_objective_regression
before insert on public.shared_objectives
for each row execute function public.fail_social_objective_regression();

set local role authenticated;
select set_config('request.jwt.claim.sub', owner_auth_id::text, true)
from social_creation_test_state;

do $$
declare
  v_type public.challenge_type;
  v_id uuid;
  v_profile_id uuid := public.current_profile_id();
  v_count integer;
  v_days integer;
  v_score public.scoring_type;
begin
  if v_profile_id is null then
    raise exception 'Owner profile could not be read';
  end if;
  if (select count(*) from public.profiles where auth_user_id = auth.uid()) <> 1 then
    raise exception 'Profile SELECT failed';
  end if;

  foreach v_type in array enum_range(null::public.challenge_type) loop
    v_id := public.create_social_challenge('  Regression ' || v_type::text || '  ', v_type, '  Description  ');
    select case v_type when 'weekly_short' then 7
                      when 'cycle_duel' then 90
                      when 'shared_objective' then 90
                      else 30 end into v_days;
    select case v_type when 'cycle_duel' then 'percentage_progress'
                      when 'shared_objective' then 'shared_okr_progress'
                      when 'consistency_league' then 'consistency_score'
                      else 'completion_count' end::public.scoring_type into v_score;
    if not exists (
      select 1 from public.challenges c
      where c.id = v_id and c.created_by_profile_id = v_profile_id
        and c.title = 'Regression ' || v_type::text
        and c.description = 'Description' and c.status = 'active'
        and c.scoring_type = v_score
        and c.end_at - c.start_at = v_days * interval '1 day'
    ) then
      raise exception 'Invalid challenge for %', v_type;
    end if;
    if (select count(*) from public.challenge_members
        where challenge_id = v_id and profile_id = v_profile_id
          and role = 'owner' and status = 'active') <> 1 then
      raise exception 'Missing owner membership for %', v_type;
    end if;
    if not public.is_challenge_member(v_id) then
      raise exception 'Owner membership lookup failed';
    end if;
    select count(*) into v_count from public.shared_objectives where challenge_id = v_id;
    if v_count <> (case when v_type = 'shared_objective' then 1 else 0 end) then
      raise exception 'Wrong objective count for %', v_type;
    end if;
    update social_creation_test_state
      set challenge_id = v_id, invite_token = public.create_challenge_invite(v_id);
  end loop;

  select count(*) into v_count from public.challenges;
  begin
    perform public.create_social_challenge('   ', 'weekly_short');
    raise exception 'Empty title was accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.create_social_challenge('Invalid type', null);
    raise exception 'Missing type was accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.create_social_challenge('__social_atomic_failure__', 'shared_objective');
    raise exception 'Expected objective failure';
  exception when raise_exception then
    if sqlerrm <> 'Forced objective failure' then raise; end if;
  end;
  if (select count(*) from public.challenges) <> v_count then
    raise exception 'Failed creation left a partial challenge';
  end if;

  -- Also exercise the old app's multi-request creation path under fixed RLS.
  insert into public.challenges (
    created_by_profile_id, challenge_type, title, scoring_type, start_at, end_at, status
  ) values (
    v_profile_id, 'weekly_short', 'Legacy creation regression',
    'completion_count', now(), now() + interval '7 days', 'active'
  ) returning id into v_id;
  insert into public.challenge_members (challenge_id, profile_id, role)
  values (v_id, v_profile_id, 'owner');
end;
$$;

select set_config('request.jwt.claim.sub', outsider_auth_id::text, true)
from social_creation_test_state;
do $$
begin
  if exists (select 1 from public.challenges) then
    raise exception 'Non-participant can read challenges';
  end if;
  if exists (select 1 from public.challenge_members) then
    raise exception 'Non-participant can read memberships';
  end if;
  if (select count(*) from public.profiles) <> 1 then
    raise exception 'Non-participant can read other profiles';
  end if;
end;
$$;

select set_config('request.jwt.claim.sub', peer_auth_id::text, true)
from social_creation_test_state;
select public.accept_challenge_invite(invite_token) from social_creation_test_state;
do $$
declare
  v_id uuid := (select challenge_id from social_creation_test_state);
begin
  if not public.is_challenge_member(v_id) then
    raise exception 'Invitation did not add peer';
  end if;
  if (select count(*) from public.challenge_members where challenge_id = v_id) <> 2 then
    raise exception 'Participants cannot read the member list';
  end if;
  if (select count(*) from public.profiles) <> 2 then
    raise exception 'Participants cannot read each other profiles';
  end if;
  perform public.create_social_challenge('Peer challenge', 'weekly_short');
end;
$$;

select set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
do $$
begin
  begin
    perform public.create_social_challenge('Missing profile', 'weekly_short');
    raise exception 'Missing profile was accepted';
  exception when no_data_found then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', '', true);
do $$
begin
  begin
    perform public.create_social_challenge('No session', 'weekly_short');
    raise exception 'Missing session was accepted';
  exception when invalid_authorization_specification then null;
  end;
end;
$$;

reset role;
do $$
begin
  if has_function_privilege('anon', 'public.create_social_challenge(text, public.challenge_type, text)', 'execute') then
    raise exception 'Anonymous callers can execute creation RPC';
  end if;
end;
$$;
rollback;
