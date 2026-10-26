create table public.care_ratings (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('caregiver_ratings', 'care_seeker_ratings')),
  author_id uuid not null references public.profiles(id) on delete cascade,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  unique (kind, author_id, booking_id)
);
create table public.app_feedback (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  payload jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.care_ratings enable row level security;
alter table public.app_feedback enable row level security;
revoke all on public.care_ratings, public.app_feedback from public, anon, authenticated;

create or replace function public.submit_caregiver_verification()
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles where id = auth.uid() and role = 'caregiver'
  ) then raise exception 'Caregiver account required'; end if;
  update public.caregiver_profiles
     set verification_status = 'pending', updated_at = now()
   where user_id = auth.uid() and verification_status in ('notSubmitted', 'rejected');
end;
$$;

create or replace function public.complete_caregiver_safety_module()
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles where id = auth.uid() and role = 'caregiver'
  ) then raise exception 'Caregiver account required'; end if;
  update public.caregiver_profiles set safety_module_completed = true, updated_at = now()
   where user_id = auth.uid();
end;
$$;

create or replace function public.save_care_rating(p_rating jsonb, p_kind text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_booking public.bookings%rowtype; v_uid uuid := auth.uid();
begin
  if p_kind not in ('caregiver_ratings', 'care_seeker_ratings') then raise exception 'Invalid rating type'; end if;
  select * into v_booking from public.bookings where id = (p_rating->>'bookingId')::uuid;
  if not found or v_booking.status not in ('completed', 'endedEarly') then raise exception 'Only finished bookings can be rated'; end if;
  if (p_kind = 'caregiver_ratings' and v_booking.seeker_id <> v_uid)
    or (p_kind = 'care_seeker_ratings' and v_booking.caregiver_id <> v_uid) then raise exception 'Not allowed'; end if;
  if coalesce((p_rating->>'stars')::integer, 0) not between 1 and 5 then raise exception 'Rating must be 1 to 5'; end if;
  insert into public.care_ratings(kind, author_id, booking_id, payload)
  values (p_kind, v_uid, v_booking.id, p_rating)
  on conflict (kind, author_id, booking_id) do update set payload = excluded.payload;
end;
$$;

create or replace function public.save_app_feedback(p_feedback jsonb)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if coalesce((p_feedback->>'stars')::integer, 0) not between 1 and 5 then raise exception 'Rating must be 1 to 5'; end if;
  insert into public.app_feedback(author_id, payload) values (auth.uid(), p_feedback);
end;
$$;

revoke execute on function public.submit_caregiver_verification() from public, anon;
revoke execute on function public.complete_caregiver_safety_module() from public, anon;
revoke execute on function public.save_care_rating(jsonb, text) from public, anon;
revoke execute on function public.save_app_feedback(jsonb) from public, anon;
grant execute on function public.submit_caregiver_verification() to authenticated;
grant execute on function public.complete_caregiver_safety_module() to authenticated;
grant execute on function public.save_care_rating(jsonb, text) to authenticated;
grant execute on function public.save_app_feedback(jsonb) to authenticated;
