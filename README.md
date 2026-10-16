# Care-Flash

Care-Flash is a two-sided care service platform with two separate Flutter apps that share one backend:

- **Care-Flash** — care seeker application.
- **Care-Merchant** — caregiver application.

## Software requirements

- [Care-Flash care seeker SRS](./docs/Care-Flash_SRS_IEEE830.md)
- [Care-Merchant caregiver SRS](./docs/Care-Merchant_SRS_IEEE830.md)
- [Shared platform SRS](./docs/Care-Flash-Platform_SRS_IEEE830.md)

## Mermaid diagrams

- [Care-Flash care seeker flow](./docs/Care-Flash_Mermaid.md)
- [Care-Merchant caregiver flow](./docs/Care-Merchant_Mermaid.md)
- [Shared platform architecture and lifecycle](./docs/Care-Flash-Platform_Mermaid.md)

## Development Roadmap

The roadmap below follows the requirements in the SRS documents. Phase order is proposed; delivery dates and final scope are TBD.

1. **Project foundation**
   - Set up the Flutter monorepo with Melos.
   - Create the Care-Flash and Care-Merchant app shells and shared package.
   - Agree on supported platforms, development standards, and shared API contracts.
2. **Accounts and caregiver onboarding**
   - Implement account creation and login for both apps.
   - Add caregiver student-ID/background verification, safety training, gender profile, and availability.
3. **Care request and matching**
   - Build the Care-Flash request flow: help type, optional description, boundary checklist, location, schedule, and caregiver gender filter.
   - Implement nearby available-caregiver matching and caregiver request accept/decline in Care-Merchant.
   - Show caregiver profile and itemized price estimates.
4. **Booking, payment, and transport**
   - Integrate a payment provider and calculate caregiver service price, 5% platform fee, and estimated Grab fare.
   - Generate a private client verification code after successful payment.
   - Integrate Grab pickup and provide booking and ride status to both apps.
5. **Arrival verification and session safety**
   - Verify the care seeker's code in Care-Merchant.
   - Generate or activate the booking-linked safety-button QR/NFC and verify it in Care-Flash.
   - Implement session start, boundary checklist, timer, End Early, Report, and caregiver SOS flows.
6. **Completion, incidents, and feedback**
   - Implement normal session completion, caregiver earnings, and payout history.
   - Add reports with evidence, support/emergency notifications, refund and compensation handling.
   - Add caregiver ratings/feedback, caregiver feedback visibility, and separate app feedback.
7. **Validation and release preparation**
   - Test both apps and shared platform flows together, including payment, ride, verification failures, cancellations, and emergencies.
   - Review privacy, security, accessibility, and performance requirements.
   - Resolve the open decisions recorded in the SRS documents before release.


## Planned Repository Structure

We will use a **Monorepo architecture** managed with **Melos** to share code (like models, API clients, or UI components) between both apps in the future.

```text
├── apps/
│   ├── care-flash/          # Flutter app for Care Seekers (To be developed)
│   └── care-merchant/       # Flutter app for Caregivers (To be developed)
├── packages/
│   └── care_flash_core/     # Shared Dart/Flutter code (Models, Shared APIs)
├── docs/                    # IEEE 830 SRS & Mermaid Documentation
├── melos.yaml               # Monorepo management configuration
└── README.md                # Main entry point
```

## Setup & Prerequisites (For Developers)

To prepare your local environment for development, ensure you have the following installed:

1. **Flutter SDK**: Recommended version `^3.24.x` or latest stable.
2. **Melos**: Install globally via pub to manage the monorepo:
   ```bash
   dart pub global activate melos
   ```


### Initializing the Project

Once the workspace structures are generated, running the project will be as simple as:

```bash
# 1. Clone the repository
git clone https://github.com
cd Care-Flash

# 2. Bootstrap all apps and packages simultaneously (Runs pub get everywhere)
melos bootstrap
```
