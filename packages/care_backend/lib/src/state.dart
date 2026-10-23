import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:care_domain/care_domain.dart';

/// The single source of truth for the Care-Flash demo backend.
///
/// One instance is shared by both apps. A care-seeker action (for example
/// submitting a request) and a caregiver action (accepting it) both mutate the
/// same [Booking] records, so a change made in one app is visible to the other.
/// This replaces the per-app mocks that used to simulate the other side.
/// (AGENTS.md §5)
class CareBackendState {
  CareBackendState({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _seq = 0;

  // Prototype credentials are stored as salted PBKDF2 hashes, never plaintext.
  final Map<String, String> _seekerPasswords = {};
  final Map<String, String> _caregiverPasswords = {};

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

  /// Serializes the complete shared platform state for durable storage.
  Map<String, Object?> toJson() => {
    'version': 1,
    'sequence': _seq,
    'seekerPasswords': _seekerPasswords,
    'caregiverPasswords': _caregiverPasswords,
    'seekers': _seekers.values.map((item) => item.toJson()).toList(),
    'caregivers': _caregivers.values.map((item) => item.toJson()).toList(),
    'bookings': _bookings.map((item) => item.toJson()).toList(),
    'bookingSeeker': _bookingSeeker,
    'earnings': _encodeLedger(_earnings, (item) => item.toJson()),
    'withdrawals': _encodeLedger(_withdrawals, (item) => item.toJson()),
    'feedbackReceived': _encodeLedger(
      _feedbackReceived,
      (item) => item.toJson(),
    ),
    'careSeekerRatings': _encodeLedger(
      _careSeekerRatings,
      (item) => item.toJson(),
    ),
    'caregiverRatings': _encodeLedger(
      _caregiverRatings,
      (item) => item.toJson(),
    ),
    'appFeedback': _appFeedback.map((item) => item.toJson()).toList(),
  };

  /// Restores a state document previously produced by [toJson].
  void restoreFromJson(Map<String, Object?> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported Care-Flash data file version.');
    }
    _seq = json['sequence'] as int? ?? 0;
    _replaceStringMap(_seekerPasswords, json['seekerPasswords']);
    _replaceStringMap(_caregiverPasswords, json['caregiverPasswords']);
    _seekers
      ..clear()
      ..addEntries(
        _jsonList(json['seekers']).map((item) {
          final account = CareSeeker.fromJson(item);
          return MapEntry(account.id, account);
        }),
      );
    _caregivers
      ..clear()
      ..addEntries(
        _jsonList(json['caregivers']).map((item) {
          final account = CaregiverAccount.fromJson(item);
          return MapEntry(account.id, account);
        }),
      );
    _bookings
      ..clear()
      ..addAll(_jsonList(json['bookings']).map(Booking.fromJson));
    _replaceStringMap(_bookingSeeker, json['bookingSeeker']);
    _restoreLedger(_earnings, json['earnings'], EarningEntry.fromJson);
    _restoreLedger(_withdrawals, json['withdrawals'], Withdrawal.fromJson);
    _restoreLedger(
      _feedbackReceived,
      json['feedbackReceived'],
      FeedbackReceived.fromJson,
    );
    _restoreLedger(
      _careSeekerRatings,
      json['careSeekerRatings'],
      CareSeekerRating.fromJson,
    );
    _restoreLedger(
      _caregiverRatings,
      json['caregiverRatings'],
      CaregiverRating.fromJson,
    );
    _appFeedback
      ..clear()
      ..addAll(_jsonList(json['appFeedback']).map(AppFeedback.fromJson));
  }

  Map<String, List<Map<String, Object?>>> _encodeLedger<T>(
    Map<String, List<T>> ledger,
    Map<String, Object?> Function(T) encode,
  ) => {
    for (final entry in ledger.entries)
      entry.key: entry.value.map(encode).toList(),
  };

  void _restoreLedger<T>(
    Map<String, List<T>> target,
    Object? value,
    T Function(Map<String, Object?>) decode,
  ) {
    target
      ..clear()
      ..addAll({
        for (final entry in (value as Map? ?? const {}).entries)
          entry.key as String: _jsonList(entry.value).map(decode).toList(),
      });
  }

  List<Map<String, Object?>> _jsonList(Object? value) =>
      (value as List<Object?>? ?? const [])
          .map((item) => Map<String, Object?>.from(item! as Map))
          .toList();

  void _replaceStringMap(Map<String, String> target, Object? value) {
    target
      ..clear()
      ..addAll(
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry(key as String, item as String),
        ),
      );
  }

  String _passwordRecord(String password) {
    final secureRandom = Random.secure();
    final salt = List<int>.generate(16, (_) => secureRandom.nextInt(256));
    final saltHex = salt
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final digest = _derivePassword(password, salt);
    final digestHex = digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'pbkdf2-sha256:120000:$saltHex:$digestHex';
  }

  bool _verifyPassword(String password, String? record) {
    if (record == null) return false;
    final parts = record.split(':');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 100000 || iterations > 1000000) {
      return false;
    }
    final salt = _decodeHex(parts[2]);
    final expected = _decodeHex(parts[3]);
    final actual = _derivePassword(password, salt, iterations: iterations);
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var index = 0; index < actual.length; index++) {
      difference |= actual[index] ^ expected[index];
    }
    return difference == 0;
  }

  List<int> _derivePassword(
    String password,
    List<int> salt, {
    int iterations = 120000,
  }) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    for (var round = 1; round < iterations; round++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
    }
    return result;
  }

  List<int> _decodeHex(String value) {
    if (value.length.isOdd) return const [];
    try {
      return [
        for (var index = 0; index < value.length; index += 2)
          int.parse(value.substring(index, index + 2), radix: 16),
      ];
    } on FormatException {
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _newId(String prefix) => '$prefix-${_seq++}-${_random.nextInt(9999)}';

  String _reference() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  String _clientCode() => List.generate(6, (_) => _random.nextInt(10)).join();

  String _safetyButtonId() => 'BTN-${_reference()}';

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
      if (b.caregiver?.id == caregiverId &&
          b.status == BookingStatus.paidPending) {
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
    if (_seekers.values.any((s) => s.email == email)) {
      return _authFail('An account with that email already exists.');
    }
    final seeker = CareSeeker(
      id: _newId('cs'),
      name: name.trim(),
      email: email.trim(),
    );
    _seekers[seeker.id] = seeker;
    _seekerPasswords[email.trim()] = _passwordRecord(password);
    return _authOk(seeker);
  }

  Map<String, Object?> seekerSignIn({
    required String email,
    required String password,
  }) {
    for (final s in _seekers.values) {
      if (s.email == email &&
          _verifyPassword(password, _seekerPasswords[email])) {
        return _authOk(s);
      }
    }
    return _authFail('Wrong email or password.');
  }

  Map<String, Object?> _authOk(CareSeeker s) => {
    'success': true,
    'user': s.toJson(),
    'error': null,
  };
  Map<String, Object?> _authFail(String m) => {
    'success': false,
    'user': null,
    'error': m,
  };

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
    if (_caregivers.values.any((c) => c.email == email)) {
      return _caregiverAuthFail('An account with that email already exists.');
    }
    final caregiver = CaregiverAccount(
      id: _newId('cg'),
      name: name.trim(),
      email: email.trim(),
      gender: gender,
      // New accounts start unsubmitted so the app routes into the onboarding
      // form. (FR-CM-2)
      verificationStatus: VerificationStatus.notSubmitted,
    );
    _caregivers[caregiver.id] = caregiver;
    _caregiverPasswords[email.trim()] = _passwordRecord(password);
    return _caregiverAuthOk(caregiver);
  }

  Map<String, Object?> caregiverSignIn({
    required String email,
    required String password,
  }) {
    for (final c in _caregivers.values) {
      if (c.email == email &&
          _verifyPassword(password, _caregiverPasswords[email])) {
        return _caregiverAuthOk(c);
      }
    }
    return _caregiverAuthFail('Wrong email or password.');
  }

  Map<String, Object?> _caregiverAuthOk(CaregiverAccount c) => {
    'success': true,
    'user': c.toJson(),
    'error': null,
  };
  Map<String, Object?> _caregiverAuthFail(String m) => {
    'success': false,
    'user': null,
    'error': m,
  };

  void submitVerification(
    String caregiverId, {
    required String residentialIdNumber,
    required String documentLabel,
  }) {
    final c = _requireCaregiver(caregiverId);
    _caregivers[c.id] = c.copyWith(
      residentialIdNumber: residentialIdNumber,
      identityCardLabel: documentLabel,
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

  void updateAvailability(
    String caregiverId,
    CaregiverAvailability availability,
  ) {
    final c = _requireCaregiver(caregiverId);
    _caregivers[caregiverId] = c.copyWith(availability: availability);
  }

  // ---------------------------------------------------------------------------
  // Care seeker: request lifecycle
  // ---------------------------------------------------------------------------

  Map<String, Object?> submitRequest(
    String seekerId,
    Map<String, Object?> args,
  ) {
    final request = HelpRequest(
      helpType: HelpType.values.byName(args['helpType']! as String),
      description: args['description'] as String?,
      checklist: BoundaryChecklist.fromJson(
        args['checklist']! as Map<String, Object?>,
      ),
      location: VisitLocation.fromJson(
        args['location']! as Map<String, Object?>,
      ),
      scheduledAt: DateTime.parse(args['scheduledAt']! as String),
      duration: VisitDuration.values.byName(args['duration']! as String),
      genderFilter: GenderFilter.values.byName(args['genderFilter']! as String),
    );
    _requireSeeker(seekerId);

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
      price: Pricing.breakdown(request.duration),
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

  Map<String, Object?> retryWithGenderFilter(
    String seekerId,
    GenderFilter filter,
  ) {
    final booking = _openSeekerBooking(seekerId);
    _replaceBooking(
      booking.copyWith(
        genderFilter: filter,
        status: BookingStatus.matching,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.matching,
            message:
                'Looking again for a ${filter.label.toLowerCase()} caregiver…',
            at: DateTime.now(),
          ),
        ],
      ),
    );
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
      _replaceBooking(
        booking.copyWith(
          status: BookingStatus.noMatch,
          updates: [
            ...booking.updates,
            BookingUpdate(
              status: BookingStatus.noMatch,
              message: 'No caregiver is available right now.',
              at: DateTime.now(),
            ),
          ],
        ),
      );
      return _requireBooking(bookingId);
    }
    _replaceBooking(
      booking.copyWith(
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
      ),
    );
    return _requireBooking(bookingId);
  }

  Map<String, Object?> pay(
    String seekerId,
    String bookingId,
    PaymentMethodType type,
  ) {
    final booking = _requireBooking(bookingId);
    if (booking.status != BookingStatus.matched || booking.price == null) {
      throw StateError('This booking is not ready to be paid.');
    }
    final method = PaymentMethod(
      id: type.name,
      type: type,
      displayLabel: type.label,
    );
    _replaceBooking(
      booking.copyWith(
        paymentMethod: method,
        paymentStatus: PaymentStatus.succeeded,
        status: BookingStatus.paidPending,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.paidPending,
            message: 'Paid. Waiting for the caregiver to accept.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
    // The paid request is now offered to the matched caregiver.
    return {
      'success': true,
      'status': PaymentStatus.succeeded.name,
      'message': null,
    };
  }

  void cancelBooking(String seekerId, CancellationReason reason) {
    final booking = _openSeekerBooking(seekerId);
    final refunded = booking.isPaid;
    _replaceBooking(
      booking.copyWith(
        status: BookingStatus.cancelled,
        cancellationReason: reason,
        paymentStatus: refunded
            ? PaymentStatus.refunded
            : booking.paymentStatus,
        refundAmount: refunded
            ? booking.price?.serviceTotal
            : booking.refundAmount,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.cancelled,
            message: 'Booking cancelled${refunded ? ' and refunded' : ''}.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
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
    if (booking.status != BookingStatus.codeVerified) {
      return {
        'success': false,
        'message':
            'Confirm the caregiver code before scanning the safety button.',
      };
    }
    final expected = booking.safetyButtonId;
    if (expected == null || verification.payload != expected) {
      return {
        'success': false,
        'message': 'That does not match this visit’s safety button.',
      };
    }
    _replaceBooking(
      booking.copyWith(
        status: BookingStatus.active,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.active,
            message: 'Safety button verified. Session started.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
    return {'success': true, 'message': null};
  }

  void endEarly(String seekerId) {
    final booking = _openSeekerBooking(seekerId);
    if (booking.price == null) return;
    final compensation = Pricing.earlyEndCompensation(booking.price!);
    final refund = Pricing.earlyEndRefund(booking.price!);
    _replaceBooking(
      booking.copyWith(
        status: BookingStatus.endedEarly,
        outcome: SessionOutcome.endedEarly,
        paymentStatus: PaymentStatus.partiallyRefunded,
        refundAmount: refund,
        caregiverPayout: compensation,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.endedEarly,
            message: 'Session ended early. Partly refunded.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
    _creditEarning(booking, EarningKind.earlyEndCompensation, compensation);
  }

  void reportIncident(String seekerId, IncidentReport report) {
    final booking = _requireBooking(report.bookingId);
    final refunded = booking.isPaid;
    _replaceBooking(
      booking.copyWith(
        status: BookingStatus.reported,
        outcome: SessionOutcome.careSeekerReported,
        paymentStatus: refunded
            ? PaymentStatus.refunded
            : booking.paymentStatus,
        refundAmount: refunded
            ? booking.price?.serviceTotal
            : booking.refundAmount,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.reported,
            message: 'Incident reported. Support has been notified.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
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
      _feedbackReceived
          .putIfAbsent(caregiverId, () => [])
          .insert(
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
    _appFeedback.add(
      AppFeedback(
        stars: args['stars']! as int,
        comment: args['comment'] as String?,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Caregiver: request + session lifecycle
  // ---------------------------------------------------------------------------

  void acceptRequest(String caregiverId) {
    final offer = _caregiverOffer(caregiverId);
    if (offer == null) throw StateError('There is no request to accept.');
    _replaceBooking(
      offer.copyWith(
        status: BookingStatus.confirmed,
        safetyButtonId: _safetyButtonId(),
        clientCode: _clientCode(),
        updates: [
          ...offer.updates,
          BookingUpdate(
            status: BookingStatus.confirmed,
            message: 'Caregiver confirmed.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void declineRequest(String caregiverId) {
    final offer = _caregiverOffer(caregiverId);
    if (offer == null) return;
    // Offer the request to the next eligible caregiver.
    _replaceBooking(
      offer.copyWith(caregiver: null, status: BookingStatus.matching),
    );
    _attemptMatch(offer.id);
  }

  void reportDanger(String caregiverId, String description) {
    final offer = _caregiverOffer(caregiverId);
    if (offer == null) return;
    _replaceBooking(
      offer.copyWith(
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
      ),
    );
  }

  void startTrip(String caregiverId) => _advance(
    caregiverId,
    BookingStatus.caregiverTravelling,
    'Caregiver is on the way.',
  );

  void markArrived(String caregiverId) =>
      _advance(caregiverId, BookingStatus.arrived, 'Caregiver has arrived.');

  void _advance(String caregiverId, BookingStatus status, String message) {
    final booking =
        _caregiverActive(caregiverId) ?? _caregiverOffer(caregiverId);
    if (booking == null) {
      throw StateError('No active booking for this caregiver.');
    }
    _replaceBooking(
      booking.copyWith(
        status: status,
        updates: [
          ...booking.updates,
          BookingUpdate(status: status, message: message, at: DateTime.now()),
        ],
      ),
    );
  }

  Map<String, Object?> verifyCaregiverCode(String seekerId, String code) {
    final booking = _openSeekerBooking(seekerId);
    if (booking.status != BookingStatus.arrived) {
      return {
        'success': false,
        'message': 'Wait until your caregiver has arrived.',
      };
    }
    if (booking.clientCode != code.trim()) {
      _replaceBooking(
        booking.copyWith(
          status: BookingStatus.cancelled,
          cancellationReason: CancellationReason.failedVerification,
          updates: [
            ...booking.updates,
            BookingUpdate(
              status: BookingStatus.cancelled,
              message: 'Caregiver verification failed. Booking cancelled.',
              at: DateTime.now(),
            ),
          ],
        ),
      );
      return {
        'success': false,
        'message': 'The code did not match. The booking was cancelled.',
      };
    }
    _replaceBooking(
      booking.copyWith(
        status: BookingStatus.codeVerified,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.codeVerified,
            message: 'Caregiver identity confirmed by the care seeker.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
    return {'success': true, 'message': null};
  }

  void completeSession(String caregiverId) {
    final booking = _caregiverActive(caregiverId);
    if (booking == null || booking.price == null) {
      throw StateError('No running session to complete.');
    }
    final earnings = Pricing.caregiverEarnings(booking.price!);
    _replaceBooking(
      booking.copyWith(
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
      ),
    );
    _creditEarning(booking, EarningKind.session, earnings);
  }

  void sos(String caregiverId, String description) {
    final booking = _caregiverActive(caregiverId);
    if (booking == null || booking.price == null) return;
    final compensation = Pricing.sosCompensation(booking.price!);
    _replaceBooking(
      booking.copyWith(
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
      ),
    );
    _creditEarning(booking, EarningKind.sosCompensation, compensation);
  }

  void reportCareSeeker(String caregiverId, IncidentReport report) {
    final booking = _requireBooking(report.bookingId);
    _replaceBooking(
      booking.copyWith(
        status: BookingStatus.reported,
        updates: [
          ...booking.updates,
          BookingUpdate(
            status: BookingStatus.reported,
            message: 'Report filed with support.',
            at: DateTime.now(),
          ),
        ],
      ),
    );
  }

  void rateCareSeeker(String caregiverId, Map<String, Object?> args) {
    final booking = _requireBooking(args['bookingId']! as String);
    _careSeekerRatings
        .putIfAbsent(caregiverId, () => [])
        .add(
          CareSeekerRating(
            bookingId: booking.id,
            reference: args['reference']! as String,
            stars: args['stars']! as int,
            comment: args['comment'] as String?,
          ),
        );
  }

  Map<String, Object?> requestWithdrawal(String caregiverId, int amount) {
    final summary = _earningsSummary(caregiverId);
    if (amount <= 0 || amount % 1 != 0) {
      return {
        'success': false,
        'amount': 0,
        'message': 'Enter a whole amount.',
      };
    }
    if (amount < PlatformPolicy.minimumWithdrawal) {
      return {
        'success': false,
        'amount': 0,
        'message': 'Minimum withdrawal is ${PlatformPolicy.minimumWithdrawal}.',
      };
    }
    if (amount > summary.availableBalance) {
      return {
        'success': false,
        'amount': 0,
        'message': 'Amount exceeds your available balance.',
      };
    }
    _withdrawals
        .putIfAbsent(caregiverId, () => [])
        .insert(
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
    _earnings
        .putIfAbsent(caregiverId, () => [])
        .insert(
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
        (pending != null &&
            pending.status == BookingStatus.active &&
            pending.price != null)
        ? Pricing.caregiverEarnings(pending.price!)
        : 0;
    return EarningsSummary(
      earnings: _earnings[caregiverId] ?? const [],
      withdrawals: _withdrawals[caregiverId] ?? const [],
      pendingBalance: pendingAmount,
    );
  }

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
      'activeBooking': active?.copyWith(clientCode: null).toJson(),
      'bookingHistory': history
          .map((b) => b.copyWith(clientCode: null).toJson())
          .toList(),
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
      'incomingRequest': _caregiverOffer(
        caregiverId,
      )?.copyWith(clientCode: null).toJson(),
      'activeBooking': active
          ?.copyWith(
            clientCode: active.status == BookingStatus.arrived
                ? active.clientCode
                : null,
          )
          .toJson(),
      'bookingHistory': history.map((b) => b.toJson()).toList(),
      'earnings': _earningsSummary(caregiverId).toJson(),
      'feedbackReceived': (_feedbackReceived[caregiverId] ?? const [])
          .map((f) => f.toJson())
          .toList(),
      'careSeekerRatings': (_careSeekerRatings[caregiverId] ?? const [])
          .map((r) => r.toJson())
          .toList(),
    };
  }
}
