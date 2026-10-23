import 'package:care_core/care_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MockCaregiverPlatform> buildPlatform() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 5),
      requestArrivalDelay: const Duration(milliseconds: 10),
      buttonScanDelay: const Duration(milliseconds: 5),
    );
  }

  Future<void> wait([Duration duration = const Duration(milliseconds: 60)]) =>
      Future<void>.delayed(duration);

  /// Signs in and drives the booking up to the point where the care seeker is
  /// on site and the caregiver must verify the client code. (FR-CM-10)
  Future<MockCaregiverPlatform> caregiverAtDestination() async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();
    await platform.acceptRequest();
    await platform.startTrip();
    await platform.markArrived();
    return platform;
  }

  /// Drives the booking up to a running session. (FR-CM-16)
  Future<MockCaregiverPlatform> caregiverInSession() async {
    final platform = await caregiverAtDestination();
    await platform.verifyClientCode(platform.debugClientCode!);
    await wait();
    return platform;
  }

  /// A platform whose simulated care seeker leaves feedback quickly, so the
  /// tests do not wait for the normal demo delay. (FR-CM-23)
  Future<MockCaregiverPlatform> buildPlatformWithFeedback() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 5),
      requestArrivalDelay: const Duration(milliseconds: 10),
      buttonScanDelay: const Duration(milliseconds: 5),
      feedbackDelay: const Duration(milliseconds: 5),
    );
  }

  /// Signs in, runs a full session and completes it. (FR-P-21)
  Future<MockCaregiverPlatform> caregiverWhoCompletedSession() async {
    final platform = await buildPlatformWithFeedback();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();
    await platform.acceptRequest();
    await platform.startTrip();
    await platform.markArrived();
    await platform.verifyClientCode(platform.debugClientCode!);
    await wait();
    await platform.completeSession();
    return platform;
  }

  test('signUp creates an unverified account without a safety badge', () async {
    final platform = await buildPlatform();
    final result = await platform.signUp(
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'secret1',
      gender: Gender.male,
    );

    expect(result.success, isTrue);
    expect(result.user!.verificationStatus, VerificationStatus.notSubmitted);
    expect(result.user!.safetyModuleCompleted, isFalse);
    expect(result.user!.canReceiveRequests, isFalse);
    expect(result.user!.canResubmit, isTrue);

    platform.dispose();
  });

  test('signUp rejects an invalid email', () async {
    final platform = await buildPlatform();
    final result = await platform.signUp(
      name: 'Budi',
      email: 'not-an-email',
      password: 'secret1',
      gender: Gender.male,
    );

    expect(result.success, isFalse);
    expect(result.user, isNull);

    platform.dispose();
  });

  test('submitVerification goes pending then approved after review', () async {
    final platform = await buildPlatform();
    await platform.signUp(
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'secret1',
      gender: Gender.male,
    );

    await platform.submitVerification(
      residentialIdNumber: '1806123456',
      documentLabel: 'identity-card.jpg',
    );
    expect(platform.currentCaregiver!.verificationStatus,
        VerificationStatus.pending);
    expect(platform.currentCaregiver!.rejectionReason, isNull);

    await wait();

    expect(platform.currentCaregiver!.verificationStatus,
        VerificationStatus.approved);
    expect(platform.currentCaregiver!.canResubmit, isFalse);

    platform.dispose();
  });

  test('a failed review is rejected with a reason and can be resubmitted',
      () async {
    final platform = await buildPlatform();
    await platform.signUp(
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'secret1',
      gender: Gender.male,
    );
    platform.setNextVerificationFails(true);

    await platform.submitVerification(
      residentialIdNumber: '1806123456',
      documentLabel: 'identity-card.jpg',
    );
    await wait();

    expect(platform.currentCaregiver!.verificationStatus,
        VerificationStatus.rejected);
    expect(platform.currentCaregiver!.rejectionReason, isNotNull);
    expect(platform.currentCaregiver!.canResubmit, isTrue);

    platform.dispose();
  });

  test('an unverified caregiver is never offered a request', () async {
    final platform = await buildPlatform();
    await platform.signUp(
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'secret1',
      gender: Gender.male,
    );

    final offers = <Booking?>[];
    platform.watchIncomingRequest().listen(offers.add);
    await wait();

    expect(platform.currentCaregiver!.canReceiveRequests, isFalse);
    expect(offers.whereType<Booking>(), isEmpty,
        reason: 'an unverified caregiver must not receive requests');

    platform.dispose();
  });

  test('a request is offered once verified, badged and available', () async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');

    final offers = <Booking?>[];
    platform.watchIncomingRequest().listen(offers.add);
    await wait();

    expect(offers, isNotEmpty);
    expect(offers.last, isNotNull);
    expect(platform.currentCaregiver!.canReceiveRequests, isTrue);

    platform.dispose();
  });

  test('the offered booking hides the client code before acceptance',
      () async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();

    final offer = await platform.watchIncomingRequest().first;
    expect(offer, isNotNull);
    expect(offer!.clientCode, isNull,
        reason: 'the client code is private until arrival');
    expect(offer.status, BookingStatus.paidPending);
    expect(offer.price, isNotNull);

    platform.dispose();
  });

  test('declining clears the offer and does not change the rating', () async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();

    final ratingBefore = platform.currentCaregiver!.rating;
    await platform.declineRequest();
    await wait();

    expect(platform.currentCaregiver!.rating, ratingBefore);
    expect(await platform.watchIncomingRequest().first, isNull);

    platform.dispose();
  });

  test('accepting moves the offer to an active confirmed booking', () async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();

    await platform.acceptRequest();
    await wait();

    expect(await platform.watchIncomingRequest().first, isNull);
    final active = await platform.watchActiveBooking().first;
    expect(active, isNotNull);
    expect(active!.status, BookingStatus.confirmed);
    expect(active.caregiver!.id, platform.currentCaregiver!.id);
    expect(active.location, isNotNull,
        reason: 'acceptance discloses the destination');

    platform.dispose();
  });

  test('a caregiver who goes unavailable stops being offered requests',
      () async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();
    await platform.declineRequest();

    await platform.updateAvailability(CaregiverAvailability.unavailable);
    expect(platform.currentCaregiver!.canReceiveRequests, isFalse);

    await wait();
    expect(await platform.watchIncomingRequest().first, isNull);

    platform.dispose();
  });

  test('the trip advances from confirmed to arrived', () async {
    final platform = await buildPlatform();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');
    await wait();
    await platform.acceptRequest();
    expect((await platform.watchActiveBooking().first)!.status,
        BookingStatus.confirmed);

    await platform.startTrip();
    expect((await platform.watchActiveBooking().first)!.status,
        BookingStatus.caregiverTravelling);

    await platform.markArrived();
    final arrived = await platform.watchActiveBooking().first;
    expect(arrived!.status, BookingStatus.arrived);
    expect(arrived.clientCode, isNotNull,
        reason: 'a client code exists once the booking is accepted');

    platform.dispose();
  });

  test('a wrong client code cancels the booking', () async {
    final platform = await caregiverAtDestination();
    final active = await platform.watchActiveBooking().first;

    final result = await platform.verifyClientCode('000000');
    // Only fail when the random code happens to be 000000.
    if (active!.clientCode == '000000') {
      return;
    }

    expect(result.success, isFalse);
    expect(result.message, isNotNull);
    expect(await platform.watchActiveBooking().first, isNull);
    expect((await platform.watchBookingHistory().first).first.status,
        BookingStatus.cancelled);

    platform.dispose();
  });

  test('the correct client code verifies and the button scan starts the session',
      () async {
    final platform = await caregiverAtDestination();
    final code = platform.debugClientCode!;

    final result = await platform.verifyClientCode(code);
    expect(result.success, isTrue);
    final verified = await platform.watchActiveBooking().first;
    expect(verified!.status, BookingStatus.codeVerified);
    expect(verified.safetyButtonId, isNotNull,
        reason: 'verifying the code activates the safety button');

    // autoAdvance lets the simulated care seeker scan the button. (FR-CM-15)
    await wait();
    final active = await platform.watchActiveBooking().first;
    expect(active!.status, BookingStatus.active);
    expect(active.isSessionActive, isTrue);

    platform.dispose();
  });

  test('completing the session finishes the booking', () async {
    final platform = await caregiverAtDestination();
    await platform.verifyClientCode(platform.debugClientCode!);
    await wait();
    expect((await platform.watchActiveBooking().first)!.status,
        BookingStatus.active);

    await platform.completeSession();
    expect(await platform.watchActiveBooking().first, isNull);
    final finished = (await platform.watchBookingHistory().first).first;
    expect(finished.status, BookingStatus.completed);
    expect(finished.outcome, SessionOutcome.completed);

    platform.dispose();
  });

  test('an SOS ends the session with compensation', () async {
    final platform = await caregiverAtDestination();
    await platform.verifyClientCode(platform.debugClientCode!);
    await wait();

    await platform.sos('Unsafe situation');

    final finished = (await platform.watchBookingHistory().first).first;
    expect(finished.status, BookingStatus.caregiverSos);
    expect(finished.outcome, SessionOutcome.caregiverSos);

    platform.dispose();
  });

  test('reporting the care seeker ends the session', () async {
    final platform = await caregiverAtDestination();
    await platform.verifyClientCode(platform.debugClientCode!);
    await wait();

    await platform.reportCareSeeker(
      IncidentReport(
        bookingId: 'bk-1',
        description: 'Refused the boundary rules.',
        createdAt: DateTime.now(),
      ),
    );

    final finished = (await platform.watchBookingHistory().first).first;
    expect(finished.status, BookingStatus.reported);

    platform.dispose();
  });

  test('the care seeker ending early finishes with compensation', () async {
    final platform = await caregiverAtDestination();
    await platform.verifyClientCode(platform.debugClientCode!);
    await wait();

    platform.simulateCareSeekerEndEarly();

    final finished = (await platform.watchBookingHistory().first).first;
    expect(finished.status, BookingStatus.endedEarly);
    expect(finished.outcome, SessionOutcome.endedEarly);

    platform.dispose();
  });

  test('a running session shows a pending balance and no earnings yet',
      () async {
    final platform = await caregiverInSession();
    final active = await platform.watchActiveBooking().first;

    final summary = await platform.watchEarnings().first;
    expect(summary.earnings, isEmpty);
    expect(summary.availableBalance, 0);
    expect(summary.pendingBalance, Pricing.caregiverEarnings(active!.price!));

    platform.dispose();
  });

  test('completing a session credits the caregiver service earnings',
      () async {
    final platform = await caregiverInSession();
    await platform.completeSession();

    final finished = (await platform.watchBookingHistory().first).first;
    final expected = Pricing.caregiverEarnings(finished.price!);
    expect(finished.caregiverPayout, expected);

    final summary = await platform.watchEarnings().first;
    expect(summary.earnings, hasLength(1));
    expect(summary.earnings.single.kind, EarningKind.session);
    expect(summary.earnings.single.amount, expected);
    expect(summary.totalEarned, expected);
    expect(summary.availableBalance, expected);
    expect(summary.pendingBalance, 0);

    platform.dispose();
  });

  test('an early end credits the caregiver compensation, not full earnings',
      () async {
    final platform = await caregiverInSession();
    final active = await platform.watchActiveBooking().first;
    final price = active!.price!;

    platform.simulateCareSeekerEndEarly();
    await wait();

    final finished = (await platform.watchBookingHistory().first).first;
    expect(finished.caregiverPayout, Pricing.earlyEndCompensation(price));

    final summary = await platform.watchEarnings().first;
    expect(summary.earnings.single.kind, EarningKind.earlyEndCompensation);
    expect(summary.earnings.single.amount, Pricing.earlyEndCompensation(price));

    platform.dispose();
  });

  test('an SOS credits the caregiver compensation (FR-P-24)', () async {
    final platform = await caregiverInSession();
    final active = await platform.watchActiveBooking().first;
    final price = active!.price!;

    await platform.sos('Unsafe situation');

    final summary = await platform.watchEarnings().first;
    expect(summary.earnings.single.kind, EarningKind.sosCompensation);
    expect(summary.earnings.single.amount, Pricing.sosCompensation(price));

    platform.dispose();
  });

  test('a withdrawal reduces the available balance and is recorded',
      () async {
    final platform = await caregiverInSession();
    await platform.completeSession();

    final before = await platform.watchEarnings().first;
    final result = await platform.requestWithdrawal(10000);
    expect(result.success, isTrue);
    expect(result.amount, 10000);

    final after = await platform.watchEarnings().first;
    expect(after.availableBalance, before.availableBalance - 10000);
    expect(after.withdrawals, hasLength(1));
    expect(after.withdrawals.single.amount, 10000);
    expect(after.withdrawals.single.status, PayoutStatus.processing);
    expect(after.totalWithdrawn, 10000);

    platform.dispose();
  });

  test('a withdrawal above the balance or below the minimum fails', () async {
    final platform = await caregiverInSession();
    await platform.completeSession();
    final summary = await platform.watchEarnings().first;

    final tooMuch =
        await platform.requestWithdrawal(summary.availableBalance + 1);
    expect(tooMuch.success, isFalse);
    expect(tooMuch.message, isNotNull);

    final tooSmall = await platform.requestWithdrawal(500);
    expect(tooSmall.success, isFalse);
    expect(tooSmall.message, isNotNull);

    expect((await platform.watchEarnings().first).withdrawals, isEmpty);

    platform.dispose();
  });

  test('the care seeker leaves feedback after a completed session (FR-CM-23)',
      () async {
    final platform = await caregiverWhoCompletedSession();
    await wait();

    final feedback = await platform.watchFeedbackReceived().first;
    expect(feedback, hasLength(1));
    expect(feedback.single.stars, inInclusiveRange(1, 5));
    expect(feedback.single.comment, isNotNull);

    final finished = (await platform.watchBookingHistory().first).first;
    expect(feedback.single.reference, finished.requestReference);
    expect(feedback.single.bookingId, finished.id);

    platform.dispose();
  });

  test('a session that ends in SOS earns no feedback', () async {
    final platform = await caregiverInSession();
    await platform.sos('Unsafe situation');
    await wait(const Duration(milliseconds: 60));

    expect(await platform.watchFeedbackReceived().first, isEmpty);

    platform.dispose();
  });

  test('the caregiver can rate the care seeker (FR-CM-24)', () async {
    final platform = await caregiverWhoCompletedSession();
    final finished = (await platform.watchBookingHistory().first).first;

    await platform.rateCareSeeker(
      CareSeekerRating(
        bookingId: finished.id,
        reference: finished.requestReference,
        stars: 5,
        comment: 'Polite and on time.',
      ),
    );

    final ratings = await platform.watchCareSeekerRatings().first;
    expect(ratings, hasLength(1));
    expect(ratings.single.stars, 5);
    expect(ratings.single.comment, 'Polite and on time.');
    expect(ratings.single.reference, finished.requestReference);

    platform.dispose();
  });
}
