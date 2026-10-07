create or replace function public.create_challenge_invite(p_challenge_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_token text := replace(gen_random_uuid()::text, '-', '');
begin
  if not exists (
    select 1
    from public.challenges c
    where c.id = p_challenge_id
      and c.created_by_profile_id = public.current_profile_id()
  ) then
    raise exception 'Only the challenge owner can create invites';
  end if;

  insert into public.social_invites (
    created_by_profile_id,
    invite_type,
    target_type,
    target_id,
    token,
    expires_at
  ) values (
    public.current_profile_id(),
    'challenge',
    'challenge',
    p_challenge_id,
    v_token,
    timezone('utc', now()) + interval '14 days'
  );

  return v_token;
end;
$$;

create or replace function public.accept_challenge_invite(p_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_invite_id uuid;
  v_challenge_id uuid;
  v_profile_id uuid;
begin
  select p.id into v_profile_id
  from public.profiles p
  where p.auth_user_id = auth.uid();

  if v_profile_id is null then
    raise exception 'Profile not found';
  end if;

  select i.id, i.target_id into v_invite_id, v_challenge_id
  from public.social_invites i
  where i.token = p_token
    and i.invite_type = 'challenge'
    and i.target_type = 'challenge'
    and i.status = 'pending'
    and i.expires_at > timezone('utc', now())
  for update;

  if v_invite_id is null or v_challenge_id is null then
    raise exception 'Invite is invalid or expired';
  end if;

  insert into public.challenge_members (challenge_id, profile_id)
  values (v_challenge_id, v_profile_id)
  on conflict (challenge_id, profile_id) do nothing;

  update public.social_invites
  set status = 'accepted',
      accepted_by_profile_id = v_profile_id,
      accepted_at = timezone('utc', now())
  where id = v_invite_id;

  return v_challenge_id;
end;
$$;

revoke execute on function public.create_challenge_invite(uuid) from public, anon;
revoke execute on function public.accept_challenge_invite(text) from public, anon;
grant execute on function public.create_challenge_invite(uuid) to authenticated;
grant execute on function public.accept_challenge_invite(text) to authenticated;
