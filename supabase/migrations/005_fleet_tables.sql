-- Fleet tables: vehicles, driver assignments, daily logs, expenses, documents.
-- Uses Firebase UID (text) via current_uid() from migration 004.

-- Enums
create type expense_type as enum ('fuel', 'maintenance', 'repair', 'other');
create type driver_day_status as enum ('active', 'completed');
create type document_type as enum ('id', 'pdp');
create type document_status as enum ('pending', 'approved', 'rejected');

-- Vehicles
create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  registration_number text not null,
  make text not null,
  model text not null,
  year int,
  color text,
  created_at timestamptz not null default now()
);

-- Driver ↔ vehicle assignments (history)
create table public.driver_vehicle (
  id uuid primary key default gen_random_uuid(),
  driver_id text not null references public.profiles (id) on delete cascade,
  vehicle_id uuid not null references public.vehicles (id) on delete restrict,
  start_date date not null default current_date,
  end_date date,
  created_at timestamptz not null default now()
);

create index driver_vehicle_active_idx on public.driver_vehicle (driver_id)
  where end_date is null;

-- Daily driver log (core MVP table)
create table public.driver_days (
  id uuid primary key default gen_random_uuid(),
  driver_id text not null references public.profiles (id) on delete cascade,
  vehicle_id uuid not null references public.vehicles (id) on delete restrict,
  date date not null,
  started_at timestamptz,
  ended_at timestamptz,
  starting_odometer int,
  ending_odometer int,
  total_earnings numeric(12, 2) not null default 0,
  notes text,
  status driver_day_status not null default 'active',
  created_at timestamptz not null default now(),
  unique (driver_id, date)
);

create index driver_days_driver_date_idx on public.driver_days (driver_id, date desc);
create index driver_days_date_idx on public.driver_days (date);

-- Expenses linked to a driver day
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  driver_day_id uuid not null references public.driver_days (id) on delete cascade,
  driver_id text not null references public.profiles (id) on delete cascade,
  vehicle_id uuid not null references public.vehicles (id) on delete restrict,
  type expense_type not null,
  amount numeric(12, 2) not null,
  description text,
  receipt_path text,
  created_at timestamptz not null default now()
);

create index expenses_driver_day_idx on public.expenses (driver_day_id);
create index expenses_created_at_idx on public.expenses (created_at desc);

-- Driver onboarding documents (ID, PDP)
create table public.driver_documents (
  id uuid primary key default gen_random_uuid(),
  driver_id text not null references public.profiles (id) on delete cascade,
  document_type document_type not null,
  file_path text not null,
  status document_status not null default 'pending',
  uploaded_at timestamptz not null default now(),
  rejection_reason text,
  unique (driver_id, document_type)
);

-- RLS
alter table public.vehicles enable row level security;
alter table public.driver_vehicle enable row level security;
alter table public.driver_days enable row level security;
alter table public.expenses enable row level security;
alter table public.driver_documents enable row level security;

-- vehicles: admins manage; drivers read assigned vehicles
create policy "admin_manage_vehicles" on public.vehicles
  for all using (public.is_admin())
  with check (public.is_admin());

create policy "drivers_read_assigned_vehicles" on public.vehicles
  for select using (
    exists (
      select 1 from public.driver_vehicle dv
      where dv.vehicle_id = vehicles.id
        and dv.driver_id = public.current_uid()
        and dv.end_date is null
    )
  );

-- driver_vehicle
create policy "drivers_read_own_assignments" on public.driver_vehicle
  for select using (driver_id = public.current_uid());

create policy "admin_manage_assignments" on public.driver_vehicle
  for all using (public.is_admin())
  with check (public.is_admin());

-- driver_days
create policy "drivers_read_own_days" on public.driver_days
  for select using (driver_id = public.current_uid());

create policy "drivers_insert_own_days" on public.driver_days
  for insert with check (driver_id = public.current_uid());

create policy "drivers_update_own_days" on public.driver_days
  for update using (driver_id = public.current_uid())
  with check (driver_id = public.current_uid());

create policy "drivers_delete_own_days" on public.driver_days
  for delete using (driver_id = public.current_uid());

create policy "admin_read_all_days" on public.driver_days
  for select using (public.is_admin());

-- expenses
create policy "drivers_read_own_expenses" on public.expenses
  for select using (driver_id = public.current_uid());

create policy "drivers_insert_own_expenses" on public.expenses
  for insert with check (driver_id = public.current_uid());

create policy "drivers_update_own_expenses" on public.expenses
  for update using (driver_id = public.current_uid())
  with check (driver_id = public.current_uid());

create policy "drivers_delete_own_expenses" on public.expenses
  for delete using (driver_id = public.current_uid());

create policy "admin_read_all_expenses" on public.expenses
  for select using (public.is_admin());

-- driver_documents
create policy "drivers_read_own_documents" on public.driver_documents
  for select using (driver_id = public.current_uid());

create policy "drivers_insert_own_documents" on public.driver_documents
  for insert with check (driver_id = public.current_uid());

create policy "drivers_update_own_documents" on public.driver_documents
  for update using (driver_id = public.current_uid())
  with check (driver_id = public.current_uid());

create policy "admin_read_all_documents" on public.driver_documents
  for select using (public.is_admin());

create policy "admin_update_documents" on public.driver_documents
  for update using (public.is_admin());
