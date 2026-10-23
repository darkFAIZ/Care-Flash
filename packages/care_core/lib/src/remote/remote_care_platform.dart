import 'dart:async';

import 'package:care_domain/care_domain.dart';

import '../mock/mock_data.dart';
import 'backend_client.dart';

/// A [CareSeekerPlatform] that talks to the shared demo backend over WebSocket.
///
/// When the Care-Flash app is launched with a `BACKEND_URL`, this replaces
/// [MockCarePlatform] so bookings the care seeker creates are visible to the
/// caregiver running in Care-Merchant, and vice versa. Stream state arrives as
/// full snapshots pushed by the backend after every operation. (AGENTS.md §5)
class RemoteCarePlatform implements CareSeekerPlatform {
  RemoteCarePlatform(this._client) {
    _subscription = _client.snapshots.listen(_applySnapshot);
  }

  final CareBackendClient _client;
  late final StreamSubscription<Map<String, Object?>> _subscription;

  final StreamController<CareSeeker?> _userController =
      StreamController<CareSeeker?>.broadcast();
  final StreamController<Booking?> _bookingController =
      StreamController<Booking?>.broadcast();
  final StreamController<List<Booking>> _historyController =
      StreamController<List<Booking>>.broadcast();

  CareSeeker? _user;
  Booking? _activeBooking;
  List<Booking> _history = const [];

  Future<void> connect() => _client.connect();

  void dispose() {
    _subscription.cancel();
    _userController.close();
    _bookingController.close();
    _historyController.close();
  }

  void _applySnapshot(Map<String, Object?> data) {
    _user = decodeOrNull(data['currentUser'], CareSeeker.fromJson);
    _activeBooking = decodeOrNull(data['activeBooking'], Booking.fromJson);
    _history = decodeList(data['bookingHistory'], Booking.fromJson);
    _userController.add(_user);
    _bookingController.add(_activeBooking);
    _historyController.add(_history);
  }

  // ---------------------------------------------------------------------------
  // AuthRepository
  // ---------------------------------------------------------------------------

  @override
  CareSeeker? get currentUser => _user;

  @override
  Stream<CareSeeker?> watchCurrentUser() async* {
    yield _user;
    yield* _userController.stream;
  }

  @override
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('seekerSignUp', {
    'name': name,
    'email': email,
    'password': password,
  });

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) => _authenticate('seekerSignIn', {'email': email, 'password': password});

  Future<AuthResult> _authenticate(String op, Map<String, Object?> args) async {
    final result = await _call(op, args);
    if (result['success'] == true) {
      _user = CareSeeker.fromJson(result['user']! as Map<String, Object?>);
      _userController.add(_user);
      return AuthResult.success(_user!);
    }
    return AuthResult.failure(result['error'] as String? ?? 'Sign in failed.');
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _userController.add(null);
  }

  // ---------------------------------------------------------------------------
  // BookingRepository
  // ---------------------------------------------------------------------------

  @override
  Booking? get activeBooking => _activeBooking;

  @override
  Stream<Booking?> watchActiveBooking() async* {
    yield _activeBooking;
    yield* _bookingController.stream;
  }

  @override
  Stream<List<Booking>> watchBookingHistory() async* {
    yield _history;
    yield* _historyController.stream;
  }

  @override
  Future<Booking> submitRequest(HelpRequest request) async {
    final json = await _call('submitRequest', {
      'helpType': request.helpType.name,
      'description': request.description,
      'checklist': request.checklist.toJson(),
      'location': request.location.toJson(),
      'scheduledAt': request.scheduledAt.toIso8601String(),
      'duration': request.duration.name,
      'genderFilter': request.genderFilter.name,
    });
    return Booking.fromJson(json);
  }

  @override
  Future<Booking> retryWithGenderFilter(GenderFilter filter) async {
    final json = await _call('retryWithGenderFilter', {'filter': filter.name});
    return Booking.fromJson(json);
  }

  @override
  Future<void> cancelBooking(CancellationReason reason) =>
      _callVoid('cancelBooking', {'reason': reason.name});

  @override
  Future<ButtonVerificationResult> verifyCaregiverCode(String code) async {
    final json = await _call('verifyCaregiverCode', {'code': code});
    return json['success'] == true
        ? const ButtonVerificationResult.success()
        : ButtonVerificationResult.failed(json['message'] as String?);
  }

  @override
  Future<ButtonVerificationResult> verifySafetyButton(
    ButtonVerification verification,
  ) async {
    final json = await _call('verifySafetyButton', {
      'method': verification.method.name,
      'payload': verification.payload,
    });
    return json['success'] == true
        ? const ButtonVerificationResult.success()
        : ButtonVerificationResult.failed(json['message'] as String?);
  }

  @override
  Future<void> endEarly() => _callVoid('endEarly');

  @override
  Future<void> reportIncident(IncidentReport report) =>
      _callVoid('reportIncident', {'report': report.toJson()});

  @override
  Future<void> rateCaregiver(CaregiverRating rating) =>
      _callVoid('rateCaregiver', rating.toJson());

  @override
  Future<void> submitAppFeedback(AppFeedback feedback) =>
      _callVoid('submitAppFeedback', feedback.toJson());

  // ---------------------------------------------------------------------------
  // PaymentRepository
  // ---------------------------------------------------------------------------

  @override
  List<PaymentMethod> availableMethods() => MockData.paymentMethods;

  @override
  Future<PaymentResult> pay({
    required String bookingId,
    required PaymentMethod method,
  }) async {
    final json = await _call('pay', {
      'bookingId': bookingId,
      'method': method.type.name,
    });
    return json['success'] == true
        ? const PaymentResult.succeeded()
        : PaymentResult.failed(json['message'] as String?);
  }

  // ---------------------------------------------------------------------------
  // DemoControls — the other side is a real app now, so these are no-ops.
  // ---------------------------------------------------------------------------

  @override
  void setAutoAdvance(bool enabled) {}

  @override
  void setNextRequestMatches(bool matches) {}

  @override
  void setNextPaymentFails(bool fails) {}

  @override
  void simulateCaregiverAccept() {}

  @override
  void simulateCaregiverDecline() {}

  @override
  void simulateCaregiverTravelling() {}

  @override
  void simulateCaregiverArrival() {}

  @override
  void simulateCaregiverCodeVerification({bool valid = true}) {}

  @override
  void simulateButtonScan({
    ButtonVerificationMethod method = ButtonVerificationMethod.qr,
    bool valid = true,
  }) {}

  @override
  void simulateButtonPress() {}

  @override
  void simulateSessionComplete() {}

  Future<Map<String, Object?>> _call(
    String op, [
    Map<String, Object?> args = const {},
  ]) async => await _client.call(op, args) as Map<String, Object?>;

  Future<void> _callVoid(
    String op, [
    Map<String, Object?> args = const {},
  ]) async {
    await _client.call(op, args);
  }
}
