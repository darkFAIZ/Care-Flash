# Care-Flash

Care-Flash is a two-sided care service platform with two separate Flutter apps that share one backend:

- **Care-Flash** - care seeker application.
- **Care-Merchant** - caregiver application.

## Running the prototype

There are two ways to run the prototype:

- **Offline (mock platform).** Self-contained. There is no real backend, payment, Grab or emergency
  service: everything external is simulated inside `packages/care_core` so it can be swapped for a
  real API later. In this mode the two apps do **not** talk to each other: they are separate
  processes with no shared memory, so each one *simulates* the other side. Run them as two
  independent walkthroughs, not as one shared booking.
- **Connected (live demo).** The two apps share one backend and genuinely talk to each other: a
  booking created in Care-Flash appears live in Care-Merchant and the caregiver's actions flow back.
  This is the mode to show that the two sides are really connected.

Every screen with a **bug icon** (debug builds only) opens **Demo Controls**, which fires the
simulated events for the other side. In connected mode the other side is a real app, so those
controls become no-ops.

Both apps support **English** and **Bahasa Indonesia**. Open **Profile -> Language** to switch; the
choice is saved on the device and applies immediately. English is the default.

### Offline (two independent walkthroughs)

```bash
# Terminal 1 - care seeker app
cd apps/care_flash
flutter run -d edge          # or -d chrome, or a connected device

# Terminal 2 - caregiver app
cd apps/care_merchant
flutter run -d edge
```

Signing in: any valid-looking email plus a password of 6+ characters logs you straight into a
ready, verified demo account. Use **Create account** instead if you want to walk through the
caregiver onboarding (KTP, safety module).

### Connected live demo (backend + two Edge windows)

Start the shared backend once, then launch each app pointing at it. On the web each app is shown
inside a phone frame so the mobile aspect ratio is preserved.

```bash
# Terminal 1 - the shared backend (run from the repository root)
dart run packages/care_backend/bin/server.dart --port 8080 --data data/backend.json

# Terminal 2 - care seeker (Care-Flash)
cd apps/care_flash
flutter run -d edge --dart-define=BACKEND_URL=ws://localhost:8080

# Terminal 3 - caregiver (Care-Merchant)
cd apps/care_merchant
flutter run -d edge --dart-define=BACKEND_URL=ws://localhost:8080
```

**Create account** in both apps the first time (the caregiver must finish onboarding and set
themselves **Available**). Without `--dart-define` the apps fall back to the offline mock above.

Authentication is real enough for a two-app demo: the backend stores accounts, keeps passwords as
salted SHA-256 hashes (never plain text), and issues a session token on sign-in. Each app saves its
token locally, so reopening the app signs you back in without typing the password again. Signing out
revokes the token on the server. With `--data`, accounts and tokens are written to that JSON file and
reloaded on the next start; **bookings are still in memory only**, so a backend restart clears any
active request. This is a demo-grade implementation, not production auth (no email delivery, rate
limiting or password reset). To start fresh, delete the data file. If the backend restarts while the
apps are open, they reconnect automatically and restore the same session; a request that was in
flight is not kept (bookings are in memory).

**Connected script (one booking, two windows):**

1. Care-Merchant: **Create account** → KTP → simulated approval → safety module → set
   **Available**. Care-Flash: **Create account**.
2. Care-Flash: request a visit (help type → checklist → location/time/duration → gender filter →
   price) and **Pay**. The client code appears.
3. Care-Merchant: the request lands in the **Requests** tab → **Accept** → **Start trip** →
   **Mark arrived**.
4. Care-Flash shows *arrived*; read the client code and enter it in Care-Merchant. Verify the
   **safety button** in Care-Flash to start the session in both windows.
5. Care-Merchant: **Mark work complete** → the earnings appear. Care-Flash: rate the caregiver →
   it shows up in the caregiver's **Feedback** tab.


## Demo script

A click-by-click walkthrough for each app. Each is self-contained and uses auto-advance or Demo
Controls to simulate the other side.

### A. Care-Flash (care seeker) - request a visit, pay, run a session, rate

1. Launch. Splash → login. Sign in (any email + 6-char password).
2. Home → tap the request CTA. Pick a **help type** and add an optional description → Next.
3. **Boundary checklist**: allowed tasks, disallowed tasks, off-limit rooms → Next.
4. **Location, date and time, duration** → Next.
5. **Caregiver gender filter** (default Both) → Next.
6. **Price estimate** (caregiver price + 5% fee + Grab fare = total) → submit. Matching status appears.
7. The caregiver auto-accepts after a few seconds. On the **matched** screen you see the caregiver
   profile and the itemized price → Continue.
8. **Payment**: pick GoPay / DANA / OVO / Mastercard → Pay. Handle the success path.
9. The private **client verification code** is shown (only you and the caregiver ever see it).
10. **Booking status** screen: watch acceptance, Grab pickup and arrival notifications.
11. At arrival, tap **Simulate scan** (QR or NFC) - the session starts only after both the client
    code and the safety button are confirmed.
12. **Active session**: a timer and the work checklist. Two separate actions:
    - **End Early** - ends the session, pays the caregiver the 50% early-end compensation, and
      refunds you the unused part.
    - **Report** (red, also triggered by the physical button) - ends the session, notifies support
      and the emergency channel, and **refunds the full amount**.
13. After the session, **rate the caregiver** and leave a visit note, then rate the **Care-Flash app**
    separately. Submit.
14. Open the **Activity** tab: the booking is listed with its payment / refund status.
15. **Profile** tab: **Edit profile** changes your display name and adds or removes a profile photo,
    and **Appearance** switches the theme mode (System / Light / Dark) and the accent
    colour (Brand / Ocean / Sunset / Forest / Plum). Both choices are saved on the device.
16. **Profile -> Language**: switch between English and Bahasa Indonesia. The UI updates
    immediately and the choice is saved on the device.

### B. Care-Merchant (caregiver) - accept a request, run a session, get paid, give feedback

1. Launch. Splash → login. Sign in (any email + 6-char password) to land on a verified demo
   caregiver. (Use **Create account** to walk through onboarding: KTP → simulated approval →
   safety module → badge.)
2. **Requests** tab: an incoming request arrives after a few seconds (or tap Demo Controls →
   *Simulate incoming request*). You see the reference, help type, description, boundary checklist
   and expected pay - never the care seeker's location or client code. **Accept** or **Decline**
   within the 60-second window (declining has no rating penalty).
3. After accepting, the **booking** screen shows pickup, destination and Grab status.
4. **Start trip** → **Mark arrived**.
5. Enter the **client code** the care seeker shows you. A wrong code cancels the booking and
   notifies support.
6. **Button handover**: the booking-linked QR / NFC is ready. When the care seeker scans it, the
   session starts. (Use Demo Controls → *Simulate care seeker button scan*.)
7. **Session**: timer + work checklist. You can **Mark work complete**, **Report the care seeker**
   (with evidence), or raise an **SOS** (ends the session and applies the compensation policy).
8. **Mark work complete** - your service earnings are released to your balance.
9. **Earnings** tab: available balance, pending, total earned, paid out, and the transaction
   history. **Request withdrawal** once you are above the minimum.
10. **Feedback** tab: a **Rate the care seeker** prompt for the visit, plus the feedback the care
    seeker left about you (it arrives a few seconds after a session ends).
11. **Profile** tab: your rating and availability setting, plus **Edit profile** (display name and photo) and
    **Appearance** (theme mode and accent colour, saved on the device).
12. **Profile -> Language**: switch between English and Bahasa Indonesia; the choice is saved on
    the device.

## Software requirements

- [Care-Flash care seeker SRS](./docs/Care-Flash_SRS_IEEE830.md)
- [Care-Merchant caregiver SRS](./docs/Care-Merchant_SRS_IEEE830.md)
- [Shared platform SRS](./docs/Care-Flash-Platform_SRS_IEEE830.md)
- [File-by-file presentation script](./docs/Project_Presentation_Script.md)

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
   - Add caregiver KTP/background verification, safety training, gender profile, and availability.
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

