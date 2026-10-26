# Software Requirements Specification for Care-Merchant

Format: IEEE Std 830-1998  
Version: 1.1 (draft)  
Date: October 16, 2026  
Course: Software Requirements Engineering  
Prepared by: Faiz, Simmon, Vincent

## 1. Introduction

### 1.1 Purpose

This document specifies requirements for Care-Merchant, the caregiver mobile application in the Care-Flash shared platform. The companion care seeker application is Care-Flash. Platform-wide behavior and requirements shared by both apps are specified in [Care-Flash-Platform_SRS_IEEE830.md](./Care-Flash-Platform_SRS_IEEE830.md).

### 1.2 Scope

Care-Merchant enables verified caregivers to complete onboarding, manage availability, receive privacy-protected help requests, accept or decline requests, travel to the care seeker using a Grab ride, verify the care seeker's code, generate/activate the safety-button QR or NFC, conduct a session, report danger, and view earnings and feedback.

Care-Merchant is a Flutter mobile app that communicates with the shared platform backend. It does not provide emergency response directly; it sends reports through the platform.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| Caregiver | Identity-verified person using Care-Merchant to provide help |
| Care seeker | User requesting help through Care-Flash |
| Request reference | Non-secret identifier for an incoming request |
| Client verification code | Booking-specific code the care seeker presents at arrival |
| Safety button | Physical device handed to the care seeker with booking-linked QR/NFC and a physical report button |
| Session | Visit period after client-code and safety-button verification |
| Platform | Shared backend and services used by Care-Flash and Care-Merchant |

### 1.4 References

- IEEE Std 830-1998, Recommended Practice for Software Requirements Specifications
- Care-Flash-Platform_SRS_IEEE830.md
- Care seeker and caregiver user flow diagrams and team notes

### 1.5 Overview

Section 2 describes the product and users. Section 3 lists Care-Merchant requirements. Section 4 records open decisions.

## 2. Overall Description

### 2.1 Product perspective

Care-Merchant is one of two Flutter mobile applications connected to the shared Care-Flash backend. The platform handles matching, payments, booking, Grab coordination, safety-button verification, session state, emergency reports, and data exchange with Care-Flash.

### 2.2 Product functions

- Create an account, submit caregiver identity information, and complete caregiver verification.
- Complete safety training and manage availability.
- Receive request details without care seeker location or private verification code before acceptance.
- Accept or decline requests without rating penalty for declining.
- View Grab pickup and route information after acceptance.
- Verify the care seeker at arrival and hand over the safety button.
- Track the session, mark normal completion, or report a dangerous situation.
- Report a care seeker with evidence during or after a session.
- View earnings, session history, and feedback received in Care-Merchant.

### 2.3 User characteristics

Caregivers are verified caregivers who need clear request details, privacy safeguards, safety controls, and transparent earnings.

### 2.4 Constraints

- The app shall be built with Flutter for mobile.
- Caregiver access to requests depends on verification and platform approval.
- Grab, maps, background-check, payment, and emergency-report integrations are external dependencies.
- The app shall follow applicable Indonesian data-protection requirements.

### 2.5 Assumptions and dependencies

- The caregiver has an internet-connected smartphone and grants necessary location permissions.
- A Grab pickup, backend connection, and physical safety button are available for an accepted booking.

### 2.6 Apportioning of requirements

Requirements are marked P1 for the MVP or P2 for a later release. Priorities should be confirmed by the team.

## 3. Specific Requirements

### 3.1 External interface requirements

#### 3.1.1 User interface

- UI-CM-1 The app shall provide account, onboarding/verification, safety module, profile, availability, incoming request, request response, Grab pickup/route, client-code verification, button QR/NFC generation or activation, active session, completion, incident report, earnings, feedback, and settings screens. (P1)
- UI-CM-2 Before accepting a request, the app shall not display the care seeker's location or private client verification code. (P1)
- UI-CM-3 The app shall display clear request, ride, verification, session, cancellation, incident-report, and earnings statuses. (P1)

#### 3.1.2 Hardware interface

- HI-CM-1 The app shall use available device capabilities to generate or activate a booking-linked QR code or NFC tag for the physical safety button. (P1)
- HI-CM-2 The caregiver app shall provide an SOS/Report action during an active session. (P1)

### 3.2 Functional requirements

#### 3.2.1 Caregiver account and onboarding

- FR-CM-1 The app shall let a caregiver create an account and log in. (P1)
- FR-CM-2 The app shall let a caregiver submit residential identity and required verification information. (P1)
- FR-CM-3 The app shall show verification status and explain rejection reasons; where resubmission is allowed, the app shall provide a resubmission path. (P1)
- FR-CM-4 The app shall provide the required safety module and show the safety badge after successful completion. (P1)
- FR-CM-5 The app shall let the caregiver record their gender for the care seeker's matching filter. (P1)
- FR-CM-6 The app shall let the caregiver set and update availability. (P1)

#### 3.2.2 Request and travel

- FR-CM-7 The app shall notify a caregiver of an eligible incoming request and show its request reference, help type, optional description, boundary checklist, and expected caregiver payment. (P1)
- FR-CM-8 Before the caregiver accepts, the app shall not show the care seeker's location or private client verification code. (P1)
- FR-CM-9 The app shall let the caregiver accept or decline a request within the platform response window. Declining shall not reduce the caregiver rating. (P1)
- FR-CM-10 After acceptance, the app shall show the care seeker's pickup/destination details and Grab pickup/ride status needed for the trip. (P1)
- FR-CM-11 The app shall let the caregiver report a safety concern about the care seeker before the session starts. The platform shall cancel the booking and notify support. (P1)
- FR-CM-12 The app shall notify the caregiver if the booking is cancelled or reassigned. (P1)

#### 3.2.3 Arrival and safety-button handover

- FR-CM-13 On arrival, the app shall let the caregiver enter or verify the client code presented by the care seeker. (P1)
- FR-CM-14 If the client code is invalid, the app shall display the cancellation/report status returned by the platform and shall not allow the session to start. (P1)
- FR-CM-15 After successful client-code verification, the app shall generate or activate the QR code or NFC tag linked to the booking and guide the caregiver to hand the physical safety button to the care seeker. (P1)
- FR-CM-16 The app shall show that the session may start only after the care seeker scans/reads and the platform verifies the button identifier. (P1)

#### 3.2.4 Session, reporting, and earnings

- FR-CM-17 During an active session, the app shall show the boundary checklist and session timer. (P1)
- FR-CM-18 The app shall let the caregiver mark the work as complete and notify the platform and care seeker. (P1)
- FR-CM-19 The app shall provide an SOS/Report action. When activated, the platform shall end the session, report the incident to support and the emergency response channel, and apply the configured caregiver compensation policy. (P1)
- FR-CM-20 The app shall let the caregiver report the care seeker and submit supporting evidence during or after the session. (P1)
- FR-CM-21 The app shall show the caregiver their earnings, transaction status, and session history. (P1)
- FR-CM-22 The app shall let the caregiver request withdrawal of available earnings according to the configured payout schedule. (P1)
- FR-CM-23 The app shall show caregiver feedback received through the platform. (P1)
- FR-CM-24 The app should let the caregiver rate the care seeker after a session. (P1)

### 3.3 Performance requirements

- PR-CM-1 The app should receive request and safety notifications within 5 seconds when a network connection is available.
- PR-CM-2 App screens should load within 3 seconds on a normal mobile connection.

### 3.4 Design constraints

- DC-CM-1 The app shall communicate with the backend over an encrypted connection.
- DC-CM-2 The app shall not expose care seeker location or the private verification code before booking acceptance.
- DC-CM-3 Identity documents shall be transmitted and stored only through authorized platform services.

### 3.5 Software attributes

| Attribute | Requirement |
|---|---|
| Security | Caregiver identity documents and incident evidence shall be protected from unauthorized access |
| Privacy | Care seeker location shall be disclosed only after acceptance and for the accepted trip/session |
| Reliability | An SOS/report shall not require the chat or Grab integration to remain available |
| Portability | Supported Android/iOS versions are TBD |

### 3.6 Other requirements

- OR-CM-1 The app should support English and Bahasa Indonesia if enabled by the platform release.

## 4. Open Issues

| No. | Issue | Related requirement |
|---|---|---|
| 1 | Caregiver request response timeout and offer sequencing | FR-CM-9 |
| 2 | Exact Grab booking integration and ride cancellation/rebooking behavior | FR-CM-10, FR-CM-12 |
| 3 | Exact mechanism for verifying the code and generating/activating button QR/NFC | FR-CM-13, FR-CM-15 |
| 4 | Compensation and payment settlement after caregiver SOS or pre-session danger report | FR-CM-11, FR-CM-19 |
| 5 | Evidence types, size limits, review and retention policy | FR-CM-20 |
| 6 | Payout schedule and supported payout methods | FR-CM-22 |
| 7 | Team names and supported mobile OS versions | Metadata, PR-CM |
