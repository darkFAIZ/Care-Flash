---
version: 1
slug: "apps-care-flash-lib-features-home-home-tab-dart"
primary_target: "apps/care_flash/lib/features/home/home_tab.dart"
related_targets: ["apps/care_merchant/lib/features/home/home_tab.dart"]
---

Scope: Care-Flash and Care-Merchant home and booking entry surfaces
Mode: Operate
Audience and job: Care seekers start or track requests; caregivers review and respond to new requests or active visits.
Action and proof: Make the next booking action obvious, with real request status, reference, caregiver, timing, and session details.
Constraints: Preserve all existing workflows, Supabase and mock behavior, English and Indonesian, adaptive Flutter layouts, Material/native navigation, and light/dark appearance.

## Direction contract
THESIS: Each care action reads like one calm, trustworthy visit record, refusing the generic pile of equal dashboard cards.
OWN-WORLD: Warm record-stock surfaces, deep puskesmas green ink, generous Plus Jakarta Sans headings, small precise field labels, restrained gold and terracotta stamps, lightly ruled booking details, and a shared next-step treatment across both apps.
STORY: The visitor understands who needs care, what stage the visit is in, and what single action comes next; caregivers can respond without hunting through secondary information.
FIRST VIEWPORT: On Care-Flash, a personal welcome leads to one prominent start-request action, followed by the active booking record with reference, caregiver, status, visit time, and next step. On Care-Merchant, caregiver availability and onboarding lead directly to the incoming request or active visit record and its response action.
FORM: The Clinic Visit Card, Impeccable's grounded pick from the direction roll; adapt its ticket-and-record hierarchy to both role-specific home screens. seed:5c91775272fb1e2e
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
