import 'enums.dart';

/// Base used to compute the early-end compensation. (FR-P-22)
enum EarlyEndCompensationBase {
  quotedTotal,
  caregiverServicePrice,
}

/// Defaults for decisions the SRS leaves open. Values follow AGENTS.md §7.
///
/// Each open decision is kept here in one place so the team can change it once,
/// and the SRS stays the source of truth if these disagree with it.
abstract final class PlatformPolicy {
  /// Time a caregiver has to accept an offer before it is offered elsewhere.
  /// TODO(team): confirm the response window. (FR-P-13)
  static const Duration caregiverResponseTimeout = Duration(seconds: 60);

  /// Default caregiver gender filter. (FR-CS-7)
  static const GenderFilter defaultGenderFilter = GenderFilter.both;

  /// Matching radius in kilometres. Mocked until maps/location is real.
  /// TODO(team): confirm the radius. (FR-P-4)
  static const double matchingRadiusKm = 5;

  /// Fraction of the base paid as early-end compensation. (FR-P-22)
  static const double earlyEndCompensationRate = 0.5;

  /// Base for the early-end compensation. The SRS currently proposes the quoted
  /// total. TODO(team): confirm total vs caregiver service price. (FR-P-22)
  static const EarlyEndCompensationBase earlyEndCompensationBase =
      EarlyEndCompensationBase.quotedTotal;

  /// Maximum evidence attachments kept per incident report.
  /// TODO(team): confirm evidence types, limits and retention. (FR-CS-18)
  static const int maxEvidenceAttachments = 10;

  /// Estimated Grab fare per duration used by the mock.
  /// TODO(team): replace with a real Grab fare estimate. The platform obtains
  /// the fare separately. (FR-P-10)
  static const Map<VisitDuration, int> mockGrabFares = {
    VisitDuration.thirty: 7000,
    VisitDuration.fortyFive: 8000,
    VisitDuration.sixty: 9000,
    VisitDuration.ninety: 11000,
    VisitDuration.oneHundredTwenty: 13000,
  };

  /// Estimated Grab fare for [duration]. (FR-P-10)
  static int mockGrabFare(VisitDuration duration) => mockGrabFares[duration]!;

  /// Smallest amount a caregiver can withdraw in one request.
  /// TODO(team): confirm the minimum and the payout methods. (FR-CM-22)
  static const int minimumWithdrawal = 10000;

  /// How long a payout takes to reach the caregiver. The mock only shows the
  /// window; no money moves. TODO(team): confirm the payout schedule.
  /// (FR-CM-22, SRS open decisions 6 and 8)
  static const Duration payoutSchedule = Duration(days: 2);

  /// Payout methods offered to a caregiver. The supported methods are not
  /// decided yet. TODO(team): confirm the payout methods. (FR-CM-22)
  static const List<String> payoutMethods = [
    'GoPay',
    'DANA',
    'Bank transfer',
  ];
}
