-- Allow users to create their own profile (fallback if trigger missed)
create policy "users_insert_own_profile" on profiles
  for insert with check (auth.uid() = id);

-- Backfill any auth users missing a profile
insert into public.profiles (id, email, first_name, last_name, phone, role, status)
select
  id,
  email,
  coalesce(raw_user_meta_data ->> 'first_name', ''),
  coalesce(raw_user_meta_data ->> 'last_name', ''),
  coalesce(raw_user_meta_data ->> 'phone', ''),
  'driver',
  'pending'
from auth.users
where id not in (select id from public.profiles)
on conflict (id) do nothing;
