# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

- Care seekers use Care-Flash to request and manage a short visit with a caregiver.
- Caregivers use Care-Merchant to receive and manage care requests and sessions.

## Product Purpose

Care-Flash and Care-Merchant are two Flutter apps for the two sides of a care service. In connected mode, a shared Supabase backend carries booking and session updates between the apps.

## Positioning

The two role-specific apps are connected through a shared booking lifecycle, allowing actions in one app to appear in the other in connected mode.

## Operating Context

The apps run as separate Flutter clients on supported targets. They can use a shared Supabase project for a live flow or a local mock for independent demonstrations.

## Capabilities and Constraints

- Care seekers can create and follow care requests, participate in a session, and rate a caregiver and the app afterward.
- Caregivers can receive and manage requests, progress sessions, and view feedback.
- Preserve existing authentication, booking, safety, session, feedback, and profile workflows during visual changes.
- English and Indonesian are supported.
- Connected mode uses Supabase Auth, Postgres, and Realtime. Offline mock mode is a separate demonstration path and does not synchronize between the two apps.
- External payment and emergency services are simulated in the prototype.

## Evidence on Hand

- The repository contains the Care-Flash and Care-Merchant Flutter apps, shared domain and UI packages, Supabase migrations, and product requirements in `docs/`.
- The repository does not establish a market-leading claim, customer testimonials, or external performance benchmarks.

## Product Principles

- Keep seeker and caregiver tasks clear in their role-specific apps.
- Preserve the shared booking lifecycle across both apps.
- Make important request, session, safety, and feedback states understandable.
- Keep the connected demo and offline mock behaviors distinct.
- Support the product's English and Indonesian audiences.
