import 'dart:math';

import 'package:care_core/care_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the two teacher recommendations: the care seeker pays the Grab
/// fare, and the generated safety-button code is verified by the client.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the care seeker pays the Grab fare', () {
    test('a 1-hour visit with a IDR 9,000 fare totals IDR 61,500', () {
      final price = Pricing.breakdown(VisitDuration.sixty);

      expect(price.caregiverPrice, 50000, reason: 'IDR 25,000 per 30 minutes');
      expect(price.platformFee, 2500, reason: '5% of the caregiver price');
      expect(price.grabFare, 9000, reason: 'mocked fare for one hour');
      // 50,000 + 2,500 + 9,000 = 61,500.
      expect(price.total, 61500);
      expect(price.total, price.caregiverPrice + price.platformFee + price.grabFare);
    });

    test('45 minutes gives 37,500 + 1,875 + the fare', () {
      final price = Pricing.breakdown(VisitDuration.fortyFive);

      expect(price.caregiverPrice, 37500);
      expect(price.platformFee, 1875, reason: '5% of 37,500');
      expect(price.total, 39375 + price.grabFare);
      expect(price.total, 37500 + 1875 + price.grabFare);
    });

    test('the caregiver pay never includes the fee or the Grab fare', () {
      for (final duration in VisitDuration.values) {
        final price = Pricing.breakdown(duration);

        expect(price.caregiverPay, price.caregiverPrice,
            reason: 'expected pay is the service price only');
        expect(Pricing.caregiverEarnings(price), price.caregiverPrice);
        expect(price.caregiverPay, isNot(price.total));
        expect(price.caregiverPay, isNot(price.platformFee));
        expect(price.caregiverPay, isNot(price.grabFare));
        // The platform keeps its fee and passes the fare to Grab.
        expect(price.caregiverPay + price.platformFee,
            price.total - price.grabFare);
      }
    });
  });

  group('the refund rules', () {
    Booking paidBooking() {
      final price = Pricing.breakdown(VisitDuration.sixty); // total 61,500
      return Booking(
        id: 'bk-1',
        requestReference: 'REQ-TEST',
        helpType: HelpType.takeCare,
        checklist: const BoundaryChecklist(),
        location: const VisitLocation(
          label: 'Home',
          address: 'Jalan Merdeka 1',
          latitude: -6.2,
          longitude: 106.8,
        ),
        scheduledAt: DateTime.now(),
        duration: VisitDuration.sixty,
        genderFilter: GenderFilter.both,
        price: price,
        estimatedGrabFare: price.grabFare,
        status: BookingStatus.active,
        paymentStatus: PaymentStatus.succeeded,
        createdAt: DateTime.now(),
      );
    }

    test('a report or a physical button press refunds the whole total', () {
      final booking = paidBooking();

      expect(RefundPolicy.refundFor(booking, RefundReason.reportOrButtonPress),
          61500, reason: 'includes the IDR 9,000 Grab fare');
      expect(
          RefundPolicy.isFullRefund(RefundReason.reportOrButtonPress), isTrue);
    });

    test('no caregiver accepting refunds the whole total', () {
      final booking = paidBooking();

      expect(RefundPolicy.refundFor(booking, RefundReason.noCaregiverAccepts),
          61500, reason: 'no ride was booked, so nothing was used');
      expect(RefundPolicy.isFullRefund(RefundReason.noCaregiverAccepts), isTrue);
    });

    test('failed verification and a pre-session danger report keep the fare',
        () {
      final booking = paidBooking();

      expect(RefundPolicy.refundFor(booking, RefundReason.failedVerification),
          61500 - 9000, reason: 'caregiver price + fee = 52,500');
      expect(RefundPolicy.refundFor(booking, RefundReason.dangerBeforeSession),
          52500);
      // TODO(team): the SRS has not decided whether the fare is kept.
      expect(
          RefundPolicy.isFullRefund(RefundReason.failedVerification), isFalse);
    });

    test('ending early refunds the unused remainder', () {
      final booking = paidBooking();
      final compensation = Pricing.earlyEndCompensation(booking.price!);

      expect(RefundPolicy.refundFor(booking, RefundReason.endedEarly),
          61500 - compensation);
      expect(RefundPolicy.caregiverCompensationFor(booking), compensation);
      expect(RefundPolicy.isFullRefund(RefundReason.endedEarly), isFalse);
    });
  });

  group('the safety-button code is verified by the client', () {
    final reference = DateTime(2026, 1, 1, 10);

    ButtonCode codeFor(String bookingId) => ButtonCode.generate(
          bookingId: bookingId,
          now: reference,
          random: Random(7),
        );

    test('a payload belonging to another booking is rejected', () {
      final mine = codeFor('bk-1');
      final theirs = codeFor('bk-2');

      expect(mine.validate('bk-1', mine.payload, reference), isNull);
      expect(mine.validate('bk-1', theirs.payload, reference),
          ButtonCodeFailure.wrongBooking);
      expect(mine.validate('bk-2', mine.payload, reference),
          ButtonCodeFailure.wrongBooking);
    });

    test('an expired payload is rejected', () {
      final code = codeFor('bk-1');
      final afterExpiry = reference.add(PlatformPolicy.safetyButtonCodeTtl);

      expect(code.validate('bk-1', code.payload, afterExpiry),
          ButtonCodeFailure.expired);
      expect(
          code.validate(
              'bk-1', code.payload, reference.add(const Duration(minutes: 14))),
          isNull,
          reason: 'still valid one minute before the expiry');
    });

    test('an already used payload is rejected', () {
      final code = codeFor('bk-1');

      expect(code.validate('bk-1', code.payload, reference), isNull);
      final used = code.markUsed(reference);
      expect(used.isUsed, isTrue);
      expect(used.validate('bk-1', used.payload, reference),
          ButtonCodeFailure.alreadyUsed);
    });

    test('a malformed payload is rejected', () {
      final code = codeFor('bk-1');

      expect(code.validate('bk-1', 'not-a-payload', reference),
          ButtonCodeFailure.wrongNonce);
      expect(code.validate('bk-1', 'careflash://button/only-one-part', reference),
          ButtonCodeFailure.wrongNonce);
    });

    test('the payload carries the booking id and the nonce', () {
      final code = codeFor('bk-42');
      final parsed = ButtonCode.parsePayload(code.payload);

      expect(code.payload, startsWith('careflash://button/bk-42/'));
      expect(parsed, isNotNull);
      expect(parsed!.bookingId, 'bk-42');
      expect(parsed.nonce, code.nonce);
      expect(code.signature, ButtonCode.mockSignature(code.bookingId, code.nonce));
    });

    test('the scan is stored on the booking so it cannot be replayed', () {
      final booking = Booking(
        id: 'bk-9',
        requestReference: 'REQ-REPLAY',
        helpType: HelpType.takeCare,
        checklist: const BoundaryChecklist(),
        location: const VisitLocation(
          label: 'Home',
          address: 'Jalan Merdeka 1',
          latitude: -6.2,
          longitude: 106.8,
        ),
        scheduledAt: DateTime.now(),
        duration: VisitDuration.sixty,
        genderFilter: GenderFilter.both,
        status: BookingStatus.codeVerified,
        buttonCode: codeFor('bk-9'),
        createdAt: DateTime.now(),
      );

      expect(booking.validateButtonPayload(booking.safetyButtonId!, now: reference),
          isNull);
      expect(
          booking.validateButtonPayload('careflash://button/bk-9/OTHER',
              now: reference),
          ButtonCodeFailure.wrongNonce);
      expect(
          booking.validateButtonPayload('careflash://button/bk-8/OTHER',
              now: reference),
          ButtonCodeFailure.wrongBooking);
      expect(booking.safetyButtonId, startsWith('careflash://button/bk-9/'));
    });
  });

  group('a caregiver app action cannot start the session', () {
    Future<MockCaregiverPlatform> platformAtDestination() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final platform = await MockCaregiverPlatform.create(
        verificationReviewDelay: const Duration(milliseconds: 5),
        requestArrivalDelay: const Duration(milliseconds: 10),
        buttonScanDelay: const Duration(milliseconds: 5),
      );
      await platform.signIn(email: 'budi@example.com', password: 'secret1');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await platform.acceptRequest();
      await platform.startTrip();
      await platform.markArrived();
      return platform;
    }

    test('the caregiver stops at codeVerified and only the client scan passes',
        () async {
      final platform = await platformAtDestination();
      // No simulated care seeker, so nothing but real actions can advance it.
      platform.setAutoAdvance(false);

      final result = await platform.verifyClientCode(platform.debugClientCode!);
      expect(result.success, isTrue);

      var booking = (await platform.watchActiveBooking().first)!;
      expect(booking.status, BookingStatus.codeVerified);
      expect(booking.status, isNot(BookingStatus.buttonVerified));
      expect(booking.status, isNot(BookingStatus.active));
      expect(booking.buttonCode, isNotNull,
          reason: 'the code is activated for the care seeker to verify');
      expect(booking.isSessionActive, isFalse);

      // The caregiver's own actions must not move the booking forward.
      await platform.completeSession();
      await platform.sos('test');
      await platform.markArrived();
      booking = (await platform.watchActiveBooking().first)!;
      expect(booking.status, BookingStatus.codeVerified,
          reason: 'a caregiver action cannot skip the client verification');
      expect(booking.isSessionActive, isFalse);

      platform.dispose();
    });

    test('a wrong payload scanned by the client cancels the booking', () async {
      final platform = await platformAtDestination();
      platform.setAutoAdvance(false);
      await platform.verifyClientCode(platform.debugClientCode!);
      final booking = (await platform.watchActiveBooking().first)!;

      // A simulated care seeker scan with the wrong payload fails the check.
      platform.simulateCareSeekerButtonScan(valid: false);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(await platform.watchActiveBooking().first, isNull);
      final finished = (await platform.watchBookingHistory().first).first;
      expect(finished.status, BookingStatus.cancelled);
      expect(finished.cancellationReason, CancellationReason.failedVerification);
      expect(finished.buttonCode!.isUsed, isFalse,
          reason: 'the code is never consumed by a failed scan');
      expect(booking.buttonCode, isNotNull);

      platform.dispose();
    });
  });
}
