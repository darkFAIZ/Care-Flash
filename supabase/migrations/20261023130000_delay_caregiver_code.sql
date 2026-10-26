drop policy if exists "Caregivers read verification secrets after accepting" on public.booking_secrets;
create policy "Caregivers read verification secrets at arrival"
  on public.booking_secrets for select to authenticated
  using (exists (
    select 1 from public.bookings b where b.id = booking_id
      and b.caregiver_id = (select auth.uid())
      and b.status in ('arrived','codeVerified','buttonVerified','active','completed','endedEarly','reported','caregiverSos')
  ));
