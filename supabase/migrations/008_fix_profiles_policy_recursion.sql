-- Fix 42P17: infinite recursion in the profiles update policy.
-- Run in the Supabase SQL Editor after 007_lock_roles_and_logs.sql.
--
-- users_update_own_profile checked role and status by selecting from
-- profiles while Postgres was already enforcing policies on profiles.
-- That self-read is rejected as infinite recursion, so every profile
-- update fails, including an admin approving a driver.
--
-- Non-admins still cannot change role or status. The
-- protect_profile_role_status trigger raises if they try.

drop policy if exists "users_update_own_profile" on public.profiles;
create policy "users_update_own_profile" on public.profiles
  for update using ((select public.current_uid()) = id)
  with check ((select public.current_uid()) = id);
