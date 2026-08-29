-- Firebase Auth: profiles use Firebase UID (text), not Supabase auth.users.
-- Run this in the Supabase SQL Editor:
-- https://supabase.com/dashboard/project/jtykzxckmegndmsmsibx/sql/new
--
-- Do not use auth.uid() here. It casts JWT sub to uuid and fails for
-- Firebase UIDs like "t8G2YFZ0TWZN4rDRACLKacqzbeY2".

-- Remove Supabase Auth trigger and handler
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Drop ALL policies first (Postgres blocks column type changes while policies reference the column)
drop policy if exists "users_insert_own_profile" on public.profiles;
drop policy if exists "users_read_own_profile" on public.profiles;
drop policy if exists "users_update_own_profile" on public.profiles;
drop policy if exists "admin_read_all_profiles" on public.profiles;
drop policy if exists "admin_update_profiles" on public.profiles;

-- Change profiles.id to text for Firebase UIDs
alter table public.profiles drop constraint if exists profiles_id_fkey;
alter table public.profiles alter column id type text using id::text;

-- Firebase UID from the JWT (auth.uid() cannot parse non-uuid subjects)
create or replace function public.current_uid()
returns text
language sql
stable
as $$
  select coalesce(auth.jwt() ->> 'sub', '');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = public.current_uid() and role = 'admin'
  );
$$;

create policy "users_insert_own_profile" on public.profiles
  for insert with check ((select public.current_uid()) = id);

create policy "users_read_own_profile" on public.profiles
  for select using ((select public.current_uid()) = id);

create policy "users_update_own_profile" on public.profiles
  for update using ((select public.current_uid()) = id)
  with check (
    (select public.current_uid()) = id
    and role = (select role from profiles where id = public.current_uid())
  );

create policy "admin_read_all_profiles" on public.profiles
  for select using (public.is_admin());

create policy "admin_update_profiles" on public.profiles
  for update using (public.is_admin());
