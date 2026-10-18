import 'package:care_core/care_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pricing.caregiverPriceFor', () {
    test('is IDR 25,000 per 30 minutes', () {
      expect(Pricing.caregiverPriceFor(VisitDuration.thirty), 25000);
      expect(Pricing.caregiverPriceFor(VisitDuration.fortyFive), 37500);
      expect(Pricing.caregiverPriceFor(VisitDuration.sixty), 50000);
      expect(Pricing.caregiverPriceFor(VisitDuration.ninety), 75000);
      expect(Pricing.caregiverPriceFor(VisitDuration.oneHundredTwenty), 100000);
    });
  });

  group('Pricing.platformFeeFor', () {
    test('is 5 percent of the caregiver price, rounded', () {
      expect(Pricing.platformFeeFor(50000), 2500);
      expect(Pricing.platformFeeFor(37500), 1875);
    });
  });

  group('Pricing.breakdown', () {
    test('matches the SRS example (1 hour with IDR 9,000 Grab fare)', () {
      final price = Pricing.breakdown(VisitDuration.sixty);
      expect(price.caregiverPrice, 50000);
      expect(price.platformFee, 2500);
      expect(price.grabFare, 9000);
      expect(price.total, 61500);
    });

    test('total is caregiver price + platform fee + Grab fare', () {
      final price = Pricing.breakdown(VisitDuration.ninety);
      expect(price.total, price.caregiverPrice + price.platformFee + price.grabFare);
    });
  });

  group('Pricing.earlyEndCompensation', () {
    test('is 50 percent of the quoted total', () {
      final price = Pricing.breakdown(VisitDuration.sixty);
      expect(Pricing.earlyEndCompensation(price), 30750);
    });
  });

  group('Pricing.caregiverEarnings', () {
    test('is the caregiver service price on completion', () {
      final price = Pricing.breakdown(VisitDuration.sixty);
      expect(Pricing.caregiverEarnings(price), 50000);
    });
  });

  group('Pricing.earlyEndRefund', () {
    test('returns the unused part of the quoted total', () {
      final price = Pricing.breakdown(VisitDuration.sixty);
      expect(
        Pricing.earlyEndRefund(price),
        price.total - Pricing.earlyEndCompensation(price),
      );
      expect(Pricing.earlyEndRefund(price), 30750);
    });
  });

  group('Pricing.sosCompensation', () {
    test('reuses the early-end compensation policy', () {
      for (final duration in VisitDuration.values) {
        final price = Pricing.breakdown(duration);
        expect(
          Pricing.sosCompensation(price),
          Pricing.earlyEndCompensation(price),
        );
      }
    });
  });

  group('PlatformPolicy', () {
    test('provides the AGENTS.md §7 defaults', () {
      expect(PlatformPolicy.defaultGenderFilter, GenderFilter.both);
      expect(PlatformPolicy.caregiverResponseTimeout, const Duration(seconds: 60));
      expect(PlatformPolicy.matchingRadiusKm, 5);
      expect(Pricing.estimateGrabFare(VisitDuration.sixty), 9000);
    });

    test('exposes payout defaults for the earnings screen', () {
      expect(PlatformPolicy.minimumWithdrawal, greaterThan(0));
      expect(PlatformPolicy.payoutMethods, isNotEmpty);
      expect(PlatformPolicy.payoutSchedule, isNot(Duration.zero));
    });
  });

  group('formatIdr', () {
    test('groups thousands and prefixes IDR', () {
      expect(formatIdr(61500), 'IDR 61,500');
      expect(formatIdr(50000), 'IDR 50,000');
      expect(formatIdr(1000000), 'IDR 1,000,000');
      expect(formatIdr(0), 'IDR 0');
    });
  });

  group('GenderFilter.matches', () {
    test('both matches any gender', () {
      expect(GenderFilter.both.matches(Gender.male), isTrue);
      expect(GenderFilter.both.matches(Gender.female), isTrue);
    });

    test('male and female match only their own gender', () {
      expect(GenderFilter.male.matches(Gender.male), isTrue);
      expect(GenderFilter.male.matches(Gender.female), isFalse);
      expect(GenderFilter.female.matches(Gender.female), isTrue);
      expect(GenderFilter.female.matches(Gender.male), isFalse);
    });
  });
}
