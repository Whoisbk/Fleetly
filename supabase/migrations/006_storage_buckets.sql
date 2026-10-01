-- Single private bucket for all fleet file uploads.
-- Paths (first folder segment = Firebase UID / driver_id):
--   fleet-files/{driver_id}/documents/id.{ext}
--   fleet-files/{driver_id}/documents/pdp.{ext}
--   fleet-files/{driver_id}/profile/profile.{ext}
--   fleet-files/{driver_id}/receipts/{expense_id}.{ext}

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'fleet-files',
  'fleet-files',
  false,
  10485760,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Clean up policies from the earlier 3-bucket version (safe if never applied).
drop policy if exists "storage_driver_documents_select" on storage.objects;
drop policy if exists "storage_driver_documents_insert" on storage.objects;
drop policy if exists "storage_driver_documents_update" on storage.objects;
drop policy if exists "storage_driver_documents_delete" on storage.objects;
drop policy if exists "storage_profile_images_select" on storage.objects;
drop policy if exists "storage_profile_images_insert" on storage.objects;
drop policy if exists "storage_profile_images_update" on storage.objects;
drop policy if exists "storage_profile_images_delete" on storage.objects;
drop policy if exists "storage_expense_receipts_select" on storage.objects;
drop policy if exists "storage_expense_receipts_insert" on storage.objects;
drop policy if exists "storage_expense_receipts_update" on storage.objects;
drop policy if exists "storage_expense_receipts_delete" on storage.objects;

-- True when the object's first path segment matches the signed-in Firebase UID.
-- split_part avoids storage.foldername, which the request role may not be
-- allowed to call. An empty uid (no Firebase token) never matches.
create or replace function public.storage_driver_owns_folder(object_name text)
returns boolean
language sql
stable
set search_path = public
as $$
  select split_part(coalesce(object_name, ''), '/', 1) = public.current_uid()
    and public.current_uid() <> '';
$$;

-- No TO authenticated. Firebase ID tokens are not the authenticated role,
-- so a role-restricted policy never applies and every upload is rejected.
-- current_uid() still requires a signed-in Firebase user.
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
