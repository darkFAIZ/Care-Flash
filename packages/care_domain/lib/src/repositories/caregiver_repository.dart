import '../enums.dart';
import '../models/booking.dart';
import '../models/caregiver_account.dart';
import '../models/earnings.dart';
import '../models/feedback.dart';
import '../models/safety.dart';

/// Caregiver-facing platform API used by Care-Merchant. (FR-CM-1 to FR-CM-24)
///
/// Mirrors the care seeker repository style: keep the interface clean so an
/// HTTP client can replace the mock platform later without touching the
/// widgets. (AGENTS.md §5)
abstract interface class CaregiverRepository {
  /// The signed-in caregiver, or null when signed out. (FR-CM-1)
  CaregiverAccount? get currentCaregiver;

  /// Streams the signed-in caregiver so the UI can react to onboarding,
  /// availability and verification changes. (FR-CM-3 to FR-CM-6)
  Stream<CaregiverAccount?> watchCurrentCaregiver();

  /// Creates an account. A new account always starts unverified so the
  /// onboarding flow can be completed. (FR-CM-1, FR-CM-2)
  Future<CaregiverAuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required Gender gender,
  });

  Future<CaregiverAuthResult> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Updates the caregiver's profile details shown across the app. Gender has
  /// its own [updateGender] because matching depends on it. (Phase 5)
  Future<void> updateProfile({required String name});

  /// Sets or clears the caregiver's profile photo. [avatarDataUrl] is a
  /// `data:image/...;base64,...` string, or null to remove the photo.
  Future<void> updateAvatar({String? avatarDataUrl});

  /// Submits KTP identity details for platform review. (FR-CM-2)
  Future<void> submitVerification({
    required String ktpNumber,
    required String documentLabel,
  });

  /// Completes the safety module and awards the safety badge. (FR-CM-4)
  Future<void> completeSafetyModule();

  /// Records the caregiver's gender for the care seeker's matching filter.
  /// (FR-CM-5)
  Future<void> updateGender(Gender gender);

  /// Sets whether the caregiver currently accepts requests. (FR-CM-6)
  Future<void> updateAvailability(CaregiverAvailability availability);

  /// The request currently offered to this caregiver, or null. (FR-CM-7)
  ///
  /// Before the caregiver accepts, the platform withholds the care seeker
  /// location and client code; those are only needed after acceptance.
  /// (FR-CM-8, DC-CM-2)
  Stream<Booking?> watchIncomingRequest();

  /// The booking this caregiver has accepted, or null. (FR-CM-10)
  Stream<Booking?> watchActiveBooking();

  /// Finished bookings, for the earnings and history screens. (FR-CM-21)
  Stream<List<Booking>> watchBookingHistory();

  /// Accepts the offered request inside the response window. (FR-CM-9)
  Future<void> acceptRequest();

  /// Declines the offered request. Declining has no rating penalty. (FR-CM-9)
  Future<void> declineRequest();

  /// Reports a safety concern about the care seeker before the session starts.
  /// The platform cancels the booking and notifies support. (FR-CM-11)
  Future<void> reportDanger(String description);

  /// Starts the trip to the care seeker after accepting. (FR-CM-10)
  Future<void> startTrip();

  /// Marks the caregiver as arrived at the care seeker's location. (FR-CM-10)
  Future<void> markArrived();

  /// Verifies the client code the care seeker presents on arrival. A wrong
  /// code cancels the booking and notifies support; the session must not
  /// start. (FR-CM-13, FR-CM-14)
  Future<ButtonVerificationResult> verifyClientCode(String code);

  /// Marks the work complete and notifies the care seeker. (FR-CM-18)
  Future<void> completeSession();

  /// Raises an SOS during the session. The platform alerts the care seeker's
  /// emergency contacts and support, and applies the compensation policy.
  /// (FR-CM-19)
  Future<void> sos(String description);

  /// Reports the care seeker with evidence during or after the session.
  /// (FR-CM-20)
  Future<void> reportCareSeeker(IncidentReport report);

  /// The caregiver's earnings: available balance, transaction history and
  /// payout status, plus expected earnings from a running session.
  /// (FR-CM-21, FR-P-29)
  Stream<EarningsSummary> watchEarnings();

  /// Requests a withdrawal of available earnings. Fails when [amount] is not a
  /// whole amount within the configured minimum and the available balance.
  /// (FR-CM-22)
  Future<WithdrawalResult> requestWithdrawal(int amount);

  /// Feedback the care seeker left about this caregiver, made visible to them
  /// in Care-Merchant. (FR-CM-23, FR-P-27)
  Stream<List<FeedbackReceived>> watchFeedbackReceived();

  /// The care-seeker ratings this caregiver has already submitted, so the UI
  /// can hide visits that no longer need a rating. (FR-CM-24)
  Stream<List<CareSeekerRating>> watchCareSeekerRatings();

  /// Rates the care seeker after a session. (FR-CM-24)
  Future<void> rateCareSeeker(CareSeekerRating rating);
}

/// Debug-only hooks used by Care-Merchant's Demo Controls sheet.
///
/// Care-Flash and Care-Merchant are separate processes, so this app's mock
/// platform simulates the care seeker. Real builds use an HTTP implementation
/// and never call this interface. (AGENTS.md §5)
abstract interface class CaregiverDemoControls {
  /// When true, the mock progresses through simulated steps on its own.
  void setAutoAdvance(bool enabled);

  /// Forces the next identity review to be rejected so the rejection and
  /// resubmission path can be shown. (FR-CM-3)
  void setNextVerificationFails(bool fails);

  /// Delivers an incoming request immediately instead of waiting for the
  /// normal delay. (FR-CM-7)
  void simulateIncomingRequest();

  /// Simulates the care seeker cancelling the booking, which notifies the
  /// caregiver. (FR-CM-12)
  void simulateCareSeekerCancel();

  /// Simulates the care seeker scanning or reading the safety button the
  /// caregiver handed over. The prototype has no camera or NFC reader.
  /// (FR-CM-15, FR-CM-16)
  void simulateCareSeekerButtonScan({
    ButtonVerificationMethod method,
    bool valid,
  });

  /// Simulates the care seeker ending the session early, which applies the
  /// caregiver compensation policy. (FR-P-22)
  void simulateCareSeekerEndEarly();
}
