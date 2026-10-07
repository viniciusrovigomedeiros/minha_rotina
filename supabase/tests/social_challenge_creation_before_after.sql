-- Only run on an isolated test database, after applying the social migrations.
-- Reproduce the original RLS recursion without keeping any schema/data changes.
begin;
alter function public.current_profile_id() security invoker;
alter function public.is_group_member(uuid) security invoker;
alter function public.is_challenge_member(uuid) security invoker;

insert into auth.users (id, raw_user_meta_data)
values ('a0000000-0000-0000-0000-000000000001', '{"full_name":"Regression owner"}');
set local role authenticated;
select set_config('request.jwt.claim.sub', 'a0000000-0000-0000-0000-000000000001', true);

do $$
declare
  v_reproduced boolean := false;
begin
  begin
    perform id from public.profiles where auth_user_id = auth.uid();
  exception when sqlstate '54001' then
    if sqlerrm <> 'stack depth limit exceeded' then raise; end if;
    v_reproduced := true;
    raise notice 'Original failure reproduced: % (SQLSTATE %)', sqlerrm, sqlstate;
  end;
  if not v_reproduced then
    raise exception 'Expected the original RLS recursion to fail';
  end if;
end;
$$;
rollback;

-- With the corrected helpers restored, verify creation, invites and failures.
\ir social_challenge_creation.sql
