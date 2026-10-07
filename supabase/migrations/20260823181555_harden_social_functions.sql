alter function public.set_updated_at() set search_path = '';
alter function public.current_profile_id() set search_path = '';
alter function public.is_group_member(uuid) set search_path = '';
alter function public.is_challenge_member(uuid) set search_path = '';

revoke execute on function public.create_profile_for_new_user() from public;
