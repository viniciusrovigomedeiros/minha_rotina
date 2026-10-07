drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_social_peers" on public.profiles
for select using (
  auth.uid() = auth_user_id
  or exists (
    select 1
    from public.challenge_members mine
    join public.challenge_members peer on peer.challenge_id = mine.challenge_id
    where mine.profile_id = public.current_profile_id()
      and peer.profile_id = profiles.id
      and mine.status = 'active'
      and peer.status = 'active'
  )
);

create or replace function public.refresh_challenge_score()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_check_in_count integer;
begin
  select count(*)::integer into v_check_in_count
  from public.social_check_ins c
  where c.challenge_id = new.challenge_id
    and c.profile_id = new.profile_id;

  insert into public.challenge_scores (
    challenge_id,
    profile_id,
    score_total,
    check_in_score,
    current_streak,
    last_calculated_at
  ) values (
    new.challenge_id,
    new.profile_id,
    v_check_in_count * 10,
    v_check_in_count * 10,
    v_check_in_count,
    timezone('utc', now())
  )
  on conflict (challenge_id, profile_id) do update
  set score_total = excluded.score_total,
      check_in_score = excluded.check_in_score,
      current_streak = excluded.current_streak,
      last_calculated_at = excluded.last_calculated_at;

  return new;
end;
$$;

revoke execute on function public.refresh_challenge_score() from public, anon, authenticated;

drop trigger if exists refresh_challenge_score_after_check_in on public.social_check_ins;
create trigger refresh_challenge_score_after_check_in
after insert on public.social_check_ins
for each row execute function public.refresh_challenge_score();

create or replace function public.enqueue_social_notification(
  p_profile_id uuid,
  p_notification_type text,
  p_title text,
  p_body text,
  p_target_type text default null,
  p_target_id uuid default null,
  p_aggregation_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_notification_id uuid;
begin
  insert into public.notifications (
    profile_id,
    notification_type,
    title,
    body,
    target_type,
    target_id,
    aggregation_key
  ) values (
    p_profile_id,
    p_notification_type,
    p_title,
    p_body,
    p_target_type,
    p_target_id,
    p_aggregation_key
  ) returning id into v_notification_id;

  return v_notification_id;
end;
$$;

revoke execute on function public.enqueue_social_notification(uuid, text, text, text, text, uuid, text) from public, anon, authenticated;
