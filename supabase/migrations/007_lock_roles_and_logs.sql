-- Lock who can change role, status, document approval, and submitted logs.
-- Run in the Supabase SQL Editor after 006_storage_buckets.sql.
--
-- Drivers can create a pending profile and re-upload documents as pending.
-- Only an admin can approve, reject, or suspend a driver or a document.
-- A submitted day and its expenses cannot be deleted or edited.

-- New profiles from the signed-in user are always pending drivers.
-- An existing admin changes role later with the admin update policy.
create or replace function public.protect_profile_insert()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() then
    return new;
  end if;

  new.role := 'driver';
  new.status := 'pending';
  return new;
end;
$$;

drop trigger if exists protect_profile_insert on public.profiles;
create trigger protect_profile_insert
  before insert on public.profiles
  for each row execute function public.protect_profile_insert();

-- Non-admins cannot change their own role or status.
create or replace function public.protect_profile_role_status()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() then
    return new;
  end if;

  if new.role is distinct from old.role or new.status is distinct from old.status then
    raise exception 'Only an administrator can change role or status';
  end if;

  return new;
end;
$$;

drop trigger if exists protect_profile_role_status on public.profiles;
create trigger protect_profile_role_status
  before update on public.profiles
  for each row execute function public.protect_profile_role_status();

drop policy if exists "users_insert_own_profile" on public.profiles;
create policy "users_insert_own_profile" on public.profiles
  for insert with check (
    (select public.current_uid()) = id
    and role = 'driver'
    and status = 'pending'
  );

drop policy if exists "users_update_own_profile" on public.profiles;
create policy "users_update_own_profile" on public.profiles
  for update using ((select public.current_uid()) = id)
  with check (
    (select public.current_uid()) = id
    and role = (select p.role from public.profiles p where p.id = public.current_uid())
    and status = (select p.status from public.profiles p where p.id = public.current_uid())
  );

-- Drivers may upload documents, and a re-upload stays pending.
-- They cannot mark a document approved or rejected.
create or replace function public.protect_document_status()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.rejection_reason := null;
    return new;
  end if;

  if new.status is distinct from old.status and new.status <> 'pending' then
    raise exception 'Only an administrator can change document status';
  end if;

  if new.status = 'pending' and old.status is distinct from 'pending' then
    new.rejection_reason := null;
  end if;

  return new;
end;
$$;

drop trigger if exists protect_document_status on public.driver_documents;
create trigger protect_document_status
  before insert or update on public.driver_documents
  for each row execute function public.protect_document_status();

drop policy if exists "drivers_insert_own_documents" on public.driver_documents;
create policy "drivers_insert_own_documents" on public.driver_documents
  for insert with check (
    driver_id = public.current_uid()
    and status = 'pending'
  );

drop policy if exists "drivers_update_own_documents" on public.driver_documents;
create policy "drivers_update_own_documents" on public.driver_documents
  for update using (driver_id = public.current_uid())
  with check (
    driver_id = public.current_uid()
    and status = 'pending'
  );

-- Submitted days stay on the record. Drivers can still finish an active day.
drop policy if exists "drivers_update_own_days" on public.driver_days;
create policy "drivers_update_own_days" on public.driver_days
  for update using (
    driver_id = public.current_uid()
    and status = 'active'
  )
  with check (driver_id = public.current_uid());

drop policy if exists "drivers_delete_own_days" on public.driver_days;
create policy "drivers_delete_own_days" on public.driver_days
  for delete using (
    driver_id = public.current_uid()
    and status = 'active'
  );

-- Expenses follow the day: writable only while that day is still active.
drop policy if exists "drivers_insert_own_expenses" on public.expenses;
create policy "drivers_insert_own_expenses" on public.expenses
  for insert with check (
    driver_id = public.current_uid()
    and exists (
      select 1 from public.driver_days d
      where d.id = driver_day_id
        and d.driver_id = public.current_uid()
        and d.status = 'active'
    )
  );

drop policy if exists "drivers_update_own_expenses" on public.expenses;
create policy "drivers_update_own_expenses" on public.expenses
  for update using (
    driver_id = public.current_uid()
    and exists (
      select 1 from public.driver_days d
      where d.id = expenses.driver_day_id
        and d.status = 'active'
    )
  )
  with check (
    driver_id = public.current_uid()
    and exists (
      select 1 from public.driver_days d
      where d.id = expenses.driver_day_id
        and d.status = 'active'
    )
  );

drop policy if exists "drivers_delete_own_expenses" on public.expenses;
create policy "drivers_delete_own_expenses" on public.expenses
  for delete using (
    driver_id = public.current_uid()
    and exists (
      select 1 from public.driver_days d
      where d.id = expenses.driver_day_id
        and d.status = 'active'
    )
  );
