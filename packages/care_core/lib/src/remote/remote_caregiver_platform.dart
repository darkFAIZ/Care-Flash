import 'dart:async';

import 'package:care_domain/care_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_client.dart';

/// A [CaregiverPlatform] that talks to the shared demo backend over WebSocket.
///
/// When Care-Merchant is launched with a `BACKEND_URL`, this replaces
/// [MockCaregiverPlatform] so the caregiver sees and acts on the requests a real
/// care seeker submits from Care-Flash. Stream state arrives as full snapshots
/// pushed by the backend after every operation. (AGENTS.md §5)
class RemoteCaregiverPlatform implements CaregiverPlatform {
  RemoteCaregiverPlatform(this._client) {
    _subscription = _client.snapshots.listen(_applySnapshot);
    _reconnectSubscription =
        _client.reconnected.listen((_) => _restoreSession());
  }

  final CareBackendClient _client;
  late final StreamSubscription<Map<String, Object?>> _subscription;
  late final StreamSubscription<void> _reconnectSubscription;

  /// Where the backend session token is kept between app launches.
  static const _tokenKey = 'backend.token.caregiver';

  String? _token;

  final StreamController<CaregiverAccount?> _caregiverController =
      StreamController<CaregiverAccount?>.broadcast();
  final StreamController<Booking?> _incomingController =
      StreamController<Booking?>.broadcast();
  final StreamController<Booking?> _activeController =
      StreamController<Booking?>.broadcast();
  final StreamController<List<Booking>> _historyController =
      StreamController<List<Booking>>.broadcast();
  final StreamController<EarningsSummary> _earningsController =
      StreamController<EarningsSummary>.broadcast();
  final StreamController<List<FeedbackReceived>> _feedbackController =
      StreamController<List<FeedbackReceived>>.broadcast();
  final StreamController<List<CareSeekerRating>> _ratingsController =
      StreamController<List<CareSeekerRating>>.broadcast();

  CaregiverAccount? _caregiver;
  Booking? _incomingRequest;
  Booking? _activeBooking;
  List<Booking> _history = const [];
  EarningsSummary _earnings = const EarningsSummary();
  List<FeedbackReceived> _feedbackReceived = const [];
  List<CareSeekerRating> _careSeekerRatings = const [];

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
        _caregiver =
            CaregiverAccount.fromJson(result['user']! as Map<String, Object?>);
        _caregiverController.add(_caregiver);
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
    _caregiverController.close();
    _incomingController.close();
    _activeController.close();
    _historyController.close();
    _earningsController.close();
    _feedbackController.close();
    _ratingsController.close();
  }

  void _applySnapshot(Map<String, Object?> data) {
    _caregiver = decodeOrNull(data['currentCaregiver'], CaregiverAccount.fromJson);
    _incomingRequest = decodeOrNull(data['incomingRequest'], Booking.fromJson);
    _activeBooking = decodeOrNull(data['activeBooking'], Booking.fromJson);
    _history = decodeList(data['bookingHistory'], Booking.fromJson);
    _earnings =
        decodeOrNull(data['earnings'], EarningsSummary.fromJson) ?? const EarningsSummary();
    _feedbackReceived = decodeList(data['feedbackReceived'], FeedbackReceived.fromJson);
    _careSeekerRatings =
        decodeList(data['careSeekerRatings'], CareSeekerRating.fromJson);
    _caregiverController.add(_caregiver);
    _incomingController.add(_incomingRequest);
    _activeController.add(_activeBooking);
    _historyController.add(_history);
    _earningsController.add(_earnings);
    _feedbackController.add(_feedbackReceived);
    _ratingsController.add(_careSeekerRatings);
  }

  @override
  String? get debugClientCode => _activeBooking?.clientCode;

  // ---------------------------------------------------------------------------
  // CaregiverRepository
  // ---------------------------------------------------------------------------

  @override
  CaregiverAccount? get currentCaregiver => _caregiver;

  @override
  Stream<CaregiverAccount?> watchCurrentCaregiver() async* {
    yield _caregiver;
    yield* _caregiverController.stream;
  }

  @override
  Future<CaregiverAuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required Gender gender,
  }) =>
      _authenticate('caregiverSignUp', {
        'name': name,
        'email': email,
        'password': password,
        'gender': gender.name,
      });

  @override
  Future<CaregiverAuthResult> signIn({
    required String email,
    required String password,
  }) =>
      _authenticate('caregiverSignIn', {'email': email, 'password': password});

  Future<CaregiverAuthResult> _authenticate(
    String op,
    Map<String, Object?> args,
  ) async {
    final result = await _call(op, args);
    if (result['success'] == true) {
      _caregiver = CaregiverAccount.fromJson(result['user']! as Map<String, Object?>);
      await _rememberToken(result['token'] as String?);
      _caregiverController.add(_caregiver);
      return CaregiverAuthResult.success(_caregiver!);
    }
    return CaregiverAuthResult.failure(result['error'] as String? ?? 'Sign in failed.');
  }

  @override
  Future<void> signOut() async {
    final token = _token;
    _caregiver = null;
    _caregiverController.add(null);
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
      _callVoid('updateCaregiverProfile', {'name': name});

  @override
  Future<void> updateAvatar({String? avatarDataUrl}) =>
      _callVoid('updateCaregiverAvatar', {'avatarDataUrl': avatarDataUrl});

  @override
  Future<void> submitVerification({
    required String ktpNumber,
    required String documentLabel,
  }) =>
      _callVoid('submitVerification', {
        'ktpNumber': ktpNumber,
        'documentLabel': documentLabel,
      });

  @override
  Future<void> completeSafetyModule() => _callVoid('completeSafetyModule');

  @override
  Future<void> updateGender(Gender gender) =>
      _callVoid('updateGender', {'gender': gender.name});

  @override
  Future<void> updateAvailability(CaregiverAvailability availability) =>
      _callVoid('updateAvailability', {'availability': availability.name});

  @override
  Stream<Booking?> watchIncomingRequest() async* {
    yield _incomingRequest;
    yield* _incomingController.stream;
  }

  @override
  Stream<Booking?> watchActiveBooking() async* {
    yield _activeBooking;
    yield* _activeController.stream;
  }

  @override
  Stream<List<Booking>> watchBookingHistory() async* {
    yield _history;
    yield* _historyController.stream;
  }

  @override
  Future<void> acceptRequest() => _callVoid('acceptRequest');

  @override
  Future<void> declineRequest() => _callVoid('declineRequest');

  @override
  Future<void> reportDanger(String description) =>
      _callVoid('reportDanger', {'description': description});

  @override
  Future<void> startTrip() => _callVoid('startTrip');

  @override
  Future<void> markArrived() => _callVoid('markArrived');

  @override
  Future<ButtonVerificationResult> verifyClientCode(String code) async {
    final json = await _call('verifyClientCode', {'code': code});
    return json['success'] == true
        ? const ButtonVerificationResult.success()
        : ButtonVerificationResult.failed(json['message'] as String?);
  }

  @override
  Future<void> completeSession() => _callVoid('completeSession');

  @override
  Future<void> sos(String description) => _callVoid('sos', {'description': description});

  @override
  Future<void> reportCareSeeker(IncidentReport report) =>
      _callVoid('reportCareSeeker', {'report': report.toJson()});

  @override
  Stream<EarningsSummary> watchEarnings() async* {
    yield _earnings;
    yield* _earningsController.stream;
  }

  @override
  Future<WithdrawalResult> requestWithdrawal(int amount) async {
    final json = await _call('requestWithdrawal', {'amount': amount});
    return json['success'] == true
        ? WithdrawalResult.succeeded(json['amount']! as int)
        : WithdrawalResult.failed(json['message'] as String?);
  }

  @override
  Stream<List<FeedbackReceived>> watchFeedbackReceived() async* {
    yield _feedbackReceived;
    yield* _feedbackController.stream;
  }

  @override
  Stream<List<CareSeekerRating>> watchCareSeekerRatings() async* {
    yield _careSeekerRatings;
    yield* _ratingsController.stream;
  }

  @override
  Future<void> rateCareSeeker(CareSeekerRating rating) =>
      _callVoid('rateCareSeeker', rating.toJson());

  // ---------------------------------------------------------------------------
  // CaregiverDemoControls — the other side is a real app now, so these are
  // no-ops.
  // ---------------------------------------------------------------------------

  @override
  void setAutoAdvance(bool enabled) {}

  @override
  void setNextVerificationFails(bool fails) {}

  @override
  void simulateIncomingRequest() {}

  @override
  void simulateCareSeekerCancel() {}

  @override
  void simulateCareSeekerButtonScan({
    ButtonVerificationMethod method = ButtonVerificationMethod.qr,
    bool valid = true,
  }) {}

  @override
  void simulateCareSeekerEndEarly() {}

  Future<Map<String, Object?>> _call(
    String op, [
    Map<String, Object?> args = const {},
  ]) async =>
      await _client.call(op, args) as Map<String, Object?>;

  Future<void> _callVoid(String op, [Map<String, Object?> args = const {}]) async {
    await _client.call(op, args);
  }
}
