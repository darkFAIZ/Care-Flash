create or replace function public.create_care_request(p_payload jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_seeker uuid := auth.uid(); v_id uuid; v_caregiver record; v_data jsonb;
  v_filter text := coalesce(p_payload->>'genderFilter','both');
  v_duration integer := (p_payload->>'durationMinutes')::integer;
  v_base integer; v_fee integer; v_grab integer; v_reference text; v_button_id text;
  v_status text := 'matched';
begin
  if v_seeker is null then raise exception 'Sign in required'; end if;
  if not exists (select 1 from public.profiles p where p.id=v_seeker and p.role='seeker') then raise exception 'A care seeker account is required'; end if;
  if v_duration not in (30,45,60,90,120) then raise exception 'Invalid visit duration'; end if;
  if v_filter not in ('male','female','both') then raise exception 'Invalid caregiver filter'; end if;
  select p.id,p.full_name,cp.gender,cp.rating,cp.review_count,cp.availability into v_caregiver
    from public.profiles p join public.caregiver_profiles cp on cp.user_id=p.id
   where p.role='caregiver' and cp.verification_status='approved' and cp.safety_module_completed and cp.availability='available'
     and (v_filter='both' or cp.gender=v_filter)
     and not exists(select 1 from public.bookings b where b.caregiver_id=p.id and b.status in ('paidPending','confirmed','caregiverTravelling','arrived','codeVerified','buttonVerified','active'))
   order by cp.rating desc,cp.review_count desc,cp.created_at limit 1 for update of cp skip locked;
  if not found then v_status := 'noMatch'; end if;
  v_base:=round(25000*v_duration/30.0); v_fee:=round(v_base*0.05);
  v_grab:=case v_duration when 30 then 30000 when 45 then 35000 when 60 then 40000 when 90 then 50000 else 60000 end;
  v_reference:='CF-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)); v_id:=gen_random_uuid(); v_button_id:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_data:=(p_payload-'location'-'clientCode'-'safetyButtonId')||jsonb_build_object('id',v_id,'requestReference',v_reference,
    'caregiver',case when v_status='matched' then jsonb_build_object('id',v_caregiver.id,'name',v_caregiver.full_name,'gender',v_caregiver.gender,'rating',v_caregiver.rating,'reviewCount',v_caregiver.review_count,'identityVerified',true,'safetyBadge',true,'availability',v_caregiver.availability) else null end,
    'price',jsonb_build_object('caregiverPrice',v_base,'platformFee',v_fee,'grabFare',v_grab),'status',v_status,'createdAt',now(),'updates','[]'::jsonb);
  insert into public.bookings(id,seeker_id,caregiver_id,status,payload) values(v_id,v_seeker,case when v_status='matched' then v_caregiver.id else null end,v_status,v_data);
  insert into public.booking_private(booking_id,location) values(v_id,p_payload->'location');
  insert into public.booking_secrets(booking_id,safety_button_id) values(v_id,v_button_id);
  return v_id;
end $$;

create or replace function public.care_booking_action(p_booking_id uuid,p_action text,p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid:=auth.uid(); v_booking public.bookings%rowtype; v_status text; v_payload jsonb;
begin
  if v_uid is null then raise exception 'Sign in required'; end if;
  select * into v_booking from public.bookings where id=p_booking_id for update;
  if not found then raise exception 'Request not found'; end if;
  v_status:=v_booking.status; v_payload:=v_booking.payload;
  if p_action='pay' then
    if v_booking.seeker_id<>v_uid or v_status<>'matched' then raise exception 'Request cannot be paid'; end if;
    v_status:='paidPending';
    update public.booking_secrets set client_code=lpad((floor(random()*1000000))::integer::text,6,'0') where booking_id=p_booking_id;
    v_payload:=v_payload||jsonb_build_object('paymentStatus','succeeded','paymentMethod',p_data->'paymentMethod');
  elsif p_action in ('accept','decline') then
    if v_booking.caregiver_id<>v_uid or v_status<>'paidPending' then raise exception 'Request is no longer available'; end if;
    v_status:=case p_action when 'accept' then 'confirmed' else 'cancelled' end;
  elsif p_action in ('startTrip','arrive','verifyCode','verifyButton','complete','cancel','endEarly','report','sos') then
    if v_booking.seeker_id=v_uid then
      if p_action not in ('verifyCode','verifyButton','cancel','endEarly','report') then raise exception 'Not allowed'; end if;
    elsif v_booking.caregiver_id=v_uid then
      if p_action not in ('startTrip','arrive','complete','sos','report') then raise exception 'Not allowed'; end if;
    else raise exception 'Not allowed'; end if;
    if p_action='startTrip' and v_status<>'confirmed' then raise exception 'Accept the request before starting the trip'; end if;
    if p_action='arrive' and v_status<>'caregiverTravelling' then raise exception 'Start the trip before marking arrival'; end if;
    if p_action='verifyCode' then
      if v_status<>'arrived' then raise exception 'The caregiver has not arrived yet'; end if;
      if not exists(select 1 from public.booking_secrets where booking_id=p_booking_id and client_code=p_data->>'code') then return jsonb_build_object('success',false,'message','That code is incorrect'); end if;
    end if;
    if p_action='verifyButton' then
      if v_status<>'codeVerified' then raise exception 'Confirm the caregiver code first'; end if;
      if not exists(select 1 from public.booking_secrets where booking_id=p_booking_id and safety_button_id=p_data->>'payload') then return jsonb_build_object('success',false,'message','That safety button does not match this booking'); end if;
    end if;
    if p_action='complete' and v_status<>'active' then raise exception 'The session is not active'; end if;
    if p_action='endEarly' and v_status<>'active' then raise exception 'The session is not active'; end if;
    if p_action='cancel' and v_status not in ('noMatch','matched','paidPending') then raise exception 'This request cannot be cancelled now'; end if;
    v_status:=case p_action when 'startTrip' then 'caregiverTravelling' when 'arrive' then 'arrived' when 'verifyCode' then 'codeVerified' when 'verifyButton' then 'active' when 'complete' then 'completed' when 'cancel' then 'cancelled' when 'endEarly' then 'endedEarly' when 'report' then 'reported' when 'sos' then 'caregiverSos' else v_status end;
  else raise exception 'Unknown booking action'; end if;
  v_payload:=v_payload||jsonb_build_object('status',v_status);
  update public.bookings set status=v_status,payload=v_payload,updated_at=now() where id=p_booking_id;
  return jsonb_build_object('success',true,'status',v_status,'payload',v_payload);
end $$;
