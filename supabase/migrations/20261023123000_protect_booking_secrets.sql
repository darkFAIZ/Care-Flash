-- A seeker must not be able to read the code that the caregiver has to tell
-- them. Keep verification secrets separate from the seeker's private address.
create table public.booking_secrets (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  client_code text,
  safety_button_id text
);
alter table public.booking_secrets enable row level security;
revoke all on public.booking_secrets from public, anon, authenticated;
grant select on public.booking_secrets to authenticated;
insert into public.booking_secrets(booking_id, client_code, safety_button_id)
select booking_id, client_code, safety_button_id from public.booking_private
on conflict (booking_id) do nothing;
update public.booking_private set client_code = null, safety_button_id = null;
revoke all on public.booking_private from public, anon, authenticated;
grant select (booking_id, location) on public.booking_private to authenticated;
create policy "Caregivers read verification secrets after accepting"
  on public.booking_secrets for select to authenticated
  using (exists (
    select 1 from public.bookings b where b.id = booking_id
      and b.caregiver_id = (select auth.uid())
      and b.status in ('confirmed','caregiverTravelling','arrived','codeVerified','buttonVerified','active','completed','endedEarly','reported','caregiverSos')
  ));

create or replace function public.care_booking_action(p_booking_id uuid, p_action text, p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_booking public.bookings%rowtype; v_status text; v_payload jsonb;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Request not found'; end if;
  v_status := v_booking.status; v_payload := v_booking.payload;
  if p_action = 'pay' then
    if v_booking.seeker_id <> v_uid or v_status <> 'matched' then raise exception 'Request cannot be paid'; end if;
    v_status := 'paidPending';
    update public.booking_secrets set client_code = lpad((floor(random() * 1000000))::integer::text, 6, '0') where booking_id = p_booking_id;
    v_payload := v_payload || jsonb_build_object('paymentStatus', 'succeeded', 'paymentMethod', p_data->'paymentMethod');
  elsif p_action = 'accept' then
    if v_booking.caregiver_id <> v_uid or v_status <> 'paidPending' then raise exception 'Request is no longer available'; end if;
    v_status := 'confirmed';
  elsif p_action = 'decline' then
    if v_booking.caregiver_id <> v_uid or v_status <> 'paidPending' then raise exception 'Request is no longer available'; end if;
    v_status := 'cancelled';
  elsif p_action in ('startTrip','arrive','verifyCode','verifyButton','complete','cancel','endEarly','report','sos') then
    if v_booking.seeker_id = v_uid then
      if p_action not in ('verifyCode','verifyButton','cancel','endEarly','report') then raise exception 'Not allowed'; end if;
    elsif v_booking.caregiver_id = v_uid then
      if p_action not in ('startTrip','arrive','complete','sos','report') then raise exception 'Not allowed'; end if;
    else raise exception 'Not allowed'; end if;
    if p_action = 'verifyCode' then
      if v_status <> 'arrived' then raise exception 'The caregiver has not arrived yet'; end if;
      if not exists (select 1 from public.booking_secrets where booking_id = p_booking_id and client_code = p_data->>'code') then
        return jsonb_build_object('success', false, 'message', 'That code is incorrect');
      end if;
    end if;
    v_status := case p_action when 'startTrip' then 'caregiverTravelling' when 'arrive' then 'arrived' when 'verifyCode' then 'codeVerified' when 'verifyButton' then 'buttonVerified' when 'complete' then 'completed' when 'cancel' then 'cancelled' when 'endEarly' then 'endedEarly' when 'report' then 'reported' when 'sos' then 'caregiverSos' else v_status end;
  else raise exception 'Unknown booking action'; end if;
  v_payload := v_payload || jsonb_build_object('status', v_status);
  update public.bookings set status = v_status, payload = v_payload, updated_at = now() where id = p_booking_id;
  return jsonb_build_object('success', true, 'status', v_status, 'payload', v_payload);
end $$;
