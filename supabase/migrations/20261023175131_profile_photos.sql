-- Persist the profile photos added by the refreshed account screens.
-- Photos remain in the user's own profile row; matching includes only the
-- assigned caregiver's photo in the booking payload.
alter table public.profiles
  add column if not exists avatar_data_url text;

alter table public.profiles
  drop constraint if exists profiles_avatar_data_url_size_check;
alter table public.profiles
  add constraint profiles_avatar_data_url_size_check
  check (avatar_data_url is null or length(avatar_data_url) <= 1000000);

grant update (full_name, phone, avatar_data_url) on public.profiles to authenticated;

create or replace function public.create_care_request(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_seeker uuid := auth.uid();
  v_id uuid;
  v_caregiver record;
  v_data jsonb;
  v_filter text := coalesce(p_payload->>'genderFilter', 'both');
  v_duration integer := (p_payload->>'durationMinutes')::integer;
  v_base integer;
  v_fee integer;
  v_grab integer;
  v_reference text;
  v_button_id text;
  v_status text := 'matched';
begin
  if v_seeker is null then raise exception 'Sign in required'; end if;
  if not exists (select 1 from public.profiles p where p.id = v_seeker and p.role = 'seeker') then
    raise exception 'A care seeker account is required';
  end if;
  if v_duration not in (30, 45, 60, 90, 120) then raise exception 'Invalid visit duration'; end if;
  if v_filter not in ('male', 'female', 'both') then raise exception 'Invalid caregiver filter'; end if;

  select p.id, p.full_name, p.avatar_data_url, cp.gender, cp.rating,
         cp.review_count, cp.availability
    into v_caregiver
    from public.profiles p
    join public.caregiver_profiles cp on cp.user_id = p.id
   where p.role = 'caregiver'
     and cp.verification_status = 'approved'
     and cp.safety_module_completed
     and cp.availability = 'available'
     and (v_filter = 'both' or cp.gender = v_filter)
     and not exists (
       select 1 from public.bookings b
       where b.caregiver_id = p.id and b.status in (
         'paidPending', 'confirmed', 'caregiverTravelling', 'arrived',
         'codeVerified', 'buttonVerified', 'active'
       )
     )
   order by cp.rating desc, cp.review_count desc, cp.created_at
   limit 1 for update of cp skip locked;
  if not found then v_status := 'noMatch'; end if;

  v_base := round(25000 * v_duration / 30.0);
  v_fee := round(v_base * 0.05);
  v_grab := case v_duration when 30 then 30000 when 45 then 35000
    when 60 then 40000 when 90 then 50000 else 60000 end;
  v_reference := 'CF-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_id := gen_random_uuid();
  v_button_id := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
  v_data := (p_payload - 'location' - 'clientCode' - 'safetyButtonId') ||
    jsonb_build_object(
      'id', v_id,
      'requestReference', v_reference,
      'caregiver', case when v_status = 'matched' then jsonb_build_object(
        'id', v_caregiver.id, 'name', v_caregiver.full_name,
        'avatarDataUrl', v_caregiver.avatar_data_url,
        'gender', v_caregiver.gender, 'rating', v_caregiver.rating,
        'reviewCount', v_caregiver.review_count, 'identityVerified', true,
        'safetyBadge', true, 'availability', v_caregiver.availability
      ) else null end,
      'price', jsonb_build_object(
        'caregiverPrice', v_base, 'platformFee', v_fee, 'grabFare', v_grab
      ),
      'status', v_status, 'createdAt', now(), 'updates', '[]'::jsonb
    );

  insert into public.bookings(id, seeker_id, caregiver_id, status, payload)
  values (v_id, v_seeker,
    case when v_status = 'matched' then v_caregiver.id else null end,
    v_status, v_data);
  insert into public.booking_private(booking_id, location)
  values (v_id, p_payload->'location');
  insert into public.booking_secrets(booking_id, safety_button_id)
  values (v_id, v_button_id);
  return v_id;
end;
$$;

revoke execute on function public.create_care_request(jsonb) from public, anon;
grant execute on function public.create_care_request(jsonb) to authenticated;
