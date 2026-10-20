import '../enums.dart';
import '../models/booking.dart';
import '../models/feedback.dart';
import '../models/help_request.dart';
import '../models/safety.dart';

/// The care seeker's request-to-session lifecycle. (FR-CS-4 to FR-CS-21)
abstract interface class BookingRepository {
  /// The current open booking, or null. Emits on every status change.
  Stream<Booking?> watchActiveBooking();

  Booking? get activeBooking;

  /// Past and finished bookings for the activity page.
  Stream<List<Booking>> watchBookingHistory();

  /// Creates a request and starts matching. (FR-CS-4 to FR-CS-9)
  Future<Booking> submitRequest(HelpRequest request);

  /// Re-runs matching with a new gender filter after a no-match. (FR-CS-9)
  Future<Booking> retryWithGenderFilter(GenderFilter filter);

  /// Cancels the current booking. (FR-CS-9, FR-P-13)
  Future<void> cancelBooking(CancellationReason reason);

  /// Verifies the physical safety button by QR or NFC. (FR-CS-13, FR-CS-14)
  Future<ButtonVerificationResult> verifySafetyButton(ButtonVerification verification);

  /// Ends the session early and pays the caregiver compensation. (FR-CS-16)
  Future<void> endEarly();

  /// Reports an incident, ending the session and refunding the care seeker.
  /// (FR-CS-17, FR-P-23)
  Future<void> reportIncident(IncidentReport report);

  /// Rates the caregiver after a session. (FR-CS-19)
  Future<void> rateCaregiver(CaregiverRating rating);

  /// Gives feedback about the Care-Flash app. (FR-CS-20)
  Future<void> submitAppFeedback(AppFeedback feedback);
}
