import 'package:care_core/care_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final HelpRequest _request = HelpRequest(
  helpType: HelpType.takeCare,
  description: 'Please help me prepare a meal.',
  checklist: BoundaryChecklist.suggested,
  location: VisitLocation.mockPresets.first,
  scheduledAt: DateTime(2026, 10, 20, 15),
  duration: VisitDuration.sixty,
);

/// Runs [body] with a fresh mock platform inside a fake clock so the simulated
/// timers can be advanced instantly.
void withPlatform(void Function(FakeAsync async, MockCarePlatform platform) body) {
  fakeAsync((async) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    MockCarePlatform? platform;
    MockCarePlatform.create().then((value) => platform = value);
    async.flushMicrotasks();
    final mock = platform!;
    try {
      body(async, mock);
    } finally {
      mock.dispose();
    }
  });
}

/// Signs in and returns once the simulated delay has passed.
void signIn(FakeAsync async, MockCarePlatform platform) {
  platform.signIn(email: 'ayu@example.com', password: 'secret1');
  async.elapse(const Duration(seconds: 1));
}

/// Drives a paid booking all the way to a running session.
void driveToActive(FakeAsync async, MockCarePlatform platform) {
  signIn(async, platform);
  platform.submitRequest(_request);
  async.elapse(MockCarePlatform.matchingDelay);
  platform.pay(
    bookingId: platform.activeBooking!.id,
    method: platform.availableMethods().first,
  );
  async.elapse(const Duration(seconds: 1));
  async.elapse(MockCarePlatform.caregiverAcceptDelay);
  async.elapse(MockCarePlatform.travelDelay);
  async.elapse(MockCarePlatform.arrivalDelay);
  async.elapse(MockCarePlatform.codeVerificationDelay);
  platform.simulateButtonScan();
  async.elapse(const Duration(seconds: 1));
}

void main() {
  test('auth: sign up and sign out update the current user', () {
    withPlatform((async, platform) {
      platform.signUp(name: 'Vincent', email: 'vincent@example.com', password: 'secret1');
      async.elapse(const Duration(seconds: 1));
      expect(platform.currentUser, isNotNull);
      expect(platform.currentUser!.name, 'Vincent');

      platform.signOut();
      async.flushMicrotasks();
      expect(platform.currentUser, isNull);
    });
  });

  test('auth: rejects short passwords', () {
    withPlatform((async, platform) {
      AuthResult? result;
      platform
          .signIn(email: 'ayu@example.com', password: '123')
          .then((value) => result = value);
      async.elapse(const Duration(seconds: 1));
      expect(result!.success, isFalse);
      expect(platform.currentUser, isNull);
    });
  });

  test('happy path: match, pay, accept, arrive, verify, complete', () {
    withPlatform((async, platform) {
      signIn(async, platform);

      var history = <Booking>[];
      platform.watchBookingHistory().listen((value) => history = value);
      async.flushMicrotasks();

      platform.submitRequest(_request);
      async.flushMicrotasks();
      expect(platform.activeBooking!.status, BookingStatus.matching);

      async.elapse(MockCarePlatform.matchingDelay);
      expect(platform.activeBooking!.status, BookingStatus.matched);
      expect(platform.activeBooking!.caregiver, isNotNull);
      expect(platform.activeBooking!.price!.total, 61500);

      platform.pay(
        bookingId: platform.activeBooking!.id,
        method: platform.availableMethods().first,
      );
      async.elapse(const Duration(seconds: 1));
      expect(platform.activeBooking!.status, BookingStatus.paidPending);
      expect(platform.activeBooking!.clientCode, isNotNull);

      async.elapse(MockCarePlatform.caregiverAcceptDelay);
      expect(platform.activeBooking!.status, BookingStatus.confirmed);

      async.elapse(MockCarePlatform.travelDelay);
      expect(platform.activeBooking!.status, BookingStatus.caregiverTravelling);

      async.elapse(MockCarePlatform.arrivalDelay);
      expect(platform.activeBooking!.status, BookingStatus.arrived);

      async.elapse(MockCarePlatform.codeVerificationDelay);
      expect(platform.activeBooking!.status, BookingStatus.codeVerified);
      expect(platform.activeBooking!.safetyButtonId, isNotNull);

      platform.simulateButtonScan();
      async.elapse(const Duration(seconds: 1));
      expect(platform.activeBooking!.status, BookingStatus.active);

      platform.simulateSessionComplete();
      async.flushMicrotasks();
      expect(platform.activeBooking, isNull);
      expect(history.single.status, BookingStatus.completed);
      expect(history.single.outcome, SessionOutcome.completed);
    });
  });

  test('no match can be retried with a new gender filter', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.setAutoAdvance(false);
      platform.setNextRequestMatches(false);

      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);
      expect(platform.activeBooking!.status, BookingStatus.noMatch);

      platform.setNextRequestMatches(true);
      platform.retryWithGenderFilter(GenderFilter.female);
      async.elapse(MockCarePlatform.matchingDelay);
      expect(platform.activeBooking!.status, BookingStatus.matched);
      expect(platform.activeBooking!.genderFilter, GenderFilter.female);
      expect(platform.activeBooking!.caregiver!.gender, Gender.female);
    });
  });

  test('payment failure can be retried', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.setAutoAdvance(false);
      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);

      platform.setNextPaymentFails(true);
      PaymentResult? failed;
      platform
          .pay(
            bookingId: platform.activeBooking!.id,
            method: platform.availableMethods().first,
          )
          .then((value) => failed = value);
      async.elapse(const Duration(seconds: 1));
      expect(failed!.success, isFalse);
      expect(platform.activeBooking!.status, BookingStatus.matched);

      PaymentResult? succeeded;
      platform
          .pay(
            bookingId: platform.activeBooking!.id,
            method: platform.availableMethods().first,
          )
          .then((value) => succeeded = value);
      async.elapse(const Duration(seconds: 1));
      expect(succeeded!.success, isTrue);
      expect(platform.activeBooking!.status, BookingStatus.paidPending);
    });
  });

  test('failed client code cancels the booking', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);
      platform.pay(
        bookingId: platform.activeBooking!.id,
        method: platform.availableMethods().first,
      );
      async.elapse(const Duration(seconds: 1));
      async.elapse(MockCarePlatform.caregiverAcceptDelay);
      async.elapse(MockCarePlatform.travelDelay);
      async.elapse(MockCarePlatform.arrivalDelay);

      platform.simulateCaregiverCodeVerification(valid: false);
      async.flushMicrotasks();
      expect(platform.activeBooking, isNull);
    });
  });

  test('physical button press reports the incident', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);
      platform.pay(
        bookingId: platform.activeBooking!.id,
        method: platform.availableMethods().first,
      );
      async.elapse(const Duration(seconds: 1));
      async.elapse(MockCarePlatform.caregiverAcceptDelay);
      async.elapse(MockCarePlatform.travelDelay);
      async.elapse(MockCarePlatform.arrivalDelay);
      async.elapse(MockCarePlatform.codeVerificationDelay);
      platform.simulateButtonScan();
      async.elapse(const Duration(seconds: 1));
      expect(platform.activeBooking!.status, BookingStatus.active);

      var history = <Booking>[];
      platform.watchBookingHistory().listen((value) => history = value);
      async.flushMicrotasks();

      platform.simulateButtonPress();
      async.flushMicrotasks();
      expect(platform.activeBooking, isNull);
      expect(history.first.status, BookingStatus.reported);
      expect(history.first.outcome, SessionOutcome.careSeekerReported);
    });
  });

  test('cancel moves the booking to history', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.setAutoAdvance(false);
      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);

      var history = <Booking>[];
      platform.watchBookingHistory().listen((value) => history = value);
      async.flushMicrotasks();

      platform.cancelBooking(CancellationReason.userCancelled);
      async.flushMicrotasks();
      expect(platform.activeBooking, isNull);
      expect(history.single.status, BookingStatus.cancelled);
      expect(history.single.cancellationReason, CancellationReason.userCancelled);
    });
  });

  test('paying records the payment as succeeded', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);
      platform.pay(
        bookingId: platform.activeBooking!.id,
        method: platform.availableMethods().first,
      );
      async.elapse(const Duration(seconds: 1));
      expect(platform.activeBooking!.paymentStatus, PaymentStatus.succeeded);
      expect(platform.activeBooking!.isPaid, isTrue);
    });
  });

  test('reporting an incident refunds the full amount', () {
    withPlatform((async, platform) {
      driveToActive(async, platform);
      final total = platform.activeBooking!.price!.total;
      var history = <Booking>[];
      platform.watchBookingHistory().listen((value) => history = value);
      async.flushMicrotasks();

      platform.simulateButtonPress();
      async.flushMicrotasks();

      expect(history.first.status, BookingStatus.reported);
      expect(history.first.paymentStatus, PaymentStatus.refunded);
      expect(history.first.refundAmount, total);
      expect(history.first.isRefunded, isTrue);
    });
  });

  test('ending early refunds the unused part of the visit', () {
    withPlatform((async, platform) {
      driveToActive(async, platform);
      final price = platform.activeBooking!.price!;
      var history = <Booking>[];
      platform.watchBookingHistory().listen((value) => history = value);
      async.flushMicrotasks();

      platform.endEarly();
      async.flushMicrotasks();

      expect(history.first.status, BookingStatus.endedEarly);
      expect(history.first.paymentStatus, PaymentStatus.partiallyRefunded);
      expect(history.first.refundAmount, Pricing.earlyEndRefund(price));
      expect(history.first.isPartiallyRefunded, isTrue);
    });
  });

  test('cancelling before payment does not refund', () {
    withPlatform((async, platform) {
      signIn(async, platform);
      platform.setAutoAdvance(false);
      platform.submitRequest(_request);
      async.elapse(MockCarePlatform.matchingDelay);

      var history = <Booking>[];
      platform.watchBookingHistory().listen((value) => history = value);
      async.flushMicrotasks();

      platform.cancelBooking(CancellationReason.userCancelled);
      async.flushMicrotasks();

      expect(history.single.paymentStatus, isNull);
      expect(history.single.hasRefund, isFalse);
    });
  });
}
