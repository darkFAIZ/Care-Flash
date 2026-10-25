-- The care seeker should never read the safety token directly. The caregiver
-- receives it only after the seeker confirms the arrival code. These helpers
-- also support the laptop demo, where a physical camera scan is unavailable.

create or replace function public.caregiver_safety_button_token(p_booking_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_status text;
  v_caregiver_id uuid;
  v_token text;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;

  select b.status, b.caregiver_id
    into v_status, v_caregiver_id
    from public.bookings b
   where b.id = p_booking_id
   for update;

  if not found or v_caregiver_id <> v_uid then
    raise exception 'This booking is not assigned to this caregiver';
  end if;
  if v_status not in ('codeVerified', 'buttonVerified', 'active') then
    raise exception 'The care seeker must confirm the arrival code first';
  end if;

  insert into public.booking_secrets as existing(booking_id, safety_button_id)
  values (p_booking_id, upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)))
  on conflict (booking_id) do update
    set safety_button_id = coalesce(
      existing.safety_button_id,
      excluded.safety_button_id
    )
  returning safety_button_id into v_token;

  return v_token;
end;
$$;

revoke execute on function public.caregiver_safety_button_token(uuid)
  from public, anon;
grant execute on function public.caregiver_safety_button_token(uuid)
  to authenticated;

-- Development/demo helper. The client token remains private; only the signed-in
-- seeker on this booking can advance it, and only after codeVerified.
create or replace function public.simulate_safety_button_scan(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_seeker_id uuid;
  v_status text;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;

  select b.seeker_id, b.status
    into v_seeker_id, v_status
    from public.bookings b
   where b.id = p_booking_id
   for update;

  if not found or v_seeker_id <> v_uid then
    raise exception 'This booking does not belong to this care seeker';
  end if;
  if v_status <> 'codeVerified' then
    raise exception 'Confirm the caregiver code before simulating a scan';
  end if;

  update public.bookings
     set status = 'active',
         payload = jsonb_set(coalesce(payload, '{}'::jsonb), '{status}', '"active"'::jsonb, true),
         updated_at = now()
   where id = p_booking_id;

  return jsonb_build_object('success', true, 'status', 'active');
end;
$$;

revoke execute on function public.simulate_safety_button_scan(uuid)
  from public, anon;
grant execute on function public.simulate_safety_button_scan(uuid)
  to authenticated;
