# Software Requirements Specification for Care-Flash

Format: IEEE Std 830-1998  
Version: 1.1 (draft)  
Date: October 16, 2026  
Course: Software Requirements Engineering  
Prepared by: Faiz, Simmon, Vincent

## 1. Introduction

### 1.1 Purpose

This document specifies requirements for Care-Flash, the care seeker mobile application in the Care-Flash shared platform. The companion caregiver application is Care-Merchant. Platform-wide behavior and requirements shared by both apps are specified in [Care-Flash-Platform_SRS_IEEE830.md](./Care-Flash-Platform_SRS_IEEE830.md).

### 1.2 Scope

Care-Flash enables a care seeker to request help from a nearby verified caregiver, set visit boundaries, select a caregiver gender preference, review the matched caregiver and price, pay, verify the visit, and manage safety and feedback during and after the session.

Care-Flash is a Flutter mobile app that communicates with the shared platform backend. It is not the caregiver app and does not directly control Grab or emergency services.

The system does not provide medical treatment, diagnosis, or emergency medical services. A person unable to use the app or complete the required verification should seek professional assistance.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| Care seeker | User requesting help through Care-Flash |
| Caregiver | Verified student providing the requested service through Care-Merchant |
| Boundary checklist | Tasks the care seeker allows or does not allow during the visit |
| Client verification code | Booking-specific code presented by the care seeker to the caregiver at arrival |
| Safety button | Physical device handed to the care seeker, with a booking-linked QR code/NFC tag and physical report button |
| Session | Visit period after the client code and safety button have both been verified |
| Platform | Shared backend and services used by Care-Flash and Care-Merchant |

### 1.4 References

- IEEE Std 830-1998, Recommended Practice for Software Requirements Specifications
- Care-Flash-Platform_SRS_IEEE830.md
- Care seeker and caregiver user flow diagrams and team notes

### 1.5 Overview

Section 2 describes the product and its users. Section 3 lists Care-Flash requirements. Section 4 records open decisions.

## 2. Overall Description

### 2.1 Product perspective

Care-Flash is one of two Flutter mobile applications connected to the shared Care-Flash backend. The platform performs matching, payment, booking, Grab coordination, session verification, emergency reporting, and data exchange with Care-Merchant. See the platform SRS for shared behavior and interfaces.

### 2.2 Product functions

- Create an account, log in, and manage settings.
- Create a help request with type, optional description, boundary checklist, location, date/time, duration, and caregiver gender preference.
- View the matched caregiver profile and itemized estimated price.
- Select a payment method, pay, and receive a client verification code.
- Verify the handed-over safety button by QR scan or NFC.
- End a session early or report an incident using separate actions.
- Rate and provide feedback about the caregiver and separately provide feedback about the app.

### 2.3 User characteristics

Care seekers are adults who need a straightforward, calm experience and have access to a smartphone, internet, and location services.

### 2.4 Constraints

- The app shall be built with Flutter for mobile.
- The app shall follow applicable Indonesian data-protection requirements.
- Payment methods depend on the payment provider configured for the platform.
- QR scanning is required; NFC availability depends on the device.

### 2.5 Assumptions and dependencies

- The user has an internet-connected smartphone and grants necessary location and camera permissions.
- A matched caregiver, Grab ride, payment provider, backend, and safety-button hardware are available for the booking.

### 2.6 Apportioning of requirements

Requirements are marked P1 for the MVP or P2 for a later release. Priorities should be confirmed by the team.

## 3. Specific Requirements

### 3.1 External interface requirements

#### 3.1.1 User interface

- UI-CS-1 The app shall provide account, home, help request, help type/optional description, boundary checklist, location and schedule, caregiver gender preference, matching status, caregiver profile, price breakdown, payment, verification code, QR/NFC scan, active session, completion, ratings/feedback, app feedback, and settings screens. (P1)
- UI-CS-2 During an active session, the app shall provide separate **Report** and **End Early** actions. (P1)
- UI-CS-3 The app shall display confirmation for important actions and clear status when a request, payment, verification, or report succeeds or fails. (P1)

#### 3.1.2 Hardware interface

- HI-CS-1 The app shall use the device camera to scan the safety button QR code and shall support reading its NFC tag when the device supports NFC. (P1)
- HI-CS-2 Pressing the physical safety button handed to the care seeker shall activate the Report action; it shall not activate End Early. (P1)

### 3.2 Functional requirements

#### 3.2.1 Account and settings

- FR-CS-1 The app shall let a care seeker create an account and log in. (P1)
- FR-CS-2 The app shall provide help and support, privacy/policy information, and logout. (P1)
- FR-CS-3 The app should allow the care seeker to select a supported app language. (P2)

#### 3.2.2 Request creation and matching

- FR-CS-4 When the care seeker taps **Need Help**, the app shall collect a help type and an optional description. (P1)
- FR-CS-5 The app shall let the care seeker set allowed and disallowed tasks in a boundary checklist. (P1)
- FR-CS-6 The app shall let the care seeker provide the visit location, date/time, and duration of 30 minutes, 45 minutes, 1 hour, 1.5 hours, or 2 hours. (P1)
- FR-CS-7 The app shall let the care seeker filter caregivers by male, female, or both. (P1)
- FR-CS-8 The app shall show a preliminary estimated price using the selected duration, location, and estimated Grab fare. (P1)
- FR-CS-9 The app shall show matching status and shall display a no-match message if no caregiver meets the request criteria. The care seeker shall be able to change the gender filter or cancel. (P1)
- FR-CS-10 The app shall show the matched caregiver's profile and rating, along with the caregiver service price, 5% platform service fee, estimated Grab fare, and total before payment. (P1)

#### 3.2.3 Payment and arrival verification

- FR-CS-11 The app shall let the care seeker select a supported payment method and pay the displayed total. (P1)
- FR-CS-12 After successful payment, the app shall display the booking-specific client verification code for the care seeker to present to the caregiver at arrival. (P1)
- FR-CS-13 The app shall let the care seeker scan the QR code or read the NFC tag on the physical safety button handed over by the caregiver. (P1)
- FR-CS-14 The app shall display session-start confirmation only after the platform confirms both client-code verification by the caregiver and booking-linked button verification. (P1)
- FR-CS-15 If either identity or button verification fails, the app shall show that the booking was cancelled and reported to platform support. (P1)

#### 3.2.4 Session, safety, and feedback

- FR-CS-16 During a session, the app shall provide a distinct **End Early** action that ends the session and triggers caregiver compensation according to the platform policy. (P1)
- FR-CS-17 During a session, the app shall provide a distinct **Report** action. A report, including activation of the physical safety button, shall end the session, notify platform support and the emergency response channel, and trigger the defined payment return to the care seeker. (P1)
- FR-CS-18 The app shall let the care seeker submit an incident description and supporting evidence during or after a session. (P1)
- FR-CS-19 After a session, the app shall let the care seeker rate and provide feedback about the caregiver. (P1)
- FR-CS-20 The app shall provide a separate way for the care seeker to give feedback about the Care-Flash app. (P1)
- FR-CS-21 The app shall display booking status, arrival, session, payment, cancellation, and report notifications received from the platform. (P1)

### 3.3 Performance requirements

- PR-CS-1 The app should display matching results or a no-match message within 60 seconds of search initiation.
- PR-CS-2 The app should submit an emergency report within 5 seconds of activation when a network connection is available.
- PR-CS-3 App screens should load within 3 seconds on a normal mobile connection.

### 3.4 Design constraints

- DC-CS-1 The app shall communicate with the backend over an encrypted connection.
- DC-CS-2 The app shall not store payment-card details; payment data shall be handled by the configured payment provider.
- DC-CS-3 The app shall request camera, NFC, and location permissions only when needed and explain their use.

### 3.5 Software attributes

| Attribute | Requirement |
|---|---|
| Usability | A first-time care seeker should be able to submit a request in under 3 minutes, excluding payment-provider delays |
| Privacy | The care seeker's location and incident evidence shall be shared only for authorized booking, support, and emergency-response purposes |
| Reliability | Report and End Early actions shall remain distinct and have clear status feedback |
| Portability | Supported Android/iOS versions are TBD |

### 3.6 Other requirements

- OR-CS-1 The app shall support English and Bahasa Indonesia if enabled by the platform release.

## 4. Open Issues

| No. | Issue | Related requirement |
|---|---|---|
| 1 | Default gender-filter value | FR-CS-7 |
| 2 | Exact payment methods and how Grab fare changes after the estimate | FR-CS-8, FR-CS-10, FR-CS-11 |
| 3 | Refund/settlement details when a report is filed or verification fails | FR-CS-15, FR-CS-17 |
| 4 | Incident evidence types, size limits, and retention period | FR-CS-18 |
| 5 | Team names and supported mobile OS versions | Metadata, PR-CS |
