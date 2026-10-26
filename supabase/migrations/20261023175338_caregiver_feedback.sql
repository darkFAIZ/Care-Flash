-- Let each caregiver see feedback for their own completed bookings, while
-- users can always see the ratings they personally submitted.
grant select on public.care_ratings to authenticated;
create policy "Participants can read their care ratings"
  on public.care_ratings for select to authenticated
  using (
    author_id = (select auth.uid())
    or exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and b.caregiver_id = (select auth.uid())
        and kind = 'caregiver_ratings'
    )
  );

create or replace function public.refresh_caregiver_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_booking_id uuid := coalesce(new.booking_id, old.booking_id);
  v_caregiver_id uuid;
begin
  select caregiver_id into v_caregiver_id
    from public.bookings where id = v_booking_id;
  if v_caregiver_id is not null then
    update public.caregiver_profiles cp
       set review_count = coalesce(r.rating_count, 0),
           rating = coalesce(r.average_rating, 0)
      from (
        select count(*)::integer as rating_count,
               round(avg((payload->>'stars')::numeric), 1) as average_rating
          from public.care_ratings cr
          join public.bookings b on b.id = cr.booking_id
         where cr.kind = 'caregiver_ratings' and b.caregiver_id = v_caregiver_id
      ) r
     where cp.user_id = v_caregiver_id;
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
revoke execute on function public.refresh_caregiver_rating() from public, anon, authenticated;

create trigger care_ratings_refresh_caregiver_rating
  after insert or update or delete on public.care_ratings
  for each row execute function public.refresh_caregiver_rating();

do $$ begin
  alter publication supabase_realtime add table public.care_ratings;
exception when duplicate_object then null;
end $$;
