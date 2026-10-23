-- Shared booking/request lifecycle for Care-Flash and Care-Merchant.
-- Personal location and the one-time verification code live in a separate
-- table so caregiver request discovery cannot expose them before acceptance.

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  seeker_id uuid not null references public.profiles(id) on delete restrict,
  caregiver_id uuid references public.profiles(id) on delete restrict,
  status text not null check (status in (
    'draft', 'matching', 'noMatch', 'matched', 'paidPending', 'confirmed',
    'caregiverTravelling', 'arrived', 'codeVerified', 'buttonVerified',
    'active', 'completed', 'endedEarly', 'reported', 'caregiverSos', 'cancelled'
  )),
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.booking_private (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  location jsonb not null,
  client_code text,
  safety_button_id text
);

alter table public.bookings enable row level security;
alter table public.booking_private enable row level security;
revoke all on public.bookings, public.booking_private from public, anon, authenticated;
grant select on public.bookings to authenticated;
grant select on public.booking_private to authenticated;

create policy "Seekers read their bookings"
  on public.bookings for select to authenticated
  using (seeker_id = (select auth.uid()));
create policy "Assigned caregivers read their bookings"
  on public.bookings for select to authenticated
  using (caregiver_id = (select auth.uid()));

create policy "Seekers read private booking details"
  on public.booking_private for select to authenticated
  using (exists (
    select 1 from public.bookings b
    where b.id = booking_id and b.seeker_id = (select auth.uid())
  ));
create policy "Caregivers read private details after confirmation"
  on public.booking_private for select to authenticated
  using (exists (
    select 1 from public.bookings b
    where b.id = booking_id
      and b.caregiver_id = (select auth.uid())
      and b.status in (
        'confirmed', 'caregiverTravelling', 'arrived', 'codeVerified',
        'buttonVerified', 'active', 'completed', 'endedEarly', 'reported', 'caregiverSos'
      )
  ));

create index bookings_seeker_open_idx on public.bookings (seeker_id, created_at desc);
create index bookings_caregiver_status_idx on public.bookings (caregiver_id, status, created_at desc);

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
begin
  if v_seeker is null then raise exception 'Sign in required'; end if;
  if not exists (select 1 from public.profiles p where p.id = v_seeker and p.role = 'seeker') then
    raise exception 'A care seeker account is required';
  end if;
  if v_duration not in (30, 45, 60, 90, 120) then raise exception 'Invalid visit duration'; end if;
  if v_filter not in ('male', 'female', 'both') then raise exception 'Invalid caregiver filter'; end if;

  select p.id, p.full_name, cp.gender, cp.rating, cp.review_count,
         cp.verification_status, cp.safety_module_completed, cp.availability
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
   limit 1
   for update of cp skip locked;
  if not found then raise exception 'No verified caregiver is available'; end if;

  v_base := round(25000 * v_duration / 30.0);
  v_fee := round(v_base * 0.05);
  v_grab := case v_duration when 30 then 30000 when 45 then 35000 when 60 then 40000 when 90 then 50000 else 60000 end;
  v_reference := 'CF-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_id := gen_random_uuid();
  v_data := p_payload - 'location' - 'clientCode' - 'safetyButtonId';
  v_data := v_data || jsonb_build_object(
    'id', v_id, 'requestReference', v_reference,
    'caregiver', jsonb_build_object(
      'id', v_caregiver.id, 'name', v_caregiver.full_name, 'gender', v_caregiver.gender,
      'rating', v_caregiver.rating, 'reviewCount', v_caregiver.review_count,
      'identityVerified', true, 'safetyBadge', true, 'availability', v_caregiver.availability
    ),
    'price', jsonb_build_object('caregiverPrice', v_base, 'platformFee', v_fee, 'grabFare', v_grab),
    'status', 'matched', 'createdAt', now(), 'updates', '[]'::jsonb
  );
  insert into public.bookings(id, seeker_id, caregiver_id, status, payload)
  values (v_id, v_seeker, v_caregiver.id, 'matched', v_data);
  insert into public.booking_private(booking_id, location)
  values (v_id, p_payload->'location');
  return v_id;
end;
$$;

create or replace function public.care_booking_action(p_booking_id uuid, p_action text, p_data jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_booking public.bookings%rowtype;
  v_status text;
  v_payload jsonb;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Request not found'; end if;
  v_status := v_booking.status;
  v_payload := v_booking.payload;

  if p_action = 'pay' then
    if v_booking.seeker_id <> v_uid or v_status <> 'matched' then raise exception 'Request cannot be paid'; end if;
    v_status := 'paidPending';
    update public.booking_private set client_code = lpad((floor(random() * 1000000))::integer::text, 6, '0') where booking_id = p_booking_id;
    v_payload := v_payload || jsonb_build_object('paymentStatus', 'succeeded', 'paymentMethod', p_data->'paymentMethod');
  elsif p_action = 'accept' then
    if v_booking.caregiver_id <> v_uid or v_status <> 'paidPending' then raise exception 'Request is no longer available'; end if;
    v_status := 'confirmed';
  elsif p_action = 'decline' then
    if v_booking.caregiver_id <> v_uid or v_status <> 'paidPending' then raise exception 'Request is no longer available'; end if;
    v_status := 'cancelled';
  elsif p_action in ('startTrip', 'arrive', 'verifyCode', 'verifyButton', 'complete', 'cancel', 'endEarly', 'report', 'sos') then
    if v_booking.seeker_id = v_uid then
      if p_action not in ('verifyCode', 'verifyButton', 'cancel', 'endEarly', 'report') then raise exception 'Not allowed'; end if;
    elsif v_booking.caregiver_id = v_uid then
      if p_action not in ('startTrip', 'arrive', 'complete', 'sos', 'report') then raise exception 'Not allowed'; end if;
    else raise exception 'Not allowed'; end if;
    v_status := case p_action
      when 'startTrip' then 'caregiverTravelling'
      when 'arrive' then 'arrived'
      when 'verifyCode' then 'codeVerified'
      when 'verifyButton' then 'buttonVerified'
      when 'complete' then 'completed'
      when 'cancel' then 'cancelled'
      when 'endEarly' then 'endedEarly'
      when 'report' then 'reported'
      when 'sos' then 'caregiverSos'
      else v_status end;
    if p_action = 'verifyCode' and not exists (
      select 1 from public.booking_private where booking_id = p_booking_id and client_code = p_data->>'code'
    ) then return jsonb_build_object('success', false, 'message', 'That code is incorrect'); end if;
  else raise exception 'Unknown booking action'; end if;

  v_payload := v_payload || jsonb_build_object('status', v_status);
  update public.bookings set status = v_status, payload = v_payload, updated_at = now() where id = p_booking_id;
  return jsonb_build_object('success', true, 'status', v_status, 'payload', v_payload);
end;
$$;

revoke execute on function public.create_care_request(jsonb) from public, anon;
revoke execute on function public.care_booking_action(uuid, text, jsonb) from public, anon;
grant execute on function public.create_care_request(jsonb) to authenticated;
grant execute on function public.care_booking_action(uuid, text, jsonb) to authenticated;

create trigger bookings_set_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

do $$ begin
  alter publication supabase_realtime add table public.bookings;
exception when duplicate_object then null;
end $$;
