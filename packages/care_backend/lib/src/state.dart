import 'dart:convert';
import 'dart:math';

import 'package:care_domain/care_domain.dart';
import 'package:crypto/crypto.dart';

/// A stored password: the salt is public, only the hash is compared.
class _Credential {
  const _Credential({required this.salt, required this.hash});

  factory _Credential.fromJson(Map<String, Object?> json) => _Credential(
        salt: json['salt']! as String,
        hash: json['hash']! as String,
      );

  final String salt;
  final String hash;

  Map<String, Object?> toJson() => {'salt': salt, 'hash': hash};
}

/// A signed-in session. The app keeps the token, the server keeps the rest.
class _Session {
  const _Session({
    required this.role,
    required this.userId,
    required this.expiresAt,
  });

  final String role;
  final String userId;
  final DateTime expiresAt;
}

/// The single source of truth for the Care-Flash demo backend.
///
/// One instance is shared by both apps. A care-seeker action (for example
/// submitting a request) and a caregiver action (accepting it) both mutate the
/// same [Booking] records, so a change made in one app is visible to the other.
/// This replaces the per-app mocks that used to simulate the other side.
/// (AGENTS.md §5)
class CareBackendState {
  CareBackendState({
    Random? random,
    DateTime Function()? clock,
    this.sessionTtl = const Duration(days: 30),
  })  : _random = random ?? Random.secure(),
        _clock = clock ?? DateTime.now;

  /// Restores a state saved with [toJson] (for example after a restart).
  factory CareBackendState.fromJson(
    Map<String, Object?> json, {
    Random? random,
    DateTime Function()? clock,
    Duration sessionTtl = const Duration(days: 30),
  }) {
    final state = CareBackendState(
      random: random,
      clock: clock,
      sessionTtl: sessionTtl,
    );
    state._seq = json['seq'] as int? ?? 0;
    for (final raw in (json['seekers'] as List<Object?>? ?? const [])) {
      final seeker = CareSeeker.fromJson(raw! as Map<String, Object?>);
      state._seekers[seeker.id] = seeker;
    }
    for (final raw in (json['caregivers'] as List<Object?>? ?? const [])) {
      final caregiver = CaregiverAccount.fromJson(raw! as Map<String, Object?>);
      state._caregivers[caregiver.id] = caregiver;
    }
    for (final entry in (json['seekerCredentials'] as Map<String, Object?>? ?? const {}).entries) {
      state._seekerCredentials[entry.key] =
          _Credential.fromJson(entry.value! as Map<String, Object?>);
    }
    for (final entry
        in (json['caregiverCredentials'] as Map<String, Object?>? ?? const {}).entries) {
      state._caregiverCredentials[entry.key] =
          _Credential.fromJson(entry.value! as Map<String, Object?>);
    }
    final now = state._clock();
    for (final raw in (json['sessions'] as List<Object?>? ?? const [])) {
      final session = raw! as Map<String, Object?>;
      final expiresAt = DateTime.parse(session['expiresAt']! as String);
      if (!expiresAt.isAfter(now)) continue;
      state._sessions[session['token']! as String] = _Session(
        role: session['role']! as String,
        userId: session['userId']! as String,
        expiresAt: expiresAt,
      );
    }
    return state;
  }

  final Random _random;
  final DateTime Function() _clock;

  /// How long an issued token stays valid. TODO(team): agree on a real value
  /// before production; 30 days is a demo default.
  final Duration sessionTtl;

  int _seq = 0;

  /// Passwords are never stored in plain text. The key is the account email.
  final Map<String, _Credential> _seekerCredentials = {};
  final Map<String, _Credential> _caregiverCredentials = {};

  /// Issued tokens, so an app can stay signed in across restarts.
  final Map<String, _Session> _sessions = {};

  final Map<String, CareSeeker> _seekers = {};
  final Map<String, CaregiverAccount> _caregivers = {};
  final List<Booking> _bookings = [];

  /// Ownership of a booking, since [Booking] itself carries no seeker id.
  final Map<String, String> _bookingSeeker = {};

  // Per-caregiver ledgers.
  final Map<String, List<EarningEntry>> _earnings = {};
  final Map<String, List<Withdrawal>> _withdrawals = {};
  final Map<String, List<FeedbackReceived>> _feedbackReceived = {};
  final Map<String, List<CareSeekerRating>> _careSeekerRatings = {};

  // Per-seeker ledgers.
  final Map<String, List<CaregiverRating>> _caregiverRatings = {};
  final List<AppFeedback> _appFeedback = [];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _newId(String prefix) => '$prefix-${_seq++}-${_random.nextInt(9999)}';

  String _reference() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  String _clientCode() => List.generate(6, (_) => _random.nextInt(10)).join();

  String _salt() =>
      base64UrlEncode(List<int>.generate(16, (_) => _random.nextInt(256)));

  /// A salted, stretched SHA-256 hash. Not a substitute for a real password
  /// hashing library (argon2/bcrypt), but it keeps plain passwords out of the
  /// data file and is enough for the demo. (Reviewer item 5)
  String _hashPassword(String password, String salt) {
    var digest = sha256.convert(utf8.encode('$salt:$password'));
    for (var i = 0; i < 4096; i++) {
      digest = sha256.convert([...digest.bytes, ...utf8.encode(salt)]);
    }
    return digest.toString();
  }

  _Credential _newCredential(String password) {
    final salt = _salt();
    return _Credential(salt: salt, hash: _hashPassword(password, salt));
  }

  bool _passwordMatches(_Credential? credential, String password) =>
      credential != null && credential.hash == _hashPassword(password, credential.salt);

  String _issueToken(String role, String userId) {
    final token = base64UrlEncode(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    ).replaceAll('=', '');
    _sessions[token] = _Session(
      role: role,
      userId: userId,
      expiresAt: _clock().add(sessionTtl),
    );
    return token;
  }

  /// Returns `{role, user}` for a valid token, or null when it is unknown or
  /// expired. The server uses this to restore a connection after a restart.
  Map<String, Object?>? resumeSession(String token) {
    final session = _sessions[token];
    if (session == null) return null;
    if (!session.expiresAt.isAfter(_clock())) {
      _sessions.remove(token);
      return null;
    }
    if (session.role == 'caregiver') {
      final caregiver = _caregivers[session.userId];
      if (caregiver == null) return null;
      return {'role': 'caregiver', 'user': caregiver.toJson()};
    }
    final seeker = _seekers[session.userId];
    if (seeker == null) return null;
    return {'role': 'seeker', 'user': seeker.toJson()};
  }

  /// Revokes one token. Signing out on one device does not sign out others.
  void signOut(String token) => _sessions.remove(token);

  Booking _requireBooking(String id) {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    throw StateError('Booking not found: $id');
  }

  void _replaceBooking(Booking updated) {
    final i = _bookings.indexWhere((b) => b.id == updated.id);
    if (i >= 0) _bookings[i] = updated;
  }

  /// Returns [booking] with the refund for [reason] recorded when it was paid.
  ///
  /// The amount comes from [RefundPolicy] so the backend and the app mocks
  /// always agree. The care seeker paid the whole total up front, including the
  /// Grab fare. (FR-P-13, FR-P-19, FR-P-22, FR-P-23)
  Booking _refunded(Booking booking, RefundReason reason) {
    if (booking.price == null || !booking.isPaid) return booking;
    return booking.copyWith(
      paymentStatus: RefundPolicy.isFullRefund(reason)
          ? PaymentStatus.refunded
          : PaymentStatus.partiallyRefunded,
      refundAmount: RefundPolicy.refundFor(booking, reason),
    );
  }

  /// Maps a cancellation to the refund rule that applies to it.
  RefundReason _refundReasonFor(CancellationReason reason) => switch (reason) {
        CancellationReason.failedVerification => RefundReason.failedVerification,
        CancellationReason.preSessionDanger => RefundReason.dangerBeforeSession,
        // Nothing was used and no ride was booked: the whole total is returned,
        // Grab fare included. (FR-P-13)
        _ => RefundReason.noCaregiverAccepts,
      };

  CareSeeker _requireSeeker(String id) {
    final s = _seekers[id];
    if (s == null) throw StateError('Care seeker not found: $id');
    return s;
  }

  CaregiverAccount _requireCaregiver(String id) {
    final c = _caregivers[id];
    if (c == null) throw StateError('Caregiver not found: $id');
    return c;
  }

  Booking _openSeekerBooking(String seekerId) {
    for (var i = _bookings.length - 1; i >= 0; i--) {
      final b = _bookings[i];
      if (_bookingSeeker[b.id] == seekerId && b.status.isOpen) return b;
    }
    throw StateError('No open booking for this care seeker.');
  }

  /// The booking a caregiver has been offered (paid, awaiting acceptance), or
  /// the one they already accepted, whichever applies.
  Booking? _caregiverOffer(String caregiverId) {
    for (var i = _bookings.length - 1; i >= 0; i--) {
      final b = _bookings[i];
      if (b.caregiver?.id == caregiverId && b.status == BookingStatus.paidPending) {
        return b;
      }
    }
    return null;
  }

  Booking? _caregiverActive(String caregiverId) {
    for (var i = _bookings.length - 1; i >= 0; i--) {
      final b = _bookings[i];
      if (b.caregiver?.id == caregiverId &&
          b.status.isOpen &&
          b.status != BookingStatus.paidPending &&
          b.status != BookingStatus.matched &&
          b.status != BookingStatus.matching) {
        return b;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Care seeker: auth
  // ---------------------------------------------------------------------------

  Map<String, Object?> seekerSignUp({
    required String name,
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || !email.contains('@')) {
      return _authFail('Enter a valid email address.');
    }
    if (password.length < 6) {
      return _authFail('Password must be at least 6 characters.');
    }
    final trimmedEmail = email.trim();
    if (_seekers.values.any((s) => s.email == trimmedEmail)) {
      return _authFail('An account with that email already exists.');
    }
    final seeker = CareSeeker(id: _newId('cs'), name: name.trim(), email: trimmedEmail);
    _seekers[seeker.id] = seeker;
    _seekerCredentials[trimmedEmail] = _newCredential(password);
    return _authOk(seeker);
  }

  Map<String, Object?> seekerSignIn({required String email, required String password}) {
    final trimmedEmail = email.trim();
    for (final s in _seekers.values) {
      if (s.email == trimmedEmail && _passwordMatches(_seekerCredentials[trimmedEmail], password)) {
        return _authOk(s);
      }
    }
    return _authFail('Wrong email or password.');
  }

  Map<String, Object?> _authOk(CareSeeker s) => {
        'success': true,
        'user': s.toJson(),
        'error': null,
        'token': _issueToken('seeker', s.id),
      };
  Map<String, Object?> _authFail(String m) =>
      {'success': false, 'user': null, 'error': m};

  /// Updates the care seeker's profile details (Phase 5).
  void updateSeekerProfile(String seekerId, {required String name}) {
    if (name.trim().isEmpty) {
      throw StateError('Name cannot be empty.');
    }
    final s = _requireSeeker(seekerId);
    _seekers[seekerId] = s.copyWith(name: name.trim());
  }

  /// Sets or clears the care seeker's profile photo (null removes it).
  void updateSeekerAvatar(String seekerId, {String? avatarDataUrl}) {
    final s = _requireSeeker(seekerId);
    _seekers[seekerId] = s.copyWith(avatarDataUrl: avatarDataUrl);
  }

  // ---------------------------------------------------------------------------
  // Caregiver: auth + onboarding
  // ---------------------------------------------------------------------------

  Map<String, Object?> caregiverSignUp({
    required String name,
    required String email,
    required String password,
    required Gender gender,
  }) {
    if (email.trim().isEmpty || !email.contains('@')) {
      return _caregiverAuthFail('Enter a valid email address.');
    }
    if (password.length < 6) {
      return _caregiverAuthFail('Password must be at least 6 characters.');
    }
    final trimmedEmail = email.trim();
    if (_caregivers.values.any((c) => c.email == trimmedEmail)) {
      return _caregiverAuthFail('An account with that email already exists.');
    }
    final caregiver = CaregiverAccount(
      id: _newId('cg'),
      name: name.trim(),
      email: trimmedEmail,
      gender: gender,
      // New accounts start unsubmitted so the app routes into the onboarding
      // form. (FR-CM-2)
      verificationStatus: VerificationStatus.notSubmitted,
    );
    _caregivers[caregiver.id] = caregiver;
    _caregiverCredentials[trimmedEmail] = _newCredential(password);
    return _caregiverAuthOk(caregiver);
  }

  Map<String, Object?> caregiverSignIn({required String email, required String password}) {
    final trimmedEmail = email.trim();
    for (final c in _caregivers.values) {
      if (c.email == trimmedEmail &&
          _passwordMatches(_caregiverCredentials[trimmedEmail], password)) {
        return _caregiverAuthOk(c);
      }
    }
    return _caregiverAuthFail('Wrong email or password.');
  }

  Map<String, Object?> _caregiverAuthOk(CaregiverAccount c) => {
        'success': true,
        'user': c.toJson(),
        'error': null,
        'token': _issueToken('caregiver', c.id),
      };
  Map<String, Object?> _caregiverAuthFail(String m) =>
      {'success': false, 'user': null, 'error': m};

  void submitVerification(
    String caregiverId, {
    required String ktpNumber,
    required String documentLabel,
  }) {
    final c = _requireCaregiver(caregiverId);
    if (!RegExp(r'^\d{16}$').hasMatch(ktpNumber.trim())) {
      throw StateError('A KTP number must be 16 digits.');
    }
    _caregivers[c.id] = c.copyWith(
      ktpNumber: ktpNumber.trim(),
      ktpDocumentLabel: documentLabel,
      verificationSubmittedAt: DateTime.now(),
      verificationStatus: VerificationStatus.approved,
      rejectionReason: null,
    );
  }

  void completeSafetyModule(String caregiverId) {
    final c = _requireCaregiver(caregiverId);
    _caregivers[c.id] = c.copyWith(safetyModuleCompleted: true);
  }

  void updateGender(String caregiverId, Gender gender) {
    final c = _requireCaregiver(caregiverId);
    _caregivers[caregiverId] = c.copyWith(gender: gender);
  }

  void updateAvailability(String caregiverId, CaregiverAvailability availability) {
    final c = _requireCaregiver(caregiverId);
    _caregivers[caregiverId] = c.copyWith(availability: availability);
  }

  /// Updates the caregiver's profile details; gender uses [updateGender].
  /// (Phase 5)
  void updateCaregiverProfile(String caregiverId, {required String name}) {
    if (name.trim().isEmpty) {
      throw StateError('Name cannot be empty.');
    }
    final c = _requireCaregiver(caregiverId);
    _caregivers[caregiverId] = c.copyWith(name: name.trim());
  }

  /// Sets or clears the caregiver's profile photo. Care-Flash shows it on the
  /// matched-caregiver card through [CaregiverAccount.toPublic].
  void updateCaregiverAvatar(String caregiverId, {String? avatarDataUrl}) {
    final c = _requireCaregiver(caregiverId);
    _caregivers[caregiverId] = c.copyWith(avatarDataUrl: avatarDataUrl);
  }

  // ---------------------------------------------------------------------------
  // Care seeker: request lifecycle
  // ---------------------------------------------------------------------------

  Map<String, Object?> submitRequest(String seekerId, Map<String, Object?> args) {
    final request = HelpRequest(
      helpType: HelpType.values.byName(args['helpType']! as String),
      description: args['description'] as String?,
      checklist: BoundaryChecklist.fromJson(args['checklist']! as Map<String, Object?>),
      location: VisitLocation.fromJson(args['location']! as Map<String, Object?>),
      scheduledAt: DateTime.parse(args['scheduledAt']! as String),
      duration: VisitDuration.values.byName(args['duration']! as String),
      genderFilter: GenderFilter.values.byName(args['genderFilter']! as String),
    );
    _requireSeeker(seekerId);

    final price = Pricing.breakdown(request.duration);
    final booking = Booking(
      id: _newId('bk'),
      requestReference: _reference(),
      helpType: request.helpType,
      description: request.description,
      checklist: request.checklist,
      location: request.location,
      scheduledAt: request.scheduledAt,
      duration: request.duration,
      genderFilter: request.genderFilter,
      price: price,
      // The care seeker pays the Grab fare as part of the total; the caregiver
      // never does. (FR-P-10, FR-P-11)
      estimatedGrabFare: price.grabFare,
      status: BookingStatus.matching,
      createdAt: DateTime.now(),
      updates: [
        BookingUpdate(
          status: BookingStatus.matching,
          message: 'Finding a caregiver…',
          at: DateTime.now(),
        ),
      ],
    );
    _bookings.add(booking);
    _bookingSeeker[booking.id] = seekerId;

    return _attemptMatch(booking.id).toJson();
  }

  Map<String, Object?> retryWithGenderFilter(String seekerId, GenderFilter filter) {
    final booking = _openSeekerBooking(seekerId);
    _replaceBooking(booking.copyWith(
      genderFilter: filter,
      status: BookingStatus.matching,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.matching,
          message: 'Looking again for a ${filter.label.toLowerCase()} caregiver…',
          at: DateTime.now(),
        ),
      ],
    ));
    return _attemptMatch(booking.id).toJson();
  }

  Booking _attemptMatch(String bookingId) {
    final booking = _requireBooking(bookingId);
    CaregiverAccount? match;
    for (final c in _caregivers.values) {
      if (c.canReceiveRequests && booking.genderFilter.matches(c.gender)) {
        match = c;
        break;
      }
    }
    if (match == null) {
      _replaceBooking(booking.copyWith(
        status: BookingStatus.noMatch,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.noMatch,
            message: 'No caregiver is available right now.',
            at: DateTime.now(),
          ),
        ],
      ));
      return _requireBooking(bookingId);
    }
    _replaceBooking(booking.copyWith(
      caregiver: match.toPublic(),
      status: BookingStatus.matched,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.matched,
          message: '${match.firstName} is available to help.',
          at: DateTime.now(),
        ),
      ],
    ));
    return _requireBooking(bookingId);
  }

  Map<String, Object?> pay(String seekerId, String bookingId, PaymentMethodType type) {
    final booking = _requireBooking(bookingId);
    if (booking.status != BookingStatus.matched || booking.price == null) {
      throw StateError('This booking is not ready to be paid.');
    }
    final method = PaymentMethod(
      id: type.name,
      type: type,
      displayLabel: type.label,
    );
    _replaceBooking(booking.copyWith(
      paymentMethod: method,
      paymentStatus: PaymentStatus.succeeded,
      clientCode: _clientCode(),
      status: BookingStatus.paidPending,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.paidPending,
          message: 'Paid. Waiting for the caregiver to accept.',
          at: DateTime.now(),
        ),
      ],
    ));
    // The paid request is now offered to the matched caregiver.
    return {'success': true, 'status': PaymentStatus.succeeded.name, 'message': null};
  }

  void cancelBooking(String seekerId, CancellationReason reason) {
    final booking = _openSeekerBooking(seekerId);
    final refunded = _refunded(booking, _refundReasonFor(reason));
    _replaceBooking(refunded.copyWith(
      status: BookingStatus.cancelled,
      cancellationReason: reason,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.cancelled,
          message:
              'Booking cancelled${refunded.hasRefund ? ' and refunded' : ''}.',
          at: DateTime.now(),
        ),
      ],
    ));
    _clearOfferIfAny(booking.id);
  }

  void _clearOfferIfAny(String bookingId) {
    // Nothing to pointer-clear; offers are derived from status. Kept for clarity.
  }

  Map<String, Object?> verifySafetyButton(
    String seekerId,
    ButtonVerification verification,
  ) {
    final booking = _openSeekerBooking(seekerId);
    if (booking.status != BookingStatus.arrived &&
        booking.status != BookingStatus.codeVerified) {
      return {'success': false, 'message': 'The caregiver has not arrived yet.'};
    }
    // The CARE SEEKER's scan is checked here: the code must belong to this
    // booking, match the nonce, be unexpired and unused. Any failure cancels
    // the booking, records the failure and notifies support. No retry. (FR-P-18)
    final failure = booking.validateButtonPayload(verification.payload);
    if (failure != null) {
      final cancelled = _refunded(booking, RefundReason.failedVerification)
          .copyWith(
            status: BookingStatus.cancelled,
            cancellationReason: CancellationReason.failedVerification,
            updates: [
              ...booking.updates,
              BookingUpdate(
                status: BookingStatus.cancelled,
                message:
                    '${failure.label} Booking cancelled and support notified.',
                at: DateTime.now(),
              ),
            ],
          );
      _replaceBooking(cancelled);
      return {'success': false, 'message': '${failure.label} Booking cancelled.'};
    }
    _replaceBooking(booking.copyWith(
      status: BookingStatus.active,
      // The button code is single use, so it is consumed by this scan.
      buttonCode: booking.buttonCode!.markUsed(DateTime.now()),
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.active,
          message: 'Safety button verified. Session started.',
          at: DateTime.now(),
        ),
      ],
    ));
    return {'success': true, 'message': null};
  }

  void endEarly(String seekerId) {
    final booking = _openSeekerBooking(seekerId);
    if (booking.price == null) return;
    // The caregiver keeps the early-end compensation and the unused remainder
    // is refunded to the care seeker. (FR-CS-16, FR-P-22)
    final refunded = _refunded(booking, RefundReason.endedEarly);
    final compensation = RefundPolicy.caregiverCompensationFor(booking);
    _replaceBooking(refunded.copyWith(
      status: BookingStatus.endedEarly,
      outcome: SessionOutcome.endedEarly,
      caregiverPayout: compensation,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.endedEarly,
          message: 'Session ended early. Partly refunded.',
          at: DateTime.now(),
        ),
      ],
    ));
    _creditEarning(booking, EarningKind.earlyEndCompensation, compensation);
  }

  void reportIncident(String seekerId, IncidentReport report) {
    final booking = _requireBooking(report.bookingId);
    // A report ends the session and returns the full amount charged, Grab fare
    // included. (FR-CS-17, FR-P-23)
    final refunded = _refunded(booking, RefundReason.reportOrButtonPress);
    _replaceBooking(refunded.copyWith(
      status: BookingStatus.reported,
      outcome: SessionOutcome.careSeekerReported,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.reported,
          message: 'Incident reported. Support has been notified.',
          at: DateTime.now(),
        ),
      ],
    ));
  }

  void rateCaregiver(String seekerId, Map<String, Object?> args) {
    final booking = _requireBooking(args['bookingId']! as String);
    final rating = CaregiverRating(
      bookingId: booking.id,
      caregiverId: args['caregiverId']! as String,
      stars: args['stars']! as int,
      comment: args['comment'] as String?,
    );
    _caregiverRatings.putIfAbsent(seekerId, () => []).add(rating);
    // Surface the feedback to the caregiver. (FR-CM-23)
    final caregiverId = booking.caregiver?.id;
    if (caregiverId != null) {
      _feedbackReceived.putIfAbsent(caregiverId, () => []).insert(
            0,
            FeedbackReceived(
              bookingId: booking.id,
              reference: booking.requestReference,
              stars: rating.stars,
              comment: rating.comment,
              receivedAt: DateTime.now(),
            ),
          );
    }
  }

  void submitAppFeedback(Map<String, Object?> args) {
    _appFeedback.add(AppFeedback(
      stars: args['stars']! as int,
      comment: args['comment'] as String?,
    ));
  }

  // ---------------------------------------------------------------------------
  // Caregiver: request + session lifecycle
  // ---------------------------------------------------------------------------

  void acceptRequest(String caregiverId) {
    final offer = _caregiverOffer(caregiverId);
    if (offer == null) throw StateError('There is no request to accept.');
    // The safety-button code is not activated yet. It is generated only after
    // the client code is verified at arrival. (FR-P-17)
    _replaceBooking(offer.copyWith(
      status: BookingStatus.confirmed,
      updates: [
        ...offer.updates,
        BookingUpdate(
          status: BookingStatus.confirmed,
          message: 'Caregiver confirmed.',
          at: DateTime.now(),
        ),
      ],
    ));
  }

  void declineRequest(String caregiverId) {
    final offer = _caregiverOffer(caregiverId);
    if (offer == null) return;
    // Offer the request to the next eligible caregiver.
    _replaceBooking(offer.copyWith(caregiver: null, status: BookingStatus.matching));
    _attemptMatch(offer.id);
  }

  void reportDanger(String caregiverId, String description) {
    final offer = _caregiverOffer(caregiverId);
    if (offer == null) return;
    // The booking is cancelled, support is notified and the care seeker is
    // refunded: the caregiver price and fee come back, the Grab fare is kept
    // because the ride may already have been taken. (FR-CM-11, FR-P-19)
    // TODO(team): confirm keeping the Grab fare; the SRS is undecided.
    final refunded = _refunded(offer, RefundReason.dangerBeforeSession);
    _replaceBooking(refunded.copyWith(
      status: BookingStatus.cancelled,
      cancellationReason: CancellationReason.preSessionDanger,
      updates: [
        ...offer.updates,
        BookingUpdate(
          status: BookingStatus.cancelled,
          message: 'Booking cancelled over a safety concern.',
          at: DateTime.now(),
        ),
      ],
    ));
  }

  void startTrip(String caregiverId) => _advance(caregiverId, BookingStatus.caregiverTravelling,
      'Caregiver is on the way.');

  void markArrived(String caregiverId) =>
      _advance(caregiverId, BookingStatus.arrived, 'Caregiver has arrived.');

  void _advance(String caregiverId, BookingStatus status, String message) {
    final booking = _caregiverActive(caregiverId) ?? _caregiverOffer(caregiverId);
    if (booking == null) throw StateError('No active booking for this caregiver.');
    _replaceBooking(booking.copyWith(
      status: status,
      updates: [...booking.updates, BookingUpdate(status: status, message: message, at: DateTime.now())],
    ));
  }

  Map<String, Object?> verifyClientCode(String caregiverId, String code) {
    final booking = _caregiverActive(caregiverId) ?? _caregiverOffer(caregiverId);
    if (booking == null) {
      return {'success': false, 'message': 'No active booking.'};
    }
    if (booking.clientCode != code) {
      _replaceBooking(booking.copyWith(
        status: BookingStatus.cancelled,
        cancellationReason: CancellationReason.failedVerification,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.cancelled,
            message: 'Wrong client code. Booking cancelled.',
            at: DateTime.now(),
          ),
        ],
      ));
      return {'success': false, 'message': 'Wrong client code. Booking cancelled.'};
    }
    // After a valid client code the caregiver app activates the booking-linked,
    // single-use safety-button code. The CARE SEEKER verifies it by scanning;
    // the caregiver can never confirm it. (FR-P-17, FR-P-18)
    _replaceBooking(booking.copyWith(
      status: BookingStatus.codeVerified,
      buttonCode: ButtonCode.generate(bookingId: booking.id),
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.codeVerified,
          message: 'Client code verified.',
          at: DateTime.now(),
        ),
      ],
    ));
    return {'success': true, 'message': null};
  }

  void completeSession(String caregiverId) {
    final booking = _caregiverActive(caregiverId);
    if (booking == null || booking.price == null) {
      throw StateError('No running session to complete.');
    }
    final earnings = Pricing.caregiverEarnings(booking.price!);
    _replaceBooking(booking.copyWith(
      status: BookingStatus.completed,
      outcome: SessionOutcome.completed,
      caregiverPayout: earnings,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.completed,
          message: 'Session complete. Thank you!',
          at: DateTime.now(),
        ),
      ],
    ));
    _creditEarning(booking, EarningKind.session, earnings);
  }

  void sos(String caregiverId, String description) {
    final booking = _caregiverActive(caregiverId);
    if (booking == null || booking.price == null) return;
    final compensation = Pricing.sosCompensation(booking.price!);
    _replaceBooking(booking.copyWith(
      status: BookingStatus.caregiverSos,
      outcome: SessionOutcome.caregiverSos,
      caregiverPayout: compensation,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.caregiverSos,
          message: 'SOS raised. Emergency contacts and support notified.',
          at: DateTime.now(),
        ),
      ],
    ));
    _creditEarning(booking, EarningKind.sosCompensation, compensation);
  }

  void reportCareSeeker(String caregiverId, IncidentReport report) {
    final booking = _requireBooking(report.bookingId);
    _replaceBooking(booking.copyWith(
      status: BookingStatus.reported,
      updates: [
        ...booking.updates,
        BookingUpdate(
          status: BookingStatus.reported,
          message: 'Report filed with support.',
          at: DateTime.now(),
        ),
      ],
    ));
  }

  void rateCareSeeker(String caregiverId, Map<String, Object?> args) {
    final booking = _requireBooking(args['bookingId']! as String);
    _careSeekerRatings.putIfAbsent(caregiverId, () => []).add(CareSeekerRating(
      bookingId: booking.id,
      reference: args['reference']! as String,
      stars: args['stars']! as int,
      comment: args['comment'] as String?,
    ));
  }

  Map<String, Object?> requestWithdrawal(String caregiverId, int amount) {
    final summary = _earningsSummary(caregiverId);
    if (amount <= 0 || amount % 1 != 0) {
      return {'success': false, 'amount': 0, 'message': 'Enter a whole amount.'};
    }
    if (amount < PlatformPolicy.minimumWithdrawal) {
      return {
        'success': false,
        'amount': 0,
        'message': 'Minimum withdrawal is ${PlatformPolicy.minimumWithdrawal}.',
      };
    }
    if (amount > summary.availableBalance) {
      return {'success': false, 'amount': 0, 'message': 'Amount exceeds your available balance.'};
    }
    _withdrawals.putIfAbsent(caregiverId, () => []).insert(
          0,
          Withdrawal(
            id: _newId('wd'),
            amount: amount,
            method: PlatformPolicy.payoutMethods.first,
            requestedAt: DateTime.now(),
          ),
        );
    return {'success': true, 'amount': amount, 'message': null};
  }

  void _creditEarning(Booking booking, EarningKind kind, int amount) {
    final caregiverId = booking.caregiver?.id;
    if (caregiverId == null) return;
    _earnings.putIfAbsent(caregiverId, () => []).insert(
          0,
          EarningEntry(
            id: _newId('earn'),
            bookingId: booking.id,
            reference: booking.requestReference,
            kind: kind,
            amount: amount,
            at: DateTime.now(),
          ),
        );
  }

  EarningsSummary _earningsSummary(String caregiverId) {
    final pending = _caregiverActive(caregiverId);
    final pendingAmount =
        (pending != null && pending.status == BookingStatus.active && pending.price != null)
            ? Pricing.caregiverEarnings(pending.price!)
            : 0;
    return EarningsSummary(
      earnings: _earnings[caregiverId] ?? const [],
      withdrawals: _withdrawals[caregiverId] ?? const [],
      pendingBalance: pendingAmount,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Everything needed to restore accounts and sessions after a restart.
  ///
  /// TODO(team): bookings are deliberately not saved yet; a restart clears the
  /// live requests. Add them here once the demo needs to survive restarts
  /// mid-booking.
  Map<String, Object?> toJson() => {
        'seq': _seq,
        'seekers': _seekers.values.map((s) => s.toJson()).toList(),
        'caregivers': _caregivers.values.map((c) => c.toJson()).toList(),
        'seekerCredentials': _seekerCredentials.map(
          (email, credential) => MapEntry(email, credential.toJson()),
        ),
        'caregiverCredentials': _caregiverCredentials.map(
          (email, credential) => MapEntry(email, credential.toJson()),
        ),
        'sessions': _sessions.entries
            .map((entry) => {
                  'token': entry.key,
                  'role': entry.value.role,
                  'userId': entry.value.userId,
                  'expiresAt': entry.value.expiresAt.toIso8601String(),
                })
            .toList(),
      };

  // ---------------------------------------------------------------------------
  // Snapshots pushed to each connected app
  // ---------------------------------------------------------------------------

  Map<String, Object?> seekerSnapshot(String seekerId) {
    final seeker = _seekers[seekerId];
    Booking? active;
    final history = <Booking>[];
    for (var i = _bookings.length - 1; i >= 0; i--) {
      final b = _bookings[i];
      if (_bookingSeeker[b.id] != seekerId) continue;
      if (b.status.isOpen) {
        active ??= b;
      } else {
        history.add(b);
      }
    }
    return {
      'currentUser': seeker?.toJson(),
      'activeBooking': active?.toJson(),
      'bookingHistory': history.map((b) => b.toJson()).toList(),
    };
  }

  Map<String, Object?> caregiverSnapshot(String caregiverId) {
    final caregiver = _caregivers[caregiverId];
    final history = <Booking>[];
    Booking? active;
    for (var i = _bookings.length - 1; i >= 0; i--) {
      final b = _bookings[i];
      if (b.caregiver?.id != caregiverId) continue;
      if (b.status == BookingStatus.paidPending) continue; // shown as the offer
      if (b.status.isOpen) {
        active ??= b;
      } else {
        history.add(b);
      }
    }
    return {
      'currentCaregiver': caregiver?.toJson(),
      'incomingRequest': _caregiverOffer(caregiverId)?.toJson(),
      'activeBooking': active?.toJson(),
      'bookingHistory': history.map((b) => b.toJson()).toList(),
      'earnings': _earningsSummary(caregiverId).toJson(),
      'feedbackReceived':
          (_feedbackReceived[caregiverId] ?? const []).map((f) => f.toJson()).toList(),
      'careSeekerRatings':
          (_careSeekerRatings[caregiverId] ?? const []).map((r) => r.toJson()).toList(),
    };
  }
}
