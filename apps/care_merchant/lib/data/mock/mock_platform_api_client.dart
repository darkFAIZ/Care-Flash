import 'dart:async';
import '../../core/network/platform_api_client.dart';
import '../../features/active_session/domain/entities/active_session.dart';
import '../../features/arrival_verification/domain/entities/safety_button_payload.dart';
import '../../features/auth_onboarding/domain/entities/caregiver_user.dart';
import '../../features/earnings/domain/entities/earnings_ledger.dart';
import '../../features/matching/domain/entities/request_offer.dart';
import '../../features/ride_transit/domain/entities/grab_ride_info.dart';
import 'mock_data.dart';

class MockPlatformApiClient implements PlatformApiClient {
  final Duration latency;

  CaregiverProfile _currentProfile;
  EarningsLedger _earningsLedger;

  final StreamController<RequestOffer> _requestStreamController =
      StreamController<RequestOffer>.broadcast();
  final StreamController<GrabRideInfo> _grabRideStreamController =
      StreamController<GrabRideInfo>.broadcast();
  final StreamController<bool> _seekerButtonScanController =
      StreamController<bool>.broadcast();
  final StreamController<SessionOutcomeType> _sessionOutcomeController =
      StreamController<SessionOutcomeType>.broadcast();

  MockPlatformApiClient({
    this.latency = const Duration(milliseconds: 400),
    CaregiverProfile? initialProfile,
    EarningsLedger? initialEarnings,
  })  : _currentProfile = initialProfile ?? MockData.verifiedCaregiver,
        _earningsLedger = initialEarnings ?? MockData.sampleEarnings;

  Future<void> _simulateDelay() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  @override
  Future<CaregiverProfile> login(String email, String password) async {
    await _simulateDelay();
    return _currentProfile;
  }

  @override
  Future<CaregiverProfile> register({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required CaregiverGender gender,
  }) async {
    await _simulateDelay();
    _currentProfile = CaregiverProfile(
      id: 'cg_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      university: university,
      studentIdNumber: '',
      verificationStatus: VerificationStatus.pending,
      safetyBadgeEarned: false,
      gender: gender,
      isAvailable: false,
      averageRating: 5.0,
      totalCompletedSessions: 0,
    );
    return _currentProfile;
  }

  @override
  Future<CaregiverProfile> submitStudentId(
    String studentIdNumber,
    String photoUrl,
  ) async {
    await _simulateDelay();
    _currentProfile = _currentProfile.copyWith(
      studentIdNumber: studentIdNumber,
      studentCardPhotoUrl: photoUrl,
      verificationStatus: VerificationStatus.pending,
    );
    return _currentProfile;
  }

  @override
  Future<CaregiverProfile> completeSafetyModule() async {
    await _simulateDelay();
    _currentProfile = _currentProfile.copyWith(
      safetyBadgeEarned: true,
      verificationStatus: VerificationStatus.approved,
    );
    return _currentProfile;
  }

  @override
  Future<CaregiverProfile> getProfile() async {
    await _simulateDelay();
    return _currentProfile;
  }

  @override
  Future<bool> setAvailability(bool isAvailable) async {
    await _simulateDelay();
    _currentProfile = _currentProfile.copyWith(isAvailable: isAvailable);
    return true;
  }

  @override
  Stream<RequestOffer> get requestStream => _requestStreamController.stream;

  @override
  void simulateIncomingOffer(RequestOffer offer) {
    _requestStreamController.add(offer);
  }

  @override
  Future<AcceptedTrip> acceptOffer(String requestReference) async {
    await _simulateDelay();
    return MockData.sampleAcceptedTrip.copyWith(
      requestReference: requestReference,
    );
  }

  @override
  Future<void> declineOffer(String requestReference) async {
    await _simulateDelay();
  }

  @override
  Stream<GrabRideInfo> get grabRideStream => _grabRideStreamController.stream;

  void updateGrabRide(GrabRideInfo rideInfo) {
    _grabRideStreamController.add(rideInfo);
  }

  @override
  Future<void> reportDangerBeforeSession(String bookingId, String reason) async {
    await _simulateDelay();
  }

  @override
  Future<bool> verifyClientCode(String bookingId, String code) async {
    await _simulateDelay();
    // Default valid PIN is 123456
    return code == '123456';
  }

  @override
  Future<SafetyButtonPayload> activateSafetyButton(String bookingId) async {
    await _simulateDelay();
    return SafetyButtonPayload(
      bookingId: bookingId,
      buttonToken: 'BTN-TOK-${DateTime.now().millisecondsSinceEpoch}',
      qrDataUri: 'careflash://safety-button/$bookingId/activate',
      nfcPayloadString: 'CF:BTN:$bookingId',
      issuedAt: DateTime.now(),
    );
  }

  @override
  Stream<bool> get seekerButtonScanStream => _seekerButtonScanController.stream;

  @override
  void simulateSeekerButtonScan(String bookingId) {
    _seekerButtonScanController.add(true);
  }

  @override
  Future<ActiveSession> startSession(String bookingId) async {
    await _simulateDelay();
    return ActiveSession(
      sessionId: 'SES-$bookingId',
      bookingId: bookingId,
      careSeekerName: 'Ibu Ratna',
      totalDurationSeconds: 3600,
      remainingSeconds: 3600,
      boundaries: const [
        BoundaryItem(id: 'b1', title: 'Light walking support only'),
        BoundaryItem(id: 'b2', title: 'No lifting > 15kg'),
        BoundaryItem(id: 'b3', title: 'No administering medications'),
      ],
      basePayoutIdr: 50000,
    );
  }

  @override
  Future<void> markWorkCompleted(String sessionId) async {
    await _simulateDelay();
    _sessionOutcomeController.add(SessionOutcomeType.normalCompletion);
  }

  @override
  Future<void> triggerSos(String sessionId) async {
    await _simulateDelay();
    _sessionOutcomeController.add(SessionOutcomeType.caregiverSosTriggered);
  }

  @override
  Stream<SessionOutcomeType> get sessionOutcomeStream =>
      _sessionOutcomeController.stream;

  @override
  void simulateSeekerEarlyEnd(String sessionId) {
    _sessionOutcomeController.add(SessionOutcomeType.careSeekerEarlyEnd);
  }

  @override
  Future<void> rateSeeker(String bookingId, int rating, String? comments) async {
    await _simulateDelay();
  }

  @override
  Future<void> submitIncidentReport(
    String bookingId,
    String description,
    List<String> evidenceUrls,
  ) async {
    await _simulateDelay();
  }

  @override
  Future<EarningsLedger> getEarningsLedger() async {
    await _simulateDelay();
    return _earningsLedger;
  }

  @override
  Future<bool> requestPayout(
    int amountIdr,
    String bankName,
    String accountNumber,
  ) async {
    await _simulateDelay();
    if (_earningsLedger.availableBalanceIdr >= amountIdr) {
      final newTransactions = List<TransactionRecord>.from(
        _earningsLedger.transactions,
      )..insert(
          0,
          TransactionRecord(
            id: 'TX-WD-${DateTime.now().millisecondsSinceEpoch}',
            bookingReference: 'PAYOUT-$bankName',
            timestamp: DateTime.now(),
            amountIdr: -amountIdr,
            description: 'Withdrawal to $bankName ($accountNumber)',
            status: 'withdrawn',
          ),
        );
      _earningsLedger = _earningsLedger.copyWith(
        availableBalanceIdr: _earningsLedger.availableBalanceIdr - amountIdr,
        transactions: newTransactions,
      );
      return true;
    }
    return false;
  }

  void dispose() {
    _requestStreamController.close();
    _grabRideStreamController.close();
    _seekerButtonScanController.close();
    _sessionOutcomeController.close();
  }
}
