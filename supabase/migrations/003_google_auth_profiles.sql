-- Improve profile creation for Google OAuth users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_first_name text;
  v_last_name text;
  v_full_name text;
begin
  v_first_name := coalesce(new.raw_user_meta_data ->> 'first_name', '');
  v_last_name := coalesce(new.raw_user_meta_data ->> 'last_name', '');
  v_full_name := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'name',
    ''
  );

  if v_first_name = '' and v_full_name <> '' then
    v_first_name := split_part(v_full_name, ' ', 1);
    v_last_name := nullif(trim(substring(v_full_name from position(' ' in v_full_name))), '');
    if v_last_name is null then v_last_name := ''; end if;
  end if;

  insert into public.profiles (id, email, first_name, last_name, phone, role, status)
  values (
    new.id,
    coalesce(new.email, ''),
    v_first_name,
    v_last_name,
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    'driver',
    'pending'
  );
  return new;
end;
$$;
