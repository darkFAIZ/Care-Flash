import '../../features/auth_onboarding/domain/entities/caregiver_user.dart';
import '../../features/matching/domain/entities/request_offer.dart';
import '../../features/ride_transit/domain/entities/grab_ride_info.dart';
import '../../features/arrival_verification/domain/entities/safety_button_payload.dart';
import '../../features/active_session/domain/entities/active_session.dart';
import '../../features/earnings/domain/entities/earnings_ledger.dart';

abstract class PlatformApiClient {
  // Auth & Onboarding
  Future<CaregiverProfile> login(String email, String password);
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required CaregiverGender gender,
  });
  Future<CaregiverProfile> submitStudentId(String studentIdNumber, String photoUrl);
  Future<CaregiverProfile> completeSafetyModule();
  Future<CaregiverProfile> getProfile();

  // Availability
  Future<bool> setAvailability(bool isAvailable);

  // Matching
  Stream<RequestOffer> get requestStream;
  Future<AcceptedTrip> acceptOffer(String requestReference);
  Future<void> declineOffer(String requestReference);
  void simulateIncomingOffer(RequestOffer offer);

  // Ride Transit
  Stream<GrabRideInfo> get grabRideStream;
  Future<void> reportDangerBeforeSession(String bookingId, String reason);

  // Handover & Arrival
  Future<bool> verifyClientCode(String bookingId, String code);
  Future<SafetyButtonPayload> activateSafetyButton(String bookingId);
  Stream<bool> get seekerButtonScanStream;
  void simulateSeekerButtonScan(String bookingId);

  // Active Session
  Future<ActiveSession> startSession(String bookingId);
  Future<void> markWorkCompleted(String sessionId);
  Future<void> triggerSos(String sessionId);
  Stream<SessionOutcomeType> get sessionOutcomeStream;
  void simulateSeekerEarlyEnd(String sessionId);

  // Post Session
  Future<void> rateSeeker(String bookingId, int rating, String? comments);
  Future<void> submitIncidentReport(
    String bookingId,
    String description,
    List<String> evidenceUrls,
  );

  // Earnings
  Future<EarningsLedger> getEarningsLedger();
  Future<bool> requestPayout(int amountIdr, String bankName, String accountNumber);
}
