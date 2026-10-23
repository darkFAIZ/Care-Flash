import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:care_domain/care_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A local, in-process stand-in for the shared platform, from the caregiver's
/// side.
///
/// Care-Flash and Care-Merchant are separate processes, so this mock simulates
/// the care seeker: it reviews identity submissions, delivers incoming requests
/// and reacts to the caregiver accepting or declining. It is the default
/// implementation behind [CaregiverRepository] and can be replaced by an HTTP
/// client later. (AGENTS.md §5)
class MockCaregiverPlatform implements CaregiverPlatform {
  MockCaregiverPlatform._(
    this._prefs,
    this._random,
    this.verificationReviewDelay,
    this.requestArrivalDelay,
    this.buttonScanDelay,
    this.feedbackDelay,
  );

  static const String _caregiverKey = 'care_core.mock.caregiver';
  static const String _activeBookingKey = 'care_core.mock.caregiver_booking';

  /// How long the simulated identity review takes. (FR-CM-3)
  final Duration verificationReviewDelay;

  /// How long after becoming eligible before a request arrives. (PR-CM-1)
  final Duration requestArrivalDelay;

  /// How long after the client code is verified before the simulated care
  /// seeker scans the safety button. (FR-CM-15)
  final Duration buttonScanDelay;

  /// How long after a session finishes before the simulated care seeker leaves
  /// feedback for the caregiver. (FR-CM-23)
  final Duration feedbackDelay;

  final SharedPreferences _prefs;
  final Random _random;

  final StreamController<CaregiverAccount?> _caregiverController =
      StreamController<CaregiverAccount?>.broadcast();
  final StreamController<Booking?> _offerController =
      StreamController<Booking?>.broadcast();
  final StreamController<Booking?> _bookingController =
      StreamController<Booking?>.broadcast();
  final StreamController<List<Booking>> _historyController =
      StreamController<List<Booking>>.broadcast();
  final StreamController<EarningsSummary> _earningsController =
      StreamController<EarningsSummary>.broadcast();
  final StreamController<List<FeedbackReceived>> _feedbackController =
      StreamController<List<FeedbackReceived>>.broadcast();
  final StreamController<List<CareSeekerRating>> _careSeekerRatingsController =
      StreamController<List<CareSeekerRating>>.broadcast();

  CaregiverAccount? _caregiver;
  Booking? _offer;
  Booking? _activeBooking;
  final List<Booking> _history = [];
  final List<Withdrawal> _withdrawals = [];
  final List<FeedbackReceived> _feedbackReceived = [];
  final List<CareSeekerRating> _careSeekerRatings = [];

  Timer? _verificationTimer;
  Timer? _responseTimer;
  Timer? _requestTimer;
  Timer? _buttonScanTimer;
  Timer? _feedbackTimer;

  bool _autoAdvance = true;
  bool _nextVerificationFails = false;

  /// Creates the mock platform, loading any persisted state.
  ///
  /// [verificationReviewDelay] and [requestArrivalDelay] are overridable so
  /// tests do not have to wait for the real (longer) demo delays.
  static Future<MockCaregiverPlatform> create({
    Random? random,
    Duration? verificationReviewDelay,
    Duration? requestArrivalDelay,
    Duration? buttonScanDelay,
    Duration? feedbackDelay,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final platform = MockCaregiverPlatform._(
      prefs,
      random ?? Random(),
      verificationReviewDelay ?? const Duration(seconds: 2),
      requestArrivalDelay ?? const Duration(seconds: 3),
      buttonScanDelay ?? const Duration(seconds: 2),
      feedbackDelay ?? const Duration(seconds: 4),
    );
    platform._restore();
    return platform;
  }

  void _restore() {
    final caregiverJson = _prefs.getString(_caregiverKey);
    if (caregiverJson != null) {
      _caregiver =
          CaregiverAccount.fromJson(jsonDecode(caregiverJson) as Map<String, Object?>);
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
    // Earnings and withdrawals are derived from the in-memory history, which is
    // not persisted yet, so they reset on restart just like the history does.
    // TODO(team): persist earnings and session history once the API is real.
  }

  /// Releases timers and streams. Call when the platform is no longer needed.
  void dispose() {
    _verificationTimer?.cancel();
    _responseTimer?.cancel();
    _requestTimer?.cancel();
    _buttonScanTimer?.cancel();
    _feedbackTimer?.cancel();
    _caregiverController.close();
    _offerController.close();
    _bookingController.close();
    _historyController.close();
    _earningsController.close();
    _feedbackController.close();
    _careSeekerRatingsController.close();
  }

  // ---------------------------------------------------------------------------
  // CaregiverRepository: account and onboarding
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
  }) async {
    await _smallDelay();
    if (name.trim().isEmpty || !email.contains('@') || password.length < 6) {
      return const CaregiverAuthResult.failure(
        'Enter a name, a valid email and a password of at least 6 characters.',
      );
    }
    final caregiver = CaregiverAccount(
      id: 'cg-${_random.nextInt(9000) + 1000}',
      name: name.trim(),
      email: email.trim(),
      gender: gender,
      // A brand new account has not been reviewed yet. (FR-CM-2)
      verificationStatus: VerificationStatus.notSubmitted,
      safetyModuleCompleted: false,
    );
    await _setCaregiver(caregiver);
    return CaregiverAuthResult.success(caregiver);
  }

  @override
  Future<CaregiverAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await _smallDelay();
    if (!email.contains('@') || password.length < 6) {
      return const CaregiverAuthResult.failure(
        'Enter a valid email and a password of at least 6 characters.',
      );
    }
    // A returning caregiver is already verified and badged, so the demo can go
    // straight to requests. Sign up instead to walk through onboarding.
    final caregiver = CaregiverAccount(
      id: 'cg-demo',
      name: _nameFromEmail(email),
      email: email.trim(),
      gender: Gender.male,
      rating: 4.8,
      reviewCount: 96,
      verificationStatus: VerificationStatus.approved,
      safetyModuleCompleted: true,
    );
    await _setCaregiver(caregiver);
    return CaregiverAuthResult.success(caregiver);
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_caregiverKey);
    await _prefs.remove(_activeBookingKey);
    _caregiver = null;
    _offer = null;
    _activeBooking = null;
    _requestTimer?.cancel();
    _responseTimer?.cancel();
    _caregiverController.add(null);
    _offerController.add(null);
    _bookingController.add(null);
  }

  @override
  Future<void> updateProfile({required String name}) async {
    final caregiver = _caregiver;
    if (caregiver == null) {
      return;
    }
    await _setCaregiver(caregiver.copyWith(name: name));
  }

  @override
  Future<void> updateAvatar({String? avatarDataUrl}) async {
    final caregiver = _caregiver;
    if (caregiver == null) {
      return;
    }
    await _setCaregiver(caregiver.copyWith(avatarDataUrl: avatarDataUrl));
  }

  @override
  Future<void> submitVerification({
    required String ktpNumber,
    required String documentLabel,
  }) async {
    final caregiver = _caregiver;
    if (caregiver == null) {
      return;
    }
    await _setCaregiver(
      caregiver.copyWith(
        verificationStatus: VerificationStatus.pending,
        rejectionReason: null,
        ktpNumber: ktpNumber.trim(),
        ktpDocumentLabel: documentLabel,
        verificationSubmittedAt: DateTime.now(),
      ),
    );
    _scheduleVerificationReview();
  }

  @override
  Future<void> completeSafetyModule() async {
    final caregiver = _caregiver;
    if (caregiver == null || caregiver.safetyModuleCompleted) {
      return;
    }
    await _setCaregiver(caregiver.copyWith(safetyModuleCompleted: true));
    _maybeScheduleRequest();
  }

  @override
  Future<void> updateGender(Gender gender) async {
    final caregiver = _caregiver;
    if (caregiver == null) {
      return;
    }
    await _setCaregiver(caregiver.copyWith(gender: gender));
  }

  @override
  Future<void> updateAvailability(CaregiverAvailability availability) async {
    final caregiver = _caregiver;
    if (caregiver == null) {
      return;
    }
    await _setCaregiver(caregiver.copyWith(availability: availability));
    _maybeScheduleRequest();
  }

  // ---------------------------------------------------------------------------
  // CaregiverRepository: requests and bookings
  // ---------------------------------------------------------------------------

  /// The booking this caregiver has accepted, or null.
  Booking? get activeBooking => _activeBooking;

  @override
  Stream<Booking?> watchIncomingRequest() async* {
    yield _offer;
    yield* _offerController.stream;
  }

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
  Future<void> acceptRequest() async {
    final offer = _offer;
    final caregiver = _caregiver;
    if (offer == null || caregiver == null) {
      return;
    }
    _responseTimer?.cancel();
    _offer = null;
    _offerController.add(null);
    // Acceptance discloses the destination to the caregiver. (FR-CM-10)
    final accepted = offer
        .copyWith(
          caregiver: caregiver.toPublic(),
          status: BookingStatus.confirmed,
          // The care seeker's client code now exists; it is only shown to the
          // caregiver when the care seeker presents it on arrival. (FR-CM-13)
          clientCode: _clientCode(),
        )
        .withUpdate(
          BookingUpdate(
            status: BookingStatus.confirmed,
            message: 'You accepted the request. Head to the care seeker.',
            at: DateTime.now(),
          ),
        );
    await _setActiveBooking(accepted);
  }

  @override
  Future<void> declineRequest() async {
    // Declining has no rating penalty. (FR-CM-9)
    _clearOffer();
  }

  @override
  Future<void> reportDanger(String description) async {
    final booking = _activeBooking;
    if (booking == null) {
      return;
    }
    // The booking is cancelled and support is notified. (FR-CM-11)
    _finishBooking(
      booking
          .copyWith(
            status: BookingStatus.cancelled,
            cancellationReason: CancellationReason.preSessionDanger,
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.cancelled,
              message:
                  'Your safety report was sent to support. The booking was cancelled and you will not be paid.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // CaregiverRepository: travel, handover and session
  // ---------------------------------------------------------------------------

  @override
  Future<void> startTrip() async {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.confirmed) {
      return;
    }
    await _smallDelay();
    await _setActiveBooking(
      booking
          .copyWith(status: BookingStatus.caregiverTravelling)
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.caregiverTravelling,
              // TODO(team): the real app asks the care seeker's mock Grab ride
              // for pickup tracking instead of just a status line. (FR-CM-10)
              message: 'You are on the way to the care seeker.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<void> markArrived() async {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.caregiverTravelling) {
      return;
    }
    await _smallDelay();
    await _setActiveBooking(
      booking
          .copyWith(status: BookingStatus.arrived)
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.arrived,
              message: 'You arrived. Ask the care seeker for their client code.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<ButtonVerificationResult> verifyClientCode(String code) async {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.arrived) {
      return const ButtonVerificationResult.failed(
        'This booking is not ready for the client code yet.',
      );
    }
    await _smallDelay();
    if (booking.clientCode == null || code.trim() != booking.clientCode) {
      // A wrong code cancels the booking and notifies support. (FR-CM-14)
      _finishBooking(
        booking
            .copyWith(
              status: BookingStatus.cancelled,
              cancellationReason: CancellationReason.failedVerification,
            )
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.cancelled,
                message:
                    'The client code did not match. The booking was cancelled and support was notified.',
                at: DateTime.now(),
              ),
            ),
      );
      return const ButtonVerificationResult.failed(
        'The client code did not match. The booking was cancelled.',
      );
    }
    // After a valid client code the caregiver app generates the booking-linked
    // safety-button code. The CARE SEEKER verifies it by scanning; the caregiver
    // can never confirm it. (FR-CM-15, FR-P-17, FR-P-18)
    await _setActiveBooking(
      booking
          .copyWith(
            status: BookingStatus.codeVerified,
            buttonCode: ButtonCode.generate(bookingId: booking.id),
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.codeVerified,
              message:
                  'Client code verified. Hand over the safety button and ask the care seeker to scan it.',
              at: DateTime.now(),
            ),
          ),
    );
    if (_autoAdvance) {
      _scheduleButtonScan();
    }
    return const ButtonVerificationResult.success();
  }

  @override
  Future<void> completeSession() async {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.active) {
      return;
    }
    await _smallDelay();
    // Normal completion releases the caregiver service earnings. (FR-P-21)
    final price = booking.price;
    _finishBooking(
      booking
          .copyWith(
            status: BookingStatus.completed,
            outcome: SessionOutcome.completed,
            caregiverPayout:
                price == null ? 0 : Pricing.caregiverEarnings(price),
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.completed,
              message: 'Work marked complete. The care seeker will be notified.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<void> sos(String description) async {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.active) {
      return;
    }
    await _smallDelay();
    // The session ends and the compensation policy applies. (FR-CM-19, FR-P-24)
    final price = booking.price;
    _finishBooking(
      booking
          .copyWith(
            status: BookingStatus.caregiverSos,
            outcome: SessionOutcome.caregiverSos,
            caregiverPayout:
                price == null ? 0 : Pricing.sosCompensation(price),
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.caregiverSos,
              message:
                  'SOS sent. The care seeker\'s contacts and support were alerted. Your compensation was applied.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  Future<void> reportCareSeeker(IncidentReport report) async {
    final booking = _activeBooking;
    await _smallDelay();
    if (booking == null) {
      // Reported after the session ended; the platform still records it.
      return;
    }
    // Reporting during a session ends it. (FR-CM-20)
    // TODO(team): decide the caregiver's pay when they report the care seeker;
    // no compensation is credited for now. (SRS open decision 5)
    _finishBooking(
      booking
          .copyWith(
            status: BookingStatus.reported,
            outcome: SessionOutcome.careSeekerReported,
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.reported,
              message:
                  'Your report was sent to support with your evidence. The session ended.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // CaregiverRepository: earnings and withdrawal
  // ---------------------------------------------------------------------------

  @override
  Stream<EarningsSummary> watchEarnings() async* {
    yield _buildEarnings();
    yield* _earningsController.stream;
  }

  @override
  Future<WithdrawalResult> requestWithdrawal(int amount) async {
    await _smallDelay();
    if (amount <= 0) {
      return const WithdrawalResult.failed('Enter an amount to withdraw.');
    }
    if (amount < PlatformPolicy.minimumWithdrawal) {
      return WithdrawalResult.failed(
        'The minimum withdrawal is '
        '${formatIdr(PlatformPolicy.minimumWithdrawal)}.',
      );
    }
    final available = _buildEarnings().availableBalance;
    if (amount > available) {
      return WithdrawalResult.failed(
        'You can withdraw up to ${formatIdr(available)} right now.',
      );
    }
    final withdrawal = Withdrawal(
      id: 'wd-${_random.nextInt(9000) + 1000}',
      amount: amount,
      method: PlatformPolicy.payoutMethods.first,
      status: PayoutStatus.processing,
      requestedAt: DateTime.now(),
    );
    _withdrawals.insert(0, withdrawal);
    _emitEarnings();
    return WithdrawalResult.succeeded(amount);
  }

  /// Builds the earnings picture from finished bookings, the running session
  /// and the withdrawal history. (FR-CM-21, FR-P-29)
  EarningsSummary _buildEarnings() {
    final entries = <EarningEntry>[];
    for (final booking in _history) {
      final payout = booking.caregiverPayout ?? 0;
      if (payout <= 0) {
        continue;
      }
      final kind = switch (booking.outcome) {
        SessionOutcome.completed => EarningKind.session,
        SessionOutcome.endedEarly => EarningKind.earlyEndCompensation,
        SessionOutcome.caregiverSos => EarningKind.sosCompensation,
        // A care seeker report does not credit the caregiver. (FR-P-24)
        SessionOutcome.careSeekerReported => null,
        null => null,
      };
      if (kind == null) {
        continue;
      }
      entries.add(
        EarningEntry(
          id: 'ern-${booking.id}',
          bookingId: booking.id,
          reference: booking.requestReference,
          kind: kind,
          amount: payout,
          // The booking finishing time is the newest status update.
          at: booking.updates.isEmpty
              ? booking.createdAt
              : booking.updates.last.at,
        ),
      );
    }

    final active = _activeBooking;
    final pending = active != null &&
            active.status == BookingStatus.active &&
            active.price != null
        ? Pricing.caregiverEarnings(active.price!)
        : 0;

    return EarningsSummary(
      earnings: List<EarningEntry>.unmodifiable(entries),
      withdrawals: List<Withdrawal>.unmodifiable(_withdrawals),
      pendingBalance: pending,
    );
  }

  void _emitEarnings() => _earningsController.add(_buildEarnings());

  // ---------------------------------------------------------------------------
  // CaregiverRepository: feedback and care-seeker ratings
  // ---------------------------------------------------------------------------

  @override
  Stream<List<FeedbackReceived>> watchFeedbackReceived() async* {
    yield List<FeedbackReceived>.unmodifiable(_feedbackReceived);
    yield* _feedbackController.stream;
  }

  @override
  Stream<List<CareSeekerRating>> watchCareSeekerRatings() async* {
    yield List<CareSeekerRating>.unmodifiable(_careSeekerRatings);
    yield* _careSeekerRatingsController.stream;
  }

  @override
  Future<void> rateCareSeeker(CareSeekerRating rating) async {
    await _smallDelay();
    _careSeekerRatings.insert(0, rating);
    _careSeekerRatingsController
        .add(List<CareSeekerRating>.unmodifiable(_careSeekerRatings));
  }

  /// Simulates the care seeker leaving feedback for the caregiver shortly after
  /// a visit ends. The two apps are separate processes, so this stands in for
  /// the feedback Care-Flash would post. (FR-CM-23, FR-P-27)
  void _scheduleSimulatedFeedback(Booking booking) {
    final outcome = booking.outcome;
    // Only a visit that actually ran earns feedback. (FR-CS-19)
    if (outcome != SessionOutcome.completed &&
        outcome != SessionOutcome.endedEarly) {
      return;
    }
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(feedbackDelay, () {
      _feedbackReceived.insert(
        0,
        FeedbackReceived(
          bookingId: booking.id,
          reference: booking.requestReference,
          stars: _feedbackStars[_random.nextInt(_feedbackStars.length)],
          comment: _feedbackComments[_random.nextInt(_feedbackComments.length)],
          receivedAt: DateTime.now(),
        ),
      );
      _feedbackController
          .add(List<FeedbackReceived>.unmodifiable(_feedbackReceived));
    });
  }

  static const List<int> _feedbackStars = [5, 5, 4, 4, 3];

  static const List<String> _feedbackComments = [
    'Very careful and kind. Helped me get water and rest.',
    'On time and polite. I felt safer having them here.',
    'Picked up my medicine exactly as asked. Recommended.',
    'Good company and respectful of my boundaries.',
  ];

  // ---------------------------------------------------------------------------
  // CaregiverDemoControls
  // ---------------------------------------------------------------------------

  @override
  void setAutoAdvance(bool enabled) {
    _autoAdvance = enabled;
    if (!enabled) {
      _requestTimer?.cancel();
    } else {
      _maybeScheduleRequest();
    }
  }

  @override
  void setNextVerificationFails(bool fails) => _nextVerificationFails = fails;

  @override
  void simulateIncomingRequest() => _deliverRequest();

  @override
  void simulateCareSeekerCancel() {
    final booking = _activeBooking;
    if (booking == null) {
      return;
    }
    _finishBooking(
      booking
          .copyWith(
            status: BookingStatus.cancelled,
            cancellationReason: CancellationReason.userCancelled,
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.cancelled,
              message: 'The care seeker cancelled this booking.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  @override
  void simulateCareSeekerButtonScan({
    ButtonVerificationMethod method = ButtonVerificationMethod.qr,
    bool valid = true,
  }) {
    final booking = _activeBooking;
    if (booking == null) {
      return;
    }
    // The button can only be verified after the client code. (FR-CM-13, FR-CM-15)
    if (booking.status != BookingStatus.codeVerified) {
      return;
    }
    _buttonScanTimer?.cancel();
    // This simulates the CARE SEEKER scanning the button. The platform applies
    // the same single-use, nonce and expiry rules as a real scan; the caregiver
    // app never confirms the button by itself. (FR-P-18)
    final payload = valid ? (booking.safetyButtonId ?? '') : 'INVALID-BUTTON';
    final failure = booking.validateButtonPayload(payload);
    if (failure != null) {
      _finishBooking(
        booking
            .copyWith(
              status: BookingStatus.cancelled,
              cancellationReason: CancellationReason.failedVerification,
            )
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.cancelled,
                message:
                    '${failure.label} The booking was cancelled and support was notified.',
                at: DateTime.now(),
              ),
            ),
      );
      return;
    }
    unawaited(
      _setActiveBooking(
        booking
            .copyWith(
              status: BookingStatus.active,
              buttonCode: booking.buttonCode!.markUsed(DateTime.now()),
            )
            .withUpdate(
              BookingUpdate(
                status: BookingStatus.active,
                message: 'The safety button was verified. The session started.',
                at: DateTime.now(),
              ),
            ),
      ),
    );
  }

  @override
  void simulateCareSeekerEndEarly() {
    final booking = _activeBooking;
    if (booking == null || booking.status != BookingStatus.active) {
      return;
    }
    // The care seeker stops the session; the caregiver is compensated. (FR-P-22)
    final price = booking.price;
    _finishBooking(
      booking
          .copyWith(
            status: BookingStatus.endedEarly,
            outcome: SessionOutcome.endedEarly,
            caregiverPayout:
                price == null ? 0 : Pricing.earlyEndCompensation(price),
          )
          .withUpdate(
            BookingUpdate(
              status: BookingStatus.endedEarly,
              message:
                  'The care seeker ended the session early. Your compensation was applied.',
              at: DateTime.now(),
            ),
          ),
    );
  }

  /// Debug-only: the client code the care seeker is currently presenting, so
  /// the demo can be driven without a second device. (FR-CM-13)
  @override
  String? get debugClientCode => _activeBooking?.clientCode;

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Simulates the care seeker scanning the safety button after the client code
  /// is verified, so the demo can run on one device. (FR-CM-15, FR-CM-16)
  void _scheduleButtonScan() {
    _buttonScanTimer?.cancel();
    _buttonScanTimer = Timer(buttonScanDelay, () {
      if (_activeBooking?.status != BookingStatus.codeVerified) {
        return;
      }
      simulateCareSeekerButtonScan();
    });
  }

  String _clientCode() =>
      (_random.nextInt(900000) + 100000).toString();

  void _scheduleVerificationReview() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer(verificationReviewDelay, () {
      final caregiver = _caregiver;
      if (caregiver == null ||
          caregiver.verificationStatus != VerificationStatus.pending) {
        return;
      }
      if (_nextVerificationFails) {
        _nextVerificationFails = false;
        unawaited(
          _setCaregiver(
            caregiver.copyWith(
              verificationStatus: VerificationStatus.rejected,
              // TODO(team): the exact rejection wording is up to the review
              // team. (FR-CM-3)
              rejectionReason:
                  'The KTP photo is blurry. Please upload a clearer photo and try again.',
            ),
          ),
        );
        return;
      }
      unawaited(
        _setCaregiver(
          caregiver.copyWith(verificationStatus: VerificationStatus.approved),
        ),
      );
      _maybeScheduleRequest();
    });
  }

  void _maybeScheduleRequest() {
    _requestTimer?.cancel();
    if (!_autoAdvance || _caregiver == null) {
      return;
    }
    if (!_caregiver!.canReceiveRequests) {
      return;
    }
    if (_offer != null || _activeBooking != null) {
      return;
    }
    _requestTimer = Timer(requestArrivalDelay, () {
      if (_caregiver == null || !_caregiver!.canReceiveRequests) {
        return;
      }
      if (_offer != null || _activeBooking != null) {
        return;
      }
      _deliverRequest();
    });
  }

  void _deliverRequest() {
    final caregiver = _caregiver;
    if (caregiver == null) {
      return;
    }
    if (_offer != null || _activeBooking != null) {
      return;
    }
    if (!caregiver.canReceiveRequests) {
      return;
    }
    final booking = _buildOfferedBooking(caregiver);
    _offer = booking;
    _offerController.add(booking);
    _startResponseWindow();
  }

  void _startResponseWindow() {
    _responseTimer?.cancel();
    _responseTimer = Timer(PlatformPolicy.caregiverResponseTimeout, () {
      // The request is offered elsewhere once the window lapses. (FR-CM-9)
      if (_offer == null) {
        return;
      }
      _clearOffer();
    });
  }

  void _clearOffer() {
    _responseTimer?.cancel();
    _offer = null;
    _offerController.add(null);
  }

  /// Builds a request as the care seeker would have submitted it.
  ///
  /// The caregiver is offered it, but the destination and client code are only
  /// needed after acceptance, so they are withheld here. (FR-CM-8, DC-CM-2)
  Booking _buildOfferedBooking(CaregiverAccount caregiver) {
    final now = DateTime.now();
    final duration = VisitDuration.values[_random.nextInt(VisitDuration.values.length)];
    final price = Pricing.breakdown(duration);
    final helpType = HelpType.values[_random.nextInt(HelpType.values.length)];
    return Booking(
      id: 'bk-${_random.nextInt(90000) + 10000}',
      requestReference: _reference(),
      helpType: helpType,
      description: _descriptions[_random.nextInt(_descriptions.length)],
      checklist: BoundaryChecklist.suggested,
      location: VisitLocation
          .mockPresets[_random.nextInt(VisitLocation.mockPresets.length)],
      scheduledAt: now.add(const Duration(minutes: 15)),
      duration: duration,
      genderFilter: GenderFilter.both,
      caregiver: caregiver.toPublic(),
      price: price,
      // The care seeker pays the Grab fare; it is recorded here for the model
      // but it is never part of the caregiver's pay. (FR-P-10, FR-P-11)
      estimatedGrabFare: price.grabFare,
      status: BookingStatus.paidPending,
      createdAt: now,
      updates: [
        BookingUpdate(
          status: BookingStatus.paidPending,
          message: 'A care seeker requested help. Respond within 60 seconds.',
          at: now,
        ),
      ],
    );
  }

  static const List<String> _descriptions = [
    'I have a fever and need someone to help me get water and rest.',
    'Please pick up my prescription from the pharmacy nearby.',
    'I feel unsafe walking back to my boarding house alone.',
    'I just need company and someone to talk to for a while.',
  ];

  Future<void> _setCaregiver(CaregiverAccount caregiver) async {
    _caregiver = caregiver;
    await _prefs.setString(_caregiverKey, jsonEncode(caregiver.toJson()));
    _caregiverController.add(caregiver);
    _maybeScheduleRequest();
  }

  Future<void> _setActiveBooking(Booking booking) async {
    _activeBooking = booking;
    await _prefs.setString(_activeBookingKey, jsonEncode(booking.toJson()));
    _bookingController.add(booking);
    _emitEarnings();
  }

  void _finishBooking(Booking booking) {
    _responseTimer?.cancel();
    _requestTimer?.cancel();
    _buttonScanTimer?.cancel();
    _history.insert(0, booking);
    _activeBooking = null;
    unawaited(_prefs.remove(_activeBookingKey));
    _bookingController.add(null);
    _historyController.add(List<Booking>.unmodifiable(_history));
    _emitEarnings();
    // The care seeker leaves feedback a little later, as they would in the
    // real two-app flow. (FR-CM-23)
    _scheduleSimulatedFeedback(booking);
    // Offer another request once the caregiver is free again.
    _maybeScheduleRequest();
  }

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

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) {
      return 'Caregiver';
    }
    return local
        .split(RegExp(r'[._]'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
