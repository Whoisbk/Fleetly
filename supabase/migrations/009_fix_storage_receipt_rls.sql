-- Fix receipt uploads: "new row violates row-level security policy".
-- Run in the Supabase SQL Editor after 008_fix_profiles_policy_recursion.sql.
--
-- The expense row inserts successfully, then the receipt upload is rejected.
-- fleet-files policies were limited to the authenticated role. This app signs
-- in with Firebase, and that token is not the authenticated role, so none of
-- the storage policies applied.
--
-- Uploads stay limited to the signed-in driver's own folder:
-- fleet-files/{firebase_uid}/receipts/{expense_id}.{ext}

create or replace function public.storage_driver_owns_folder(object_name text)
returns boolean
language sql
stable
set search_path = public
as $$
  select split_part(coalesce(object_name, ''), '/', 1) = public.current_uid()
    and public.current_uid() <> '';
$$;

drop policy if exists "storage_fleet_files_select" on storage.objects;
drop policy if exists "storage_fleet_files_insert" on storage.objects;
drop policy if exists "storage_fleet_files_update" on storage.objects;
drop policy if exists "storage_fleet_files_delete" on storage.objects;

create policy "storage_fleet_files_select" on storage.objects
  for select
  using (
    bucket_id = 'fleet-files'
    and (
      public.storage_driver_owns_folder(name)
      or public.is_admin()
    )
  );

create policy "storage_fleet_files_insert" on storage.objects
  for insert
  with check (
    bucket_id = 'fleet-files'
    and public.storage_driver_owns_folder(name)
  );

create policy "storage_fleet_files_update" on storage.objects
  for update
  using (
    bucket_id = 'fleet-files'
    and public.storage_driver_owns_folder(name)
  )
  with check (
    bucket_id = 'fleet-files'
    and public.storage_driver_owns_folder(name)
  );

create policy "storage_fleet_files_delete" on storage.objects
  for delete
  using (
    bucket_id = 'fleet-files'
    and (
      public.storage_driver_owns_folder(name)
      or public.is_admin()
    )
  );
