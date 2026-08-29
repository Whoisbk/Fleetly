-- Run this in the Supabase SQL editor to enable auth + profiles

create type user_role as enum ('admin', 'driver');
create type user_status as enum ('pending', 'approved', 'rejected', 'suspended');

create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role user_role not null default 'driver',
  first_name text not null,
  last_name text not null,
  phone text,
  email text not null,
  profile_photo text,
  status user_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Auto-create profile when a user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, last_name, phone, role, status)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    'driver',
    'pending'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table profiles enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Drivers read/update own profile; admins read all
create policy "users_read_own_profile" on profiles
  for select using (auth.uid() = id);

create policy "users_update_own_profile" on profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id and role = (select role from profiles where id = auth.uid()));

create policy "admin_read_all_profiles" on profiles
  for select using (public.is_admin());

create policy "admin_update_profiles" on profiles
  for update using (public.is_admin());

-- If you already signed up before running this migration, backfill your profile:
-- insert into public.profiles (id, email, first_name, last_name, phone, role, status)
-- select
--   id,
--   email,
--   coalesce(raw_user_meta_data ->> 'first_name', ''),
--   coalesce(raw_user_meta_data ->> 'last_name', ''),
--   coalesce(raw_user_meta_data ->> 'phone', ''),
--   'driver',
--   'pending'
-- from auth.users
-- where id not in (select id from public.profiles);
