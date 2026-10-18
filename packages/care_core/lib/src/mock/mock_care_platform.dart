import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../enums.dart';
import '../formatting.dart';
import '../models/account.dart';
import '../models/booking.dart';
import '../models/feedback.dart';
import '../models/help_request.dart';
import '../models/payment.dart';
import '../models/safety.dart';
import '../pricing/pricing.dart';
import '../repositories/auth_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/demo_controls.dart';
import '../repositories/payment_repository.dart';
import 'mock_data.dart';

/// A local, in-process stand-in for the shared platform.
///
/// Care-Flash and Care-Merchant are separate processes, so this mock simulates
/// the whole booking lifecycle for one app, including the other side, using
/// timers and the demo hooks. It is the default implementation behind the
/// repository interfaces and can be replaced by an HTTP client later.
/// (AGENTS.md §5)
class MockCarePlatform
    implements AuthRepository, BookingRepository, PaymentRepository, DemoControls {
  MockCarePlatform._(this._prefs, this._random);

  static const String _userKey = 'care_core.mock.user';
  static const String _activeBookingKey = 'care_core.mock.active_booking';
  static const String _ratingsKey = 'care_core.mock.ratings';
  static const String _appFeedbackKey = 'care_core.mock.app_feedback';

  /// Simulated timing. The platform SRS allows up to 60 seconds to match.
  /// (PR-CS-1)
  static const Duration matchingDelay = Duration(seconds: 3);
  static const Duration caregiverAcceptDelay = Duration(seconds: 3);
  static const Duration travelDelay = Duration(seconds: 2);
  static const Duration arrivalDelay = Duration(seconds: 2);
  static const Duration codeVerificationDelay = Duration(seconds: 2);

  final SharedPreferences _prefs;
  final Random _random;

  final StreamController<CareSeeker?> _userController =
      StreamController<CareSeeker?>.broadcast();
  final StreamController<Booking?> _bookingController =
      StreamController<Booking?>.broadcast();
  final StreamController<List<Booking>> _historyController =
      StreamController<List<Booking>>.broadcast();

  CareSeeker? _user;
  Booking? _activeBooking;
  final List<Booking> _history = [];
  final Set<String> _declinedCaregiverIds = {};

  Timer? _pendingTimer;
  bool _autoAdvance = true;
  bool _nextRequestMatches = true;
  bool _nextPaymentFails = false;

  /// Creates the mock platform, loading any persisted state.
  static Future<MockCarePlatform> create({Random? random}) async {
    final prefs = await SharedPreferences.getInstance();
    final platform = MockCarePlatform._(prefs, random ?? Random());
    platform._restore();
    return platform;
  }

  void _restore() {
    final userJson = _prefs.getString(_userKey);
    if (userJson != null) {
      _user = CareSeeker.fromJson(jsonDecode(userJson) as Map<String, Object?>);
    }
    final bookingJson = _prefs.getString(_activeBookingKey);
    if (bookingJson != null) {
      final booking =
          Booking.fromJson(jsonDecode(bookingJson) as Map<String, Object?>);
      if (booking.status.isOpen) {
        _activeBooking = booking;
      } else {
        _history.add(booking);
      }
    }
  }

  /// Releases timers and streams. Call when the platform is no longer needed.
  void dispose() {
    _pendingTimer?.cancel();
    _userController.close();
    _bookingController.close();
    _historyController.close();
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
  }) async {
    await _smallDelay();
    if (name.trim().isEmpty || !email.contains('@') || password.length < 6) {
      return const AuthResult.failure(
        'Enter a name, a valid email and a password of at least 6 characters.',
      );
    }
    final user = CareSeeker(
      id: 'seeker-${_random.nextInt(9000) + 1000}',
      name: name.trim(),
      email: email.trim(),
    );
    await _setUser(user);
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await _smallDelay();
    if (!email.contains('@') || password.length < 6) {
      return const AuthResult.failure(
        'Enter a valid email and a password of at least 6 characters.',
      );
    }
    final user = CareSeeker(
      id: 'seeker-demo',
      name: _nameFromEmail(email),
      email: email.trim(),
    );
    await _setUser(user);
    return AuthResult.success(user);
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_userKey);
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
    yield List<Booking>.unmodifiable(_history);
    yield* _historyController.stream;
  }

  @override
  Future<Booking> submitRequest(HelpRequest request) async {
    final now = DateTime.now();
    _declinedCaregiverIds.clear();
    final booking = Booking(
      id: 'bk-${_random.nextInt(90000) + 10000}',
      requestReference: _reference(),
      helpType: request.helpType,
      description: request.description,
      checklist: request.checklist,
      location: request.location,
      scheduledAt: request.scheduledAt,
      duration: request.duration,
      genderFilter: request.genderFilter,
      price: Pricing.breakdown(request.duration),
      status: BookingStatus.matching,
      createdAt: now,
      updates: [
        BookingUpdate(
          status: BookingStatus.matching,
          message: 'Looking for a nearby caregiver…',
          at: now,
        ),
      ],
    );
    await _setActiveBooking(booking);
    _scheduleMatching();
    return booking;
  }

  @override
  Future<Booking> retryWithGenderFilter(GenderFilter filter) async {
    final booking = _activeBooking;
    if (booking == null) {
      throw StateError('There is no active booking to retry.');
    }
    _declinedCaregiverIds.clear();
    final updated = booking
        .copyWith(genderFilter: filter, status: BookingStatus.matching)
        .withUpdate(
          BookingUpdate(
            status: BookingStatus.matching,
            message: 'Searching again with a new filter…',
            at: DateTime.now(),
          ),
        );
    await _setActiveBooking(updated);
    _scheduleMatching();
    return updated;
  }

  @override
  Future<void> cancelBooking(CancellationReason reason) async {
    final booking = _activeBooking;
    if (booking == null) {
      return;
    }
    // A cancelled paid booking is refunded: the caregiver is not paid when no
    // one accepts in time and the care seeker keeps their money otherwise.
    // (FR-P-13, FR-CS-15)
    final refunded = _refunded(booking, partial: false);
    final refundNote =
        refunded.hasRefund ? ' ${formatIdr(refunded.refundAmount!)} refunded.' : '';
    _finishBooking(
      refunded
          .copyWith(status: BookingStatus.cancelled, cancellationReason: reason)
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.cancelled,
              message: '${reason.label}.$refundNote',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<ButtonVerificationResult> verifySafetyButton(
    ButtonVerification verification,
  ) async {
    await _smallDelay();
    final booking = _activeBooking;
    if (booking == null) {
      return const ButtonVerificationResult.failed('This booking is no longer active.');
    }
    if (!booking.canVerifyButton) {
      return const ButtonVerificationResult.failed(
        'The safety button cannot be verified yet.',
      );
    }
    final expected = booking.safetyButtonId;
    if (expected == null || verification.payload.trim() != expected) {
      _finishBooking(_failedVerification(
        booking,
        'The safety button does not match this booking.',
      ));
      return const ButtonVerificationResult.failed(
        'The safety button does not match this booking. The booking was cancelled.',
      );
    }
    await _setActiveBooking(
      booking
          .copyWith(status: BookingStatus.active)
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.active,
              message: 'Session started.',
              at: DateTime.now(),
            ),
          ),
    );
    return const ButtonVerificationResult.success();
  }

  @override
  Future<void> endEarly() async {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.active) {
      return;
    }
    // The caregiver keeps the early-end compensation and the unused part of the
    // visit is refunded to the care seeker. (FR-CS-16, FR-P-22)
    final partial = _refunded(booking, partial: true);
    final refundNote = partial.hasRefund
        ? ' ${formatIdr(partial.refundAmount!)} refunded to you.'
        : '';
    _finishBooking(
      partial
          .copyWith(
            status: BookingStatus.endedEarly,
            outcome: SessionOutcome.endedEarly,
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.endedEarly,
              message:
                  'Session ended early. The caregiver receives the configured '
                  'compensation.$refundNote',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<void> reportIncident(IncidentReport report) async {
    final booking = _activeBooking;
    if (booking == null) {
      return;
    }
    // A report returns the full amount charged. (FR-CS-17, FR-P-23)
    final refunded = _refunded(booking, partial: false);
    final refundNote = refunded.hasRefund
        ? ' ${formatIdr(refunded.refundAmount!)} refunded to you.'
        : ' Your payment will be refunded.';
    _finishBooking(
      refunded
          .copyWith(
            status: BookingStatus.reported,
            outcome: SessionOutcome.careSeekerReported,
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.reported,
              message:
                  'Report sent to support and the emergency response channel.'
                  '$refundNote',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<void> rateCaregiver(CaregiverRating rating) async {
    final list = _prefs.getStringList(_ratingsKey) ?? [];
    list.add(jsonEncode(rating.toJson()));
    await _prefs.setStringList(_ratingsKey, list);
  }

  @override
  Future<void> submitAppFeedback(AppFeedback feedback) async {
    final list = _prefs.getStringList(_appFeedbackKey) ?? [];
    list.add(jsonEncode(feedback.toJson()));
    await _prefs.setStringList(_appFeedbackKey, list);
  }

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
    await _smallDelay();
    final booking = _activeBooking;
    if (booking == null || booking.id != bookingId) {
      return const PaymentResult.failed('This booking is no longer available.');
    }
    if (_nextPaymentFails) {
      // Clear the flag so the retry attempt can succeed, as in the SRS flow.
      _nextPaymentFails = false;
      return const PaymentResult.failed(
        'Payment failed. Check your balance and try again.',
      );
    }
    final paid = booking
        .copyWith(
          status: BookingStatus.paidPending,
          paymentMethod: method,
          paymentStatus: PaymentStatus.succeeded,
          clientCode: _clientCode(),
        )
        .withUpdate(
          BookingUpdate(
            status: BookingStatus.paidPending,
            message: 'Payment received. Waiting for a caregiver to accept.',
            at: DateTime.now(),
          ),
        );
    await _setActiveBooking(paid);
    if (_autoAdvance) {
      _scheduleCaregiverAccept();
    }
    return const PaymentResult.succeeded();
  }

  // ---------------------------------------------------------------------------
  // DemoControls
  // ---------------------------------------------------------------------------

  @override
  void setAutoAdvance(bool enabled) => _autoAdvance = enabled;

  @override
  void setNextRequestMatches(bool matches) => _nextRequestMatches = matches;

  @override
  void setNextPaymentFails(bool fails) => _nextPaymentFails = fails;

  @override
  void simulateCaregiverAccept() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.paidPending) {
      return;
    }
    _acceptBooking(booking);
  }

  @override
  void simulateCaregiverDecline() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.paidPending) {
      return;
    }
    final declinedId = booking.caregiver?.id;
    if (declinedId != null) {
      _declinedCaregiverIds.add(declinedId);
    }
    final next = _nextMatchingCaregiver(booking.genderFilter);
    if (next == null) {
      unawaited(cancelBooking(CancellationReason.timeout));
      return;
    }
    final offered = booking
        .copyWith(caregiver: next, status: BookingStatus.paidPending)
        .withUpdate(
          BookingUpdate(
            status: BookingStatus.paidPending,
            message: 'Offered to another caregiver.',
            at: DateTime.now(),
          ),
        );
    unawaited(_setActiveBooking(offered));
    if (_autoAdvance) {
      _scheduleCaregiverAccept();
    }
  }

  @override
  void simulateCaregiverTravelling() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.confirmed) {
      return;
    }
    _travelBooking(booking);
  }

  @override
  void simulateCaregiverArrival() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.caregiverTravelling) {
      return;
    }
    _arriveBooking(booking);
  }

  @override
  void simulateCaregiverCodeVerification({bool valid = true}) {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.arrived) {
      return;
    }
    if (!valid) {
      _finishBooking(_failedVerification(booking, 'The client code did not match.'));
      return;
    }
    unawaited(
      _setActiveBooking(
        booking
            .copyWith(
              status: BookingStatus.codeVerified,
              safetyButtonId: 'BTN-${booking.id}',
            )
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.codeVerified,
                message: 'Client code verified. Hand over the safety button.',
                at: DateTime.now(),
              ),
            ),
      ),
    );
  }

  @override
  void simulateButtonScan({
    ButtonVerificationMethod method = ButtonVerificationMethod.qr,
    bool valid = true,
  }) {
    final booking = _activeBooking;
    if (booking == null || !booking.canVerifyButton) {
      return;
    }
    final payload = valid ? (booking.safetyButtonId ?? '') : 'INVALID-BUTTON';
    unawaited(
      verifySafetyButton(ButtonVerification(method: method, payload: payload)),
    );
  }

  @override
  void simulateButtonPress() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.active) {
      return;
    }
    unawaited(
      reportIncident(
        IncidentReport(
          bookingId: booking.id,
          description: 'The physical safety button was pressed.',
          createdAt: DateTime.now(),
          fromPhysicalButton: true,
        ),
      ),
    );
  }

  @override
  void simulateSessionComplete() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.active) {
      return;
    }
    _finishBooking(
      booking
          .copyWith(status: BookingStatus.completed, outcome: SessionOutcome.completed)
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.completed,
              message: 'Session completed. Please rate your caregiver.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _scheduleMatching() {
    _cancelPending();
    _pendingTimer = Timer(matchingDelay, () {
      final booking = _activeBooking;
      if (booking == null || booking.status != BookingStatus.matching) {
        return;
      }
      if (!_nextRequestMatches || MockData.firstMatching(booking.genderFilter) == null) {
        unawaited(
          _setActiveBooking(
            booking.copyWith(status: BookingStatus.noMatch).withUpdate(
                  BookingUpdate(
                    status: BookingStatus.noMatch,
                    message: 'No caregiver is available for this filter right now.',
                    at: DateTime.now(),
                  ),
                ),
          ),
        );
        return;
      }
      final caregiver = _nextMatchingCaregiver(booking.genderFilter);
      unawaited(
        _setActiveBooking(
          booking.copyWith(status: BookingStatus.matched, caregiver: caregiver).withUpdate(
                BookingUpdate(
                  status: BookingStatus.matched,
                  message: 'Caregiver found. Review the price and pay to confirm.',
                  at: DateTime.now(),
                ),
              ),
        ),
      );
    });
  }

  void _scheduleCaregiverAccept() {
    _cancelPending();
    _pendingTimer = Timer(caregiverAcceptDelay, () {
      final booking = _activeBooking;
      if (booking == null || booking.status != BookingStatus.paidPending) {
        return;
      }
      _acceptBooking(booking);
    });
  }

  void _scheduleTravel() {
    _cancelPending();
    _pendingTimer = Timer(travelDelay, () {
      final booking = _activeBooking;
      if (booking == null || booking.status != BookingStatus.confirmed) {
        return;
      }
      _travelBooking(booking);
    });
  }

  void _scheduleArrival() {
    _cancelPending();
    _pendingTimer = Timer(arrivalDelay, () {
      final booking = _activeBooking;
      if (booking == null || booking.status != BookingStatus.caregiverTravelling) {
        return;
      }
      _arriveBooking(booking);
    });
  }

  void _scheduleCodeVerification() {
    _cancelPending();
    _pendingTimer = Timer(codeVerificationDelay, () {
      final booking = _activeBooking;
      if (booking == null || booking.status != BookingStatus.arrived) {
        return;
      }
      simulateCaregiverCodeVerification();
    });
  }

  void _acceptBooking(Booking booking) {
    unawaited(
      _setActiveBooking(
        booking
            .copyWith(status: BookingStatus.confirmed)
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.confirmed,
                message:
                    '${booking.caregiver?.firstName ?? 'Your caregiver'} accepted your request.',
                at: DateTime.now(),
              ),
            ),
      ),
    );
    if (_autoAdvance) {
      _scheduleTravel();
    }
  }

  void _travelBooking(Booking booking) {
    unawaited(
      _setActiveBooking(
        booking
            .copyWith(status: BookingStatus.caregiverTravelling)
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.caregiverTravelling,
                message: 'Your caregiver is on the way.',
                at: DateTime.now(),
              ),
            ),
      ),
    );
    if (_autoAdvance) {
      _scheduleArrival();
    }
  }

  void _arriveBooking(Booking booking) {
    unawaited(
      _setActiveBooking(
        booking
            .copyWith(status: BookingStatus.arrived)
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.arrived,
                message: 'Your caregiver has arrived. Show your client code.',
                at: DateTime.now(),
              ),
            ),
      ),
    );
    if (_autoAdvance) {
      _scheduleCodeVerification();
    }
  }

  Booking _failedVerification(Booking booking, String reason) {
    // A failed verification is refunded: no session ran. (FR-P-19)
    final refunded = _refunded(booking, partial: false);
    final refundNote =
        refunded.hasRefund ? ' ${formatIdr(refunded.refundAmount!)} refunded.' : '';
    return refunded
        .copyWith(
          status: BookingStatus.cancelled,
          cancellationReason: CancellationReason.failedVerification,
        )
        .withUpdate(
          BookingUpdate(
            status: BookingStatus.cancelled,
            message:
                '$reason The booking was cancelled and reported to support.$refundNote',
            at: DateTime.now(),
          ),
        );
  }

  /// Returns [booking] with a full or partial refund recorded when it was paid.
  /// (FR-P-13, FR-CS-16, FR-P-19, FR-P-23)
  Booking _refunded(Booking booking, {required bool partial}) {
    final price = booking.price;
    if (price == null || !booking.isPaid) {
      return booking;
    }
    return booking.copyWith(
      paymentStatus: partial
          ? PaymentStatus.partiallyRefunded
          : PaymentStatus.refunded,
      refundAmount:
          partial ? Pricing.earlyEndRefund(price) : price.total,
    );
  }

  Caregiver? _nextMatchingCaregiver(GenderFilter filter) {
    for (final caregiver in MockData.caregivers) {
      if (filter.matches(caregiver.gender) &&
          !_declinedCaregiverIds.contains(caregiver.id)) {
        return caregiver;
      }
    }
    return null;
  }

  Future<void> _setUser(CareSeeker user) async {
    _user = user;
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    _userController.add(user);
  }

  Future<void> _setActiveBooking(Booking booking) async {
    _activeBooking = booking;
    await _prefs.setString(_activeBookingKey, jsonEncode(booking.toJson()));
    _bookingController.add(booking);
  }

  void _finishBooking(Booking booking) {
    _cancelPending();
    _history.insert(0, booking);
    _activeBooking = null;
    unawaited(_prefs.remove(_activeBookingKey));
    _bookingController.add(null);
    _historyController.add(List<Booking>.unmodifiable(_history));
  }

  void _cancelPending() => _pendingTimer?.cancel();

  Future<void> _smallDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  String _reference() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final buffer = StringBuffer('REQ-');
    for (var i = 0; i < 4; i++) {
      buffer.write(letters[_random.nextInt(letters.length)]);
    }
    return buffer.toString();
  }

  String _clientCode() => '${_random.nextInt(900000) + 100000}';

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) {
      return 'Care seeker';
    }
    return local
        .split(RegExp(r'[._]'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
