-- Kilometres are tracked from GPS during an active day, not typed in by the driver.
alter table public.driver_days
  add column if not exists distance_km numeric(10, 2) not null default 0;

-- A client bug or a replayed request must not wipe distance already stored.
create or replace function public.prevent_distance_decrease()
returns trigger
language plpgsql
as $$
begin
  if new.distance_km < old.distance_km then
    new.distance_km := old.distance_km;
  end if;
  return new;
end;
$$;

drop trigger if exists driver_days_distance_monotonic on public.driver_days;
create trigger driver_days_distance_monotonic
  before update on public.driver_days
  for each row execute function public.prevent_distance_decrease();
