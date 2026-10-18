/// Domain enums shared by Care-Flash (care seeker) and Care-Merchant (caregiver).
///
/// Requirement ids refer to the SRS documents in `docs/`. Keep these values in
/// sync with those documents; the SRS is the source of truth.
library;

/// Types of help a care seeker can request. (FR-CS-4)
enum HelpType {
  takeCare('Take care', 'General assistance and companionship'),
  dropMedicine('Drop medicine', 'Pick up or deliver medicine'),
  feelUnsafe('Feel unsafe', 'Presence and safety support'),
  emotionalSupport('Emotional support', 'Company and a calm presence');

  const HelpType(this.label, this.description);

  final String label;
  final String description;
}

/// A caregiver's gender. Used only for the care seeker's matching filter. (FR-P-3)
enum Gender {
  male('Male'),
  female('Female');

  const Gender(this.label);

  final String label;
}

/// The care seeker's caregiver gender preference. (FR-CS-7)
///
/// Default is [GenderFilter.both] until the team confirms otherwise (SRS §4).
enum GenderFilter {
  male('Male'),
  female('Female'),
  both('Both');

  const GenderFilter(this.label);

  final String label;

  /// Whether a caregiver of [gender] matches this filter. (FR-P-4)
  bool matches(Gender gender) => switch (this) {
        GenderFilter.male => gender == Gender.male,
        GenderFilter.female => gender == Gender.female,
        GenderFilter.both => true,
      };
}

/// Supported visit durations. (FR-CS-6)
enum VisitDuration {
  thirty(30),
  fortyFive(45),
  sixty(60),
  ninety(90),
  oneHundredTwenty(120);

  const VisitDuration(this.minutes);

  final int minutes;

  String get label => switch (this) {
        VisitDuration.thirty => '30 minutes',
        VisitDuration.fortyFive => '45 minutes',
        VisitDuration.sixty => '1 hour',
        VisitDuration.ninety => '1.5 hours',
        VisitDuration.oneHundredTwenty => '2 hours',
      };
}

/// Lifecycle of a booking.
///
/// The names follow the suggested states in AGENTS.md §6. [noMatch] is added so
/// the no-match screen (FR-CS-9) can be retried without ending the booking.
enum BookingStatus {
  draft('Draft'),
  matching('Finding a caregiver'),
  noMatch('No caregiver found'),
  matched('Caregiver found'),
  paidPending('Waiting for caregiver to accept'),
  confirmed('Caregiver confirmed'),
  caregiverTravelling('Caregiver on the way'),
  arrived('Caregiver arrived'),
  codeVerified('Client code verified'),
  buttonVerified('Safety button verified'),
  active('Session in progress'),
  completed('Completed'),
  endedEarly('Ended early'),
  reported('Reported'),
  caregiverSos('Caregiver SOS'),
  cancelled('Cancelled');

  const BookingStatus(this.label);

  final String label;

  /// True while the booking is still being arranged or is in progress.
  bool get isOpen => switch (this) {
        BookingStatus.completed ||
        BookingStatus.endedEarly ||
        BookingStatus.reported ||
        BookingStatus.caregiverSos ||
        BookingStatus.cancelled =>
          false,
        _ => true,
      };

  /// True once the session has started. (FR-CS-14)
  bool get isSessionStarted =>
      this == BookingStatus.active ||
      this == BookingStatus.completed ||
      this == BookingStatus.endedEarly;

  /// True once the booking can no longer change.
  bool get isFinished => !isOpen;
}

/// Why a booking was cancelled. (FR-CS-15, FR-P-13, FR-P-19, FR-P-26)
enum CancellationReason {
  noMatch('No caregiver available'),
  timeout('No caregiver accepted in time'),
  failedVerification('Verification failed'),
  preSessionDanger('Safety concern before the session'),
  userCancelled('Cancelled by you');

  const CancellationReason(this.label);

  final String label;
}

/// Supported mock payment methods. (FR-CS-11, AGENTS.md §5)
///
/// Card details are never stored by the app (DC-CS-2); [PaymentMethod] only
/// keeps a display label.
enum PaymentMethodType {
  gopay('GoPay'),
  dana('DANA'),
  ovo('OVO'),
  mastercard('Mastercard');

  const PaymentMethodType(this.label);

  final String label;
}

/// Outcome of a payment attempt. (FR-CS-11)
///
/// [partiallyRefunded] is used when a session ends early: the caregiver is paid
/// the early-end compensation and the care seeker gets the unused part back.
/// (FR-CS-16, FR-P-22)
enum PaymentStatus {
  pending,
  succeeded,
  failed,
  refunded,
  partiallyRefunded;

  String get label => switch (this) {
        PaymentStatus.pending => 'Payment pending',
        PaymentStatus.succeeded => 'Paid',
        PaymentStatus.failed => 'Payment failed',
        PaymentStatus.refunded => 'Refunded',
        PaymentStatus.partiallyRefunded => 'Partly refunded',
      };
}

/// How the physical safety button is verified. (FR-CS-13, HI-CS-1)
enum ButtonVerificationMethod {
  qr,
  nfc,
}

/// Caregiver onboarding/verification status. (FR-CM-3)
enum VerificationStatus {
  notSubmitted('Not submitted'),
  pending('Under review'),
  approved('Verified'),
  rejected('Rejected');

  const VerificationStatus(this.label);

  final String label;
}

/// Whether a caregiver is currently accepting requests. (FR-CM-6)
enum CaregiverAvailability {
  available('Available'),
  unavailable('Unavailable');

  const CaregiverAvailability(this.label);

  final String label;
}

/// The room a care seeker marks as off limits. (team sketch / AGENTS.md §6)
enum OffLimitRoom {
  bedroom('Bedroom'),
  studyRoom('Study room'),
  other('Other');

  const OffLimitRoom(this.label);

  final String label;
}

/// Kind of evidence attached to an incident report.
///
/// TODO(team): evidence types, size limits and retention are undecided
/// (FR-CS-18, SRS §4).
enum EvidenceKind {
  photo('Photo'),
  video('Video'),
  note('Note');

  const EvidenceKind(this.label);

  final String label;
}

/// How a session ended, used for reporting, refunds and settlement.
enum SessionOutcome {
  completed('Completed'),
  endedEarly('Ended early'),
  careSeekerReported('Reported by care seeker'),
  caregiverSos('Caregiver SOS');

  const SessionOutcome(this.label);

  final String label;
}

/// Why a caregiver earned money on a booking. (FR-CM-21, FR-P-21, FR-P-22,
/// FR-P-24)
enum EarningKind {
  session('Session earnings'),
  earlyEndCompensation('Early-end compensation'),
  sosCompensation('SOS compensation');

  const EarningKind(this.label);

  final String label;
}

/// Status of a caregiver withdrawal request. (FR-CM-22, FR-P-29)
///
/// The payout schedule the platform uses is not decided yet (SRS open
/// decision 6 and 8), so the mock only needs these three display states.
enum PayoutStatus {
  requested('Requested'),
  processing('Processing'),
  paid('Paid');

  const PayoutStatus(this.label);

  final String label;
}

/// Supported app languages. English is P1, Bahasa Indonesia is P2. (FR-CS-3)
enum AppLanguage {
  english('English', 'en'),
  bahasaIndonesia('Bahasa Indonesia', 'id');

  const AppLanguage(this.label, this.code);

  final String label;
  final String code;
}
