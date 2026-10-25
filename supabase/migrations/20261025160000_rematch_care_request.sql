-- Let a care seeker reject a pre-payment quote and search again without
-- offering the same caregiver a second time.
create or replace function public.rematch_care_request(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_booking public.bookings%rowtype;
  v_caregiver record;
  v_status text := 'matched';
  v_filter text;
  v_payload jsonb;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;

  select * into v_booking
    from public.bookings
   where id = p_booking_id
   for update;

  if not found or v_booking.seeker_id <> v_uid then
    raise exception 'This request does not belong to this care seeker';
  end if;
  if v_booking.status <> 'matched' or v_booking.caregiver_id is null then
    raise exception 'Only an unpaid match can be replaced';
  end if;

  v_filter := coalesce(v_booking.payload->>'genderFilter', 'both');

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
     and p.id <> v_booking.caregiver_id
     and not exists (
       select 1 from public.bookings b
        where b.caregiver_id = p.id
          and b.id <> p_booking_id
          and b.status in (
            'matched', 'paidPending', 'confirmed', 'caregiverTravelling',
            'arrived', 'codeVerified', 'buttonVerified', 'active'
          )
     )
   order by cp.rating desc, cp.review_count desc, cp.created_at
   limit 1
   for update of cp skip locked;

  if not found then
    v_status := 'noMatch';
    v_payload := v_booking.payload || jsonb_build_object(
      'caregiver', null,
      'status', v_status
    );
    update public.bookings
       set caregiver_id = null,
           status = v_status,
           payload = v_payload,
           updated_at = now()
     where id = p_booking_id;
  else
    v_payload := v_booking.payload || jsonb_build_object(
      'caregiver', jsonb_build_object(
        'id', v_caregiver.id,
        'name', v_caregiver.full_name,
        'avatarDataUrl', v_caregiver.avatar_data_url,
        'gender', v_caregiver.gender,
        'rating', v_caregiver.rating,
        'reviewCount', v_caregiver.review_count,
        'identityVerified', true,
        'safetyBadge', true,
        'availability', v_caregiver.availability
      ),
      'status', v_status
    );
    update public.bookings
       set caregiver_id = v_caregiver.id,
           status = v_status,
           payload = v_payload,
           updated_at = now()
     where id = p_booking_id;
  end if;

  return jsonb_build_object('success', true, 'status', v_status);
end;
$$;

revoke execute on function public.rematch_care_request(uuid)
  from public, anon;
grant execute on function public.rematch_care_request(uuid)
  to authenticated;
