-- Make the profile tables inaccessible to the implicit PUBLIC role. The
-- authenticated grants are added explicitly by the initial schema migration.
revoke all on public.profiles from public;
revoke all on public.caregiver_profiles from public;
