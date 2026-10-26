-- Supabase foundation for account identity and caregiver discovery.
-- Sensitive identity document data is deliberately not stored in these public
-- profile tables. Booking state remains in the existing shared backend for now.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null check (role in ('seeker', 'caregiver')),
  full_name text not null default '',
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.caregiver_profiles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  gender text not null check (gender in ('male', 'female')),
  rating numeric(2, 1) not null default 0 check (rating between 0 and 5),
  review_count integer not null default 0 check (review_count >= 0),
  verification_status text not null default 'notSubmitted'
    check (verification_status in ('notSubmitted', 'pending', 'approved', 'rejected')),
  safety_module_completed boolean not null default false,
  availability text not null default 'available'
    check (availability in ('available', 'unavailable')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  user_role text := coalesce(new.raw_user_meta_data ->> 'role', 'seeker');
  caregiver_gender text := new.raw_user_meta_data ->> 'gender';
begin
  if user_role not in ('seeker', 'caregiver') then
    raise exception 'Unsupported account role';
  end if;

  insert into public.profiles (id, role, full_name, phone)
  values (
    new.id,
    user_role,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.phone
  );

  if user_role = 'caregiver' then
    if caregiver_gender not in ('male', 'female') then
      raise exception 'Caregiver gender must be provided as male or female';
    end if;
    insert into public.caregiver_profiles (user_id, gender)
    values (new.id, caregiver_gender);
  end if;

  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.caregiver_profiles enable row level security;

revoke all on public.profiles from anon, authenticated;
revoke all on public.caregiver_profiles from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;
grant select on public.caregiver_profiles to authenticated;
grant update (gender, availability) on public.caregiver_profiles to authenticated;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Caregivers can read their own profile"
  on public.caregiver_profiles for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Seekers can discover approved caregivers"
  on public.caregiver_profiles for select to authenticated
  using (
    verification_status = 'approved'
    and safety_module_completed
  );

create policy "Caregivers can update their own matching preferences"
  on public.caregiver_profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger caregiver_profiles_set_updated_at
  before update on public.caregiver_profiles
  for each row execute function public.set_updated_at();
