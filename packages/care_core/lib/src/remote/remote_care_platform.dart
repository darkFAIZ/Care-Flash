import 'dart:async';

import 'package:care_domain/care_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _reconnectSubscription =
        _client.reconnected.listen((_) => _restoreSession());
  }

  final CareBackendClient _client;
  late final StreamSubscription<Map<String, Object?>> _subscription;
  late final StreamSubscription<void> _reconnectSubscription;

  /// Where the backend session token is kept between app launches.
  static const _tokenKey = 'backend.token.seeker';

  String? _token;

  final StreamController<CareSeeker?> _userController =
      StreamController<CareSeeker?>.broadcast();
  final StreamController<Booking?> _bookingController =
      StreamController<Booking?>.broadcast();
  final StreamController<List<Booking>> _historyController =
      StreamController<List<Booking>>.broadcast();

  CareSeeker? _user;
  Booking? _activeBooking;
  List<Booking> _history = const [];

  Future<void> connect() async {
    await _client.connect();
    await _restoreSession();
  }

  /// Signs this app back in with the token saved on the last launch.
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return;
    try {
      final result = await _client.call('authToken', {'token': token});
      if (result is Map && result['resume'] == true) {
        _token = token;
        _user = CareSeeker.fromJson(result['user']! as Map<String, Object?>);
        _userController.add(_user);
      } else {
        await prefs.remove(_tokenKey);
      }
    } on BackendException {
      await prefs.remove(_tokenKey);
    }
  }

  Future<void> _rememberToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  void dispose() {
    _subscription.cancel();
    _reconnectSubscription.cancel();
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
  }) =>
      _authenticate('seekerSignUp', {'name': name, 'email': email, 'password': password});

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) =>
      _authenticate('seekerSignIn', {'email': email, 'password': password});

  Future<AuthResult> _authenticate(String op, Map<String, Object?> args) async {
    final result = await _call(op, args);
    if (result['success'] == true) {
      _user = CareSeeker.fromJson(result['user']! as Map<String, Object?>);
      await _rememberToken(result['token'] as String?);
      _userController.add(_user);
      return AuthResult.success(_user!);
    }
    return AuthResult.failure(result['error'] as String? ?? 'Sign in failed.');
  }

  @override
  Future<void> signOut() async {
    final token = _token;
    _user = null;
    _userController.add(null);
    await _rememberToken(null);
    if (token != null) {
      try {
        await _callVoid('signOut', {'token': token});
      } on BackendException {
        // The local session is already gone; the server token expires on its
        // own if the connection is down.
      }
    }
  }

  @override
  Future<void> updateProfile({required String name}) =>
      _callVoid('updateSeekerProfile', {'name': name});

  @override
  Future<void> updateAvatar({String? avatarDataUrl}) =>
      _callVoid('updateSeekerAvatar', {'avatarDataUrl': avatarDataUrl});

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
    final json = await _call('pay', {'bookingId': bookingId, 'method': method.type.name});
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
  ]) async =>
      await _client.call(op, args) as Map<String, Object?>;

  Future<void> _callVoid(String op, [Map<String, Object?> args = const {}]) async {
    await _client.call(op, args);
  }
}
