# Care-Merchant Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the production-grade Care-Merchant Flutter app following Feature-First Clean Architecture and BLoC state management.

**Architecture:** Feature-First Clean Architecture (Domain, Data, Presentation layers). Unidirectional data flow via BLoCs. Mock-driven development for standalone testing.

**Tech Stack:** Flutter, BLoC/Cubit, Equatable, MockTail (for tests).

**Spec:** `docs/superpowers/specs/2026-10-18-care-merchant-design.md`

## Global Constraints

- Currency: Indonesian Rupiah (IDR) via `Intl` package.
- Base Rate: IDR 25,000 per 30 minutes.
- Early Termination: 50% compensation rule applies.
- Privacy: Seeker location and code hidden before acceptance.
- Offer Expiry: 30-second countdown for matching.
- Verification: Safety badge required for availability.

## Review Focus

- **Verification Lock**: Online toggle MUST be disabled if `verificationStatus != approved` or `safetyBadgeEarned == false`.
- **Privacy Leak**: `RequestOffer` entity and `IncomingOfferDialog` must never contain or show GPS/Code fields before acceptance.
- **Handover Sequence**: `ActiveSession` cannot start unless `ArrivalVerificationBloc` confirms both Stage 1 (PIN) and Stage 2 (QR/NFC Scan).
- **SOS Reliability**: `SosEmergencyTriggered` must be accessible within 2 seconds via hold-to-activate on the active session HUD.
- **Math Accuracy**: 50% early end compensation must round correctly to nearest IDR for short durations.

---

### Task 1: Core Scaffolding & Theme

**Files:**
- Create: `apps/care_merchant/lib/core/constants/app_colors.dart`
- Create: `apps/care_merchant/lib/core/theme/app_theme.dart`
- Create: `apps/care_merchant/lib/core/utils/currency_formatter.dart`
- Create: `apps/care_merchant/lib/core/utils/validators.dart`

**Interfaces:**
- Produces: `AppTheme.light`, `AppTheme.dark`, `CurrencyFormatter.toIdr(int amount)`, `Validators.validatePin(String? value)`

- [ ] **Step 1: Write tests for CurrencyFormatter and Validators**
- [ ] **Step 2: Implement `CurrencyFormatter` using `intl` for IDR**
- [ ] **Step 3: Implement Material 3 `AppTheme` with Emerald Green (#10B981) safety accents**
- [ ] **Step 4: Verify UI-CM-1 baseline rendering**
- [ ] **Step 5: Commit**

### Task 2: Mock API Client & Data Seeds

**Files:**
- Create: `apps/care_merchant/lib/data/mock/mock_data.dart`
- Create: `apps/care_merchant/lib/core/network/platform_api_client.dart`
- Create: `apps/care_merchant/lib/data/mock/mock_platform_api_client.dart`

**Interfaces:**
- Produces: `PlatformApiClient` (Abstract), `MockPlatformApiClient` (Singleton)

- [ ] **Step 1: Define `PlatformApiClient` interface matching spec section 4/5**
- [ ] **Step 2: Implement `MockPlatformApiClient` with simulated 400ms latency**
- [ ] **Step 3: Add `verifiedCaregiver` and `pendingCaregiver` seed constants**
- [ ] **Step 4: Verify mock client returns seed data in unit test**
- [ ] **Step 5: Commit**

### Task 3: Auth & Onboarding Flow

**Files:**
- Create: `apps/care_merchant/lib/features/auth_onboarding/domain/entities/caregiver_user.dart`
- Create: `apps/care_merchant/lib/features/auth_onboarding/presentation/bloc/auth_bloc.dart`
- Create: `apps/care_merchant/lib/features/auth_onboarding/presentation/screens/verification_status_screen.dart`

**Interfaces:**
- Consumes: `MockPlatformApiClient`
- Produces: `AuthBloc` (States: `Authenticated`, `Unauthenticated`, `NeedsVerification`)

- [ ] **Step 1: Write `AuthBloc` tests for Login -> Verification Pending -> Approved transitions**
- [ ] **Step 2: Implement `AuthBloc` and `CaregiverProfile` entity**
- [ ] **Step 3: Build `VerificationStatusScreen` showing "Safety Badge" requirement**
- [ ] **Step 4: Verify "LoginRequested" leads to correct verification state**
- [ ] **Step 5: Commit**

### Task 4: Availability & Home Dashboard

**Files:**
- Create: `apps/care_merchant/lib/features/availability/presentation/bloc/availability_bloc.dart`
- Create: `apps/care_merchant/lib/features/availability/presentation/screens/caregiver_home_screen.dart`

**Interfaces:**
- Consumes: `AuthBloc.state.profile`
- Produces: `AvailabilityBloc` (Events: `ToggleAvailability`)

- [ ] **Step 1: Write test: Toggle fails if `safetyBadgeEarned` is false**
- [ ] **Step 2: Implement `AvailabilityBloc` with optimistic UI update**
- [ ] **Step 3: Build `CaregiverHomeScreen` with Emerald Green verified badge**
- [ ] **Step 4: Verify toggle state persists via mock client**
- [ ] **Step 5: Commit**

### Task 5: Privacy-Preserving Matching

**Files:**
- Create: `apps/care_merchant/lib/features/matching/domain/entities/request_offer.dart`
- Create: `apps/care_merchant/lib/features/matching/presentation/bloc/matching_bloc.dart`
- Create: `apps/care_merchant/lib/features/matching/presentation/widgets/incoming_offer_dialog.dart`

**Interfaces:**
- Consumes: `PlatformApiClient.requestStream`
- Produces: `MatchingBloc` (States: `OfferReceived`, `OfferAccepted`)

- [ ] **Step 1: Write test: `RequestOffer` JSON mapping must fail if "address" or "code" is present**
- [ ] **Step 2: Implement `MatchingBloc` with 30-second Ticker**
- [ ] **Step 3: Build `IncomingOfferDialog` (Shield icon + masked location warning)**
- [ ] **Step 4: Verify `OfferTimeout` triggers after 30s**
- [ ] **Step 5: Commit**

### Task 6: Arrival & 2-Stage Handover

**Files:**
- Create: `apps/care_merchant/lib/features/arrival_verification/presentation/bloc/arrival_verification_bloc.dart`
- Create: `apps/care_merchant/lib/features/arrival_verification/presentation/screens/arrival_verification_screen.dart`

**Interfaces:**
- Consumes: `BookingRepository`
- Produces: `ArrivalVerificationBloc` (Stages: `awaitingClientCodeInput`, `awaitingSeekerButtonScan`)

- [ ] **Step 1: Write test: `VerifyClientCodeSubmitted` transitions to `Stage 2` only on success**
- [ ] **Step 2: Implement Stage 1 (PIN Entry) logic**
- [ ] **Step 3: Implement Stage 2 (QR/NFC Payload) generation logic**
- [ ] **Step 4: Build `SafetyButtonQrView` with high-contrast Material 3 design**
- [ ] **Step 5: Commit**

### Task 7: Active Session & SOS

**Files:**
- Create: `apps/care_merchant/lib/features/active_session/presentation/bloc/active_session_bloc.dart`
- Create: `apps/care_merchant/lib/features/active_session/presentation/screens/active_session_screen.dart`
- Create: `apps/care_merchant/lib/features/active_session/presentation/widgets/hold_to_activate_sos_button.dart`

**Interfaces:**
- Consumes: `SessionRepository`
- Produces: `ActiveSessionBloc` (Ticker, `SosTriggered`, `EarlyEndReceived`)

- [ ] **Step 1: Write test: `SosEmergencyTriggered` ends session with `caregiverSosTriggered` outcome**
- [ ] **Step 2: Implement Countdown Ticker (1-second intervals)**
- [ ] **Step 3: Implement 50% early-end compensation math**
- [ ] **Step 4: Build `HoldToActivateSosButton` (2-second circular progress delay)**
- [ ] **Step 5: Verify SOS trigger dispatches alert in test**
- [ ] **Step 6: Commit**

### Task 8: Earnings Dashboard

**Files:**
- Create: `apps/care_merchant/lib/features/earnings/domain/entities/earnings_ledger.dart`
- Create: `apps/care_merchant/lib/features/earnings/presentation/bloc/earnings_bloc.dart`
- Create: `apps/care_merchant/lib/features/earnings/presentation/screens/earnings_dashboard_screen.dart`

**Interfaces:**
- Consumes: `EarningsRepository`
- Produces: `EarningsBloc` (States: `EarningsLoaded`, `WithdrawalSuccess`)

- [ ] **Step 1: Write tests for Transaction History fetching**
- [ ] **Step 2: Implement `EarningsLedger` and `TransactionRecord` entities**
- [ ] **Step 3: Build `EarningsDashboardScreen` with list of settled transactions**
- [ ] **Step 4: Verify Withdrawal request updates balance in mock**
- [ ] **Step 5: Commit**
