# Software Requirements Specification for Care-Flash Platform

Format: IEEE Std 830-1998  
Version: 1.1 (draft)  
Date: October 16, 2026  
Course: Software Requirements Engineering  
Prepared by: Faiz, Simmon, Vincent

## 1. Introduction

### 1.1 Purpose

This document specifies the shared backend, services, integrations, and cross-application requirements for the Care-Flash platform. The platform is used by two separate Flutter mobile apps:

- [Care-Flash](./Care-Flash_SRS_IEEE830.md): care seeker app.
- [Care-Merchant](./Care-Merchant_SRS_IEEE830.md): caregiver app.

### 1.2 Scope

The platform receives requests from Care-Flash, matches them to eligible caregivers using Care-Merchant, manages payments and Grab rides, coordinates client and safety-button verification, tracks sessions and reports, and provides ratings, feedback, and earnings information to both apps.

The platform coordinates reports to support and configured emergency-response services but does not itself provide police, medical, or emergency response.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| Care seeker | User requesting help through Care-Flash |
| Caregiver | Verified student providing help through Care-Merchant |
| Booking | A paid care request accepted by a caregiver |
| Client verification code | Booking-specific secret presented by the care seeker at arrival |
| Request reference | Non-secret request identifier visible to the caregiver before acceptance |
| Safety button | Physical device handed to the care seeker, with booking-linked QR/NFC and physical Report activation |
| Session | Visit period after the care seeker and safety button are verified |
| Platform service fee | Fee equal to 5 percent of the caregiver service price |

### 1.4 References

- IEEE Std 830-1998, Recommended Practice for Software Requirements Specifications
- Care-Flash_SRS_IEEE830.md
- Care-Merchant_SRS_IEEE830.md
- Care seeker and caregiver user flow diagrams and team notes

### 1.5 Overview

Section 2 describes the platform. Section 3 lists shared platform requirements. Section 4 records open decisions that affect one or both apps.

## 2. Overall Description

### 2.1 Product perspective

The platform is the shared backend for Care-Flash and Care-Merchant. It provides account and caregiver verification, matching, booking state, pricing, payment, Grab coordination, verification-code and safety-button checks, session tracking, emergency reporting, and app data synchronization.

### 2.2 Product functions

- Authenticate both apps and enforce role-appropriate access.
- Verify caregivers and maintain availability/profile data.
- Match care requests with nearby available caregivers by the care seeker's gender filter.
- Calculate and present itemized price information and collect payment.
- Keep the care seeker's location and client verification code private until appropriate.
- Coordinate caregiver request acceptance and Grab transport.
- Verify client identity and the booking-linked safety button before session start.
- Manage normal completion, early end, incident reports, refunds, and compensation.
- Synchronize ratings, caregiver feedback, app feedback, earnings, and notifications.
- Maintain audit records for bookings, verification, payments, sessions, and incidents.

### 2.3 User characteristics

The platform serves care seekers and caregivers through their respective apps and provides administrative access to authorized support staff.

### 2.4 Constraints

- Care-Flash and Care-Merchant are separate Flutter applications using one shared platform.
- The platform shall follow applicable Indonesian data-protection requirements.
- The platform depends on external payment, Grab, maps/location, background-check, and emergency-response services.
- The safety button shall support booking-linked QR and NFC.

### 2.5 Assumptions and dependencies

- Users have internet-connected smartphones. Care seekers can scan QR codes; NFC depends on device support.
- External providers remain available and permit the required integrations.
- Support and emergency-response routing requires a configured receiving channel.

### 2.6 Apportioning of requirements

Requirements are marked P1 for the MVP or P2 for a later release. Priorities should be confirmed by the team.

## 3. Specific Requirements

### 3.1 External interface requirements

#### 3.1.1 Application interfaces

- API-1 The platform shall provide authenticated interfaces for Care-Flash and Care-Merchant over an encrypted connection. (P1)
- API-2 The platform shall return authoritative booking, payment, matching, Grab, verification, session, report, and earnings status to the relevant app. (P1)
- API-3 The platform shall restrict each user and app role to authorized records and actions. (P1)

#### 3.1.2 External service and hardware interfaces

- SI-1 The platform shall integrate with a payment provider to collect care seeker payments and return payment/settlement status. (P1)
- SI-2 The platform shall integrate with Grab or an authorized ride service for caregiver pickup and travel to the care seeker. (P1)
- SI-3 The platform shall use maps/location services for proximity matching and accepted trip navigation. (P1)
- SI-4 The platform shall use an identity/background-check service to verify caregivers. (P1)
- SI-5 The platform shall send emergency reports to a configured police/emergency-response channel and support staff. (P1)
- HI-1 The platform shall issue and verify booking-linked safety-button QR/NFC identifiers. (P1)

#### 3.1.3 Communications interface

- CI-1 The platform shall send push notifications or equivalent app updates for request offers, acceptance, ride status, arrival, verification, session changes, reports, payment, cancellation, and feedback. (P1)

### 3.2 Functional requirements

#### 3.2.1 Accounts, profiles, and matching

- FR-P-1 The platform shall maintain separate care seeker and caregiver roles and authorize requests accordingly. (P1)
- FR-P-2 The platform shall unlock caregiver request access only after required student identity/background checks and safety training are complete. (P1)
- FR-P-3 The platform shall maintain caregiver gender and use it only to apply the care seeker's selected male, female, or both filter. (P1)
- FR-P-4 The platform shall match requests to nearby available verified caregivers whose gender matches the selected filter. (P1)
- FR-P-5 If no matching caregiver is available, the platform shall return a no-match result and support filter changes or cancellation. (P1)

#### 3.2.2 Booking, privacy, and pricing

- FR-P-6 The platform shall store each request's help type, optional description, boundary checklist, location, date/time, duration, and gender filter. (P1)
- FR-P-7 Before caregiver acceptance, the platform shall send Care-Merchant a non-secret request reference and request details, but shall not expose the care seeker's location or client verification code. (P1)
- FR-P-8 After caregiver acceptance, the platform shall disclose the care seeker's destination only as required to arrange and complete the accepted trip/session. (P1)
- FR-P-9 The platform shall calculate caregiver service price at IDR 25,000 per 30 minutes. (P1)
- FR-P-10 The platform shall calculate the platform service fee as 5 percent of caregiver service price and obtain the applicable estimated Grab fare separately. (P1)
- FR-P-11 Before payment, the platform shall return the itemized caregiver service price, platform service fee, Grab fare, and total to Care-Flash. A 1-hour visit with a Grab fare of IDR 9,000 shall total IDR 61,500: IDR 50,000 + IDR 2,500 + IDR 9,000. (P1)
- FR-P-12 After successful payment, the platform shall create a paid pending request; after a caregiver accepts, it shall set the booking to confirmed and notify both apps. (P1)
- FR-P-13 The platform shall offer a declined or timed-out request to another eligible caregiver. If no caregiver accepts, the platform shall cancel the booking and initiate the configured care seeker refund. (P1)
- FR-P-14 After caregiver acceptance, the platform shall arrange the Grab pickup and synchronize ride status with both apps. (P1)
- FR-P-15 After successful payment, the platform shall generate a booking-specific client verification code and expose it only to the care seeker until presented at arrival. The caregiver shall verify the presented code through Care-Merchant without seeing it before acceptance. (P1)

#### 3.2.3 Arrival verification and session management

- FR-P-16 The platform shall validate the client verification code submitted by the caregiver against the accepted booking. (P1)
- FR-P-17 After valid client-code verification, the platform shall authorize generation/activation of a booking-linked safety-button QR/NFC identifier. (P1)
- FR-P-18 The platform shall start a session only after valid client-code verification, valid safety-button QR/NFC verification by Care-Flash, and confirmation that the button has been handed to the care seeker. (P1)
- FR-P-19 If either verification fails, the platform shall automatically record the failed verification, notify support, cancel the booking, and block session start. (P1)
- FR-P-20 The platform shall maintain session state and make the boundary checklist and timer state available to Care-Merchant. (P1)
- FR-P-21 On normal completion, the platform shall close the session, release caregiver service earnings, settle applicable platform and ride amounts, and make the completed booking available for ratings. (P1)
- FR-P-22 When the care seeker ends the session early, the platform shall close the session and pay caregiver compensation according to the confirmed early-end policy. Current proposed amount: 50 percent of the quoted total booking price. (P1)

#### 3.2.4 Reports, refunds, and feedback

- FR-P-23 When the care seeker reports an incident during the session or presses the physical safety button, the platform shall end the session, send a report to support and the configured emergency-response channel, and initiate a full refund of the amount charged to the care seeker. (P1)
- FR-P-24 When the caregiver submits an SOS during a session, the platform shall end the session, send a report to support and the configured emergency-response channel, and apply the configured caregiver compensation policy. (P1)
- FR-P-25 The platform shall let care seekers and caregivers submit incident reports with evidence during or after a session. (P1)
- FR-P-26 Before session start, if the caregiver reports that the care seeker may be dangerous, the platform shall cancel the booking and notify support. (P1)
- FR-P-27 The platform shall make caregiver feedback visible to the caregiver in Care-Merchant and support care seeker feedback about caregivers. (P1)
- FR-P-28 The platform shall store app feedback separately from caregiver ratings and feedback. (P1)
- FR-P-29 The platform shall maintain caregiver earnings and expose available balance, history, and payout status to Care-Merchant. (P1)
- FR-P-30 The platform shall record booking, payment, ride, verification, session, report, evidence-access, and settlement events for authorized audit. (P1)

### 3.3 Performance requirements

- PR-P-1 The platform should return a match or no-match result within 60 seconds of a request.
- PR-P-2 The platform should deliver emergency notifications within 5 seconds of report activation when external connectivity is available.
- PR-P-3 The platform should support at least 500 concurrent active sessions.
- PR-P-4 The platform should respond to normal app requests within 3 seconds, excluding third-party provider delays.

### 3.4 Design constraints

- DC-P-1 All app-to-platform traffic shall use encrypted transport.
- DC-P-2 Payment-card details shall be handled by the payment provider and shall not be stored by the platform.
- DC-P-3 Location, identity documents, gender data, and incident evidence shall be accessible only for documented platform purposes and authorized roles.

### 3.5 Software attributes

| Attribute | Requirement |
|---|---|
| Availability | The platform should be available 99.5 percent of the time |
| Reliability | Report delivery shall not depend on video, chat, or Grab availability |
| Security | User data, verification codes, evidence, and payment status shall be protected from unauthorized access |
| Privacy | Care seeker location and client verification code shall remain hidden from the caregiver until the appropriate booking stage |
| Maintainability | Shared business rules shall be implemented once in the platform and exposed consistently to both apps |

### 3.6 Other requirements

- OR-P-1 The platform should support English and Bahasa Indonesia.

## 4. Open Issues

| No. | Issue | Related requirement |
|---|---|---|
| 1 | Default gender filter and caregiver response timeout/offer sequencing | FR-P-3–FR-P-5, FR-P-13 |
| 2 | Exact Grab integration, fare changes, ride cancellation, and responsibility for ride costs on failed bookings | FR-P-10–FR-P-14 |
| 3 | Refund processing time and treatment of platform fee/Grab fare on cancellation, failed verification, or report | FR-P-13, FR-P-19, FR-P-23 |
| 4 | Confirm whether early-end compensation is 50 percent of total price or caregiver service price | FR-P-22 |
| 5 | Caregiver compensation and settlement after SOS; pre-session danger report payment treatment | FR-P-24, FR-P-26 |
| 6 | Emergency-response integration, evidence types, retention, and support review process | SI-5, FR-P-23–FR-P-26 |
| 7 | Exact button hardware protocol and fallback when NFC or network access is unavailable | HI-1, FR-P-17–FR-P-19 |
| 8 | Team names, supported mobile OS versions, and payout schedule | Metadata, OR-P, app SRS |
