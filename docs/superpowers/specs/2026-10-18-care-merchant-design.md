# Design Specification: Care-Merchant Application

- **Document Version**: 1.0.0
- **Date**: October 18, 2026
- **Status**: Approved
- **Scope**: Care-Merchant Flutter Application (`apps/care_merchant`)
- **System Requirements Alignment**: `docs/Care-Merchant_SRS_IEEE830.md`, `docs/Care-Flash-Platform_SRS_IEEE830.md`
- **Workflow State Machine Alignment**: `docs/Care-Merchant_Mermaid.md`

---

## 1. Executive Summary & System Goals

`care-merchant` is the dedicated mobile client application for verified student caregivers in the Care-Flash ecosystem. The application coordinates the end-to-end caregiver lifecycle:
1. **Student Onboarding & Verification**: Identity document upload, verification state tracking, and interactive safety training certification.
2. **Availability & Matching**: Real-time availability toggling and receipt of privacy-preserving incoming booking requests.
3. **Transport & Safety Navigation**: Post-acceptance reveal of destination details, Grab ride integration, and pre-session danger cancellation triggers.
4. **Two-Stage Arrival Handover Verification**:
   - Verification of the care seeker's private client code.
   - Dynamic generation and activation of the booking-linked safety button QR/NFC payload, followed by physical button handover and platform confirmation.
5. **In-Session Safety & Monitoring**: Boundary checklist management, real-time session countdown timer, care seeker early-termination compensation handling (50% rule), and hold-to-activate emergency SOS.
6. **Financial Operations & Quality Assurance**: Itemized earnings tracking, bank payout withdrawals, care seeker ratings, and incident reporting with evidence attachments.

---

## 2. Architecture & Layering Strategy

The application adopts **Feature-First Clean Architecture** with **BLoC (Business Logic Component)** for state management. This guarantees deterministic state transitions matching the project's Mermaid state machine and allows 100% testability of business logic independent of UI or network layers.

### 2.1 Directory Structure

```
apps/care_merchant/
├── lib/
│   ├── main.dart                                # Application bootstrapping & MultiRepositoryProvider
│   ├── app.dart                                 # Root MaterialApp, Routing & AppTheme setup
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart                  # Accessible palette, safety badges, emergency red
│   │   │   ├── app_dimensions.dart              # Spacing, border radii, touch target dimensions
│   │   │   └── app_strings.dart                 # Localization keys (EN & ID support)
│   │   ├── errors/
│   │   │   ├── exceptions.dart                  # ServerException, StorageException, VerificationException
│   │   │   └── failures.dart                    # Equatable Failure classes for BLoC states
│   │   ├── network/
│   │   │   └── platform_api_client.dart         # Abstract interface for platform REST & WebSocket APIs
│   │   ├── theme/
│   │   │   └── app_theme.dart                   # Material 3 light & dark theme definitions
│   │   └── utils/
│   │   │   ├── currency_formatter.dart          # Indonesian Rupiah (IDR) formatter
│   │   │   ├── date_time_helper.dart            # Humanized relative time and timer formatters
│   │   │   └── validators.dart                  # Form field & PIN input validation logic
│   ├── data/
│   │   ├── mock/
│   │   │   ├── mock_data.dart                   # Seed data (verified profile, mock requests, rides)
│   │   │   └── mock_platform_api_client.dart    # Full-featured mock simulation engine
│   │   └── repositories/                        # Repository implementations delegating to PlatformApiClient
│   │       ├── auth_repository_impl.dart
│   │       ├── availability_repository_impl.dart
│   │       ├── booking_repository_impl.dart
│   │       ├── session_repository_impl.dart
│   │       └── earnings_repository_impl.dart
│   └── features/
│       ├── auth_onboarding/
│       │   ├── domain/ (entities: CaregiverUser, StudentVerification, SafetyBadge)
│       │   ├── presentation/
│       │   │   ├── bloc/ (AuthBloc, OnboardingCubit)
│       │   │   └── screens/ (LoginScreen, RegisterScreen, VerificationStatusScreen, SafetyModuleScreen)
│       ├── availability/
│       │   ├── domain/ (entities: AvailabilityStatus, CaregiverProfile)
│       │   ├── presentation/
│       │   │   ├── bloc/ (AvailabilityBloc)
│       │   │   └── screens/ (CaregiverHomeScreen, ProfileScreen)
│       ├── matching/
│       │   ├── domain/ (entities: RequestOffer)
│       │   ├── presentation/
│       │   │   ├── bloc/ (MatchingBloc)
│       │   │   └── widgets/ (IncomingOfferDialog, RadialCountdownWidget)
│       ├── ride_transit/
│       │   ├── domain/ (entities: GrabRideInfo, AcceptedTrip)
│       │   ├── presentation/
│       │   │   ├── bloc/ (RideTransitBloc)
│       │   │   └── screens/ (TripTransitScreen, DangerReportDialog)
│       ├── arrival_verification/
│       │   ├── domain/ (entities: VerificationStage, ButtonPayload)
│       │   ├── presentation/
│       │   │   ├── bloc/ (ArrivalVerificationBloc)
│       │   │   └── screens/ (ArrivalVerificationScreen, SafetyButtonQrView)
│       ├── active_session/
│       │   ├── domain/ (entities: ActiveSession, SessionOutcome, BoundaryItem)
│       │   ├── presentation/
│       │   │   ├── bloc/ (ActiveSessionBloc)
│       │   │   └── screens/ (ActiveSessionScreen, HoldToActivateSosButton)
│       ├── post_session/
│       │   ├── domain/ (entities: SeekerRating, IncidentReport)
│       │   ├── presentation/
│       │   │   ├── bloc/ (PostSessionBloc)
│       │   │   └── screens/ (SessionOutcomeSummaryScreen, RateSeekerScreen, IncidentReportScreen)
│       └── earnings/
│           ├── domain/ (entities: EarningsLedger, TransactionRecord, PayoutRequest)
│           ├── presentation/
│           │   ├── bloc/ (EarningsBloc)
│           │   └── screens/ (EarningsDashboardScreen, WithdrawalModal)
└── test/
    ├── unit/                                    # Entities, formatting, repository logic, BLoC tests
    └── widget/                                  # Screen rendering, privacy assertions, stepper validation
```

---

## 3. Data Contracts & Domain Entities

### 3.1 Verification & Profile (`auth_onboarding`, `availability`)
```dart
enum VerificationStatus { pending, approved, rejected }
enum CaregiverGender { male, female }

class CaregiverProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String university;
  final String studentIdNumber;
  final String? studentCardPhotoUrl;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final bool safetyBadgeEarned;
  final CaregiverGender gender;
  final bool isAvailable;
  final double averageRating;
  final int totalCompletedSessions;
}
```

### 3.2 Privacy-Preserving Matching (`matching`)
```dart
class RequestOffer extends Equatable {
  final String requestReference;      // e.g. "CR-2026-9812"
  final String helpType;              // e.g. "Elderly Mobility Support"
  final String? description;          // Seeker notes
  final List<String> boundaryChecklist;
  final int durationMinutes;          // e.g. 60
  final int expectedEarningsIdr;      // IDR 25,000 per 30 minutes -> IDR 50,000
  final DateTime expiresAt;           // 30-second window
  
  // NOTE: Address, GPS coordinates, and private client verification code
  // are STRICTLY excluded from this entity to enforce FR-CM-8 and DC-CM-2.
}
```

### 3.3 Trip Transit & Grab Ride (`ride_transit`)
```dart
enum GrabRideStage { arranging, driverAssigned, inTransit, arrived }

class GrabRideInfo extends Equatable {
  final String rideId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleModel;
  final String driverPhone;
  final int etaMinutes;
  final GrabRideStage stage;
}

class AcceptedTrip extends Equatable {
  final String bookingId;
  final String requestReference;
  final String careSeekerName;
  final String destinationAddress;
  final double latitude;
  final double longitude;
  final int durationMinutes;
  final int payoutIdr;
  final List<String> boundaryChecklist;
  final GrabRideInfo grabRide;
}
```

### 3.4 Arrival & Safety Button Handover (`arrival_verification`)
```dart
enum HandoverStage {
  awaitingClientCodeInput,
  clientCodeVerified,
  generatingSafetyButtonPayload,
  awaitingSeekerButtonScan,
  handoverCompleted
}

class SafetyButtonPayload extends Equatable {
  final String bookingId;
  final String buttonToken;          // Cryptographic token linked to booking
  final String qrDataUri;            // Formatted URI for QR rendering
  final String nfcPayloadString;     // NFC NDEF record payload
  final DateTime issuedAt;
}
```

### 3.5 Active Session & Safety (`active_session`)
```dart
enum SessionOutcomeType {
  normalCompletion,
  careSeekerEarlyEnd,
  caregiverSosTriggered,
  preSessionDangerCancelled
}

class ActiveSession extends Equatable {
  final String sessionId;
  final String bookingId;
  final String careSeekerName;
  final int totalDurationSeconds;
  final int remainingSeconds;
  final List<BoundaryItem> boundaries;
  final bool isPaused;
  final SessionOutcomeType? outcome;
}

class BoundaryItem extends Equatable {
  final String id;
  final String title;
  final bool isAcknowledged;
}
```

### 3.6 Earnings & Ledger (`earnings`)
```dart
class TransactionRecord extends Equatable {
  final String id;
  final String bookingReference;
  final DateTime timestamp;
  final int amountIdr;
  final String description;
  final String status; // "settled", "pending", "withdrawn"
}

class EarningsLedger extends Equatable {
  final int availableBalanceIdr;
  final int pendingBalanceIdr;
  final int lifetimeEarningsIdr;
  final List<TransactionRecord> transactions;
}
```

---

## 4. State Management (BLoC / Cubit Architecture)

Each operational flow is encapsulated in a dedicated BLoC to enforce strict unidirectional data flow:

1. **`AuthBloc`**:
   - `AuthInitial` → `AuthLoading` → `Authenticated(CaregiverProfile)` / `Unauthenticated`
   - Actions: `LoginRequested`, `RegisterRequested`, `LogoutRequested`, `StudentIdSubmitted`, `SafetyModuleCompleted`.
2. **`AvailabilityBloc`**:
   - Manages online/offline toggle with optimistic updates and fallback rollback on network failure.
   - Blocks toggling online if `verificationStatus != approved` or `safetyBadgeEarned == false`.
3. **`MatchingBloc`**:
   - Listens to incoming request offer streams from `PlatformApiClient`.
   - Manages the 30-second countdown ticker. Emits `OfferTimeout` if unaccepted.
   - Handles `AcceptOfferRequested` and `DeclineOfferRequested`. (Declining emits `OfferDeclined` without penalty).
4. **`RideTransitBloc`**:
   - Manages Grab ride progression stream (`driverAssigned` → `inTransit` → `arrived`).
   - Supports `ReportDangerBeforeSessionRequested`: Immediately calls platform danger endpoint, transitions to `BookingCancelledDangerReported`, and notifies support.
5. **`ArrivalVerificationBloc`**:
   - Handles 2-stage verification:
     - Stage 1: `VerifyClientCodeSubmitted(code)`: Validates seeker PIN. If invalid, emits `InvalidClientCodeState` and prevents session start.
     - Stage 2: `ActivateSafetyButtonRequested`: Generates QR/NFC payload, transitions to `AwaitingSeekerScanState`.
     - Automatically receives WebSocket/Mock push when the care seeker scans the button, transitioning to `VerificationCompleteState`.
6. **`ActiveSessionBloc`**:
   - Emits 1-second interval timer updates.
   - Manages boundary checklist acknowledgment items.
   - Handles `MarkWorkCompleted`: Transitions to `SessionCompletedState` (100% earnings awarded).
   - Handles `SeekerEndedEarlyReceived`: Transitions to `EarlyEndCompensationState` (calculates 50% compensation rule: IDR 25k/30m * 50%).
   - Handles `SosEmergencyTriggered`: Dispatches emergency alert to platform support channel and ends session with caregiver compensation protected.
7. **`EarningsBloc`**:
   - Fetches transaction ledger and balance summaries.
   - Processes `WithdrawalRequested(amount, bankName, accountNumber)`.

---

## 5. Mock Simulation Engine (`MockPlatformApiClient`)

To ensure the application can be run, demoed, and thoroughly tested standalone without an external server:
- Implements `PlatformApiClient` interface identically to a production REST/WebSocket client.
- In-memory data store with predefined personas (verified caregiver with badge, pending caregiver, rejected caregiver).
- Simulated async network latency (configurable, defaults to 400ms for realistic UI loading states, 0ms in test harness).
- Interactive event triggers:
  - Button to simulate incoming offer broadcast.
  - Accelerated ride progress simulation.
  - Manual toggle to simulate care seeker scanning the safety button.
  - Simulated care seeker early-termination broadcast.

---

## 6. User Interface & Safety Visual Language

The design implements Material 3 principles customized for high-stress mobile environments:
1. **Safety First**:
   - Distinctive **Verified Safety Badge** (Emerald Green `#10B981`) rendered across home and profile.
   - High-contrast, unambiguous **SOS Trigger**: 2-second hold-to-activate circular progress button with haptic feedback to eliminate false positives while remaining rapidly accessible.
2. **Strict Information Hygiene**:
   - The `IncomingOfferDialog` visually highlights the non-secret reference, help type, boundary rules, and payout, with an explicit shield icon: *"Seeker exact location and client verification code remain private until acceptance."*
3. **Arrival Stepper**:
   - Visual two-step handover guide: Step 1 (Enter 6-digit seeker PIN) and Step 2 (Full-screen high-contrast QR code for the care seeker to scan onto the physical button).
4. **Active Session HUD**:
   - Big, glanceable countdown timer with remaining hours, minutes, and seconds.
   - Interactive boundary checklist cards with checkable items.

---

## 7. Quality Assurance & Test Strategy

### 7.1 Unit Testing Suite
- **Entity & Business Rules**:
  - Test IDR price calculations (IDR 25,000 / 30 mins).
  - Test 50% early termination rule (`duration = 60m` -> quoted IDR 50,000 -> payout IDR 25,000).
  - Test serialization and immutability (`copyWith`, `props`).
- **BLoC Tests (`bloc_test`)**:
  - `MatchingBloc`: Acceptance within window, decline without rating penalty, timeout expiry.
  - `RideTransitBloc`: Grab status advancement, pre-session danger cancellation.
  - `ArrivalVerificationBloc`: Valid code vs invalid code rejection, QR generation, button handshake.
  - `ActiveSessionBloc`: Timer ticker, boundary toggle, SOS emergency flow, early-end handling.

### 7.2 Widget & Interaction Testing Suite
- **Privacy Assertion Test**: Verify that `IncomingOfferDialog` never renders seeker address or client code.
- **Verification Flow Test**: Enter client code, verify transition to QR display, tap simulated seeker confirmation, verify navigation to active session.
- **Active Session HUD Test**: Verify countdown timer ticks and SOS button triggers emergency state after 2-second hold.

---

## 8. Requirements Traceability Matrix

| Requirement | Description | Component / Feature Module |
|---|---|---|
| FR-CM-1 | Caregiver account creation & login | `features/auth_onboarding/` |
| FR-CM-2, 3 | Student ID submission & verification status tracking | `features/auth_onboarding/` |
| FR-CM-4 | Interactive safety module & badge issuance | `features/auth_onboarding/` |
| FR-CM-5, 6 | Gender profile & availability toggle | `features/availability/` |
| FR-CM-7, 8 | Privacy-preserving request offer (hidden location & code) | `features/matching/` |
| FR-CM-9 | Accept/Decline within window with zero rating penalty | `features/matching/` |
| FR-CM-10 | Post-acceptance trip details & Grab ride tracking | `features/ride_transit/` |
| FR-CM-11, 12 | Pre-session danger report & cancellation alerts | `features/ride_transit/` |
| FR-CM-13, 14 | Client verification code validation & rejection handling | `features/arrival_verification/` |
| FR-CM-15, 16 | Safety-button QR/NFC generation & handover handshake | `features/arrival_verification/` |
| FR-CM-17 | Active session boundary checklist & countdown timer | `features/active_session/` |
| FR-CM-18 | Mark work complete & normal session closure | `features/active_session/` |
| FR-CM-19 | Caregiver SOS/Report emergency trigger & compensation | `features/active_session/` |
| FR-CM-20 | Submit incident report with evidence attachments | `features/post_session/` |
| FR-CM-21, 22 | Itemized earnings ledger & payout withdrawal requests | `features/earnings/` |
| FR-CM-23, 24 | Caregiver feedback viewing & rating care seeker | `features/post_session/` |
