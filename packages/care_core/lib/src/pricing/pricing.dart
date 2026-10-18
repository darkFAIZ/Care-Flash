import '../enums.dart';
import '../models/pricing.dart';
import '../platform_policy.dart';

/// Pricing rules from the platform SRS (FR-P-9 to FR-P-11) and AGENTS.md §6.
abstract final class Pricing {
  /// Caregiver service price for 30 minutes. (FR-P-9)
  static const int caregiverPricePer30Minutes = 25000;

  /// Platform service fee as a fraction of the caregiver price. (FR-P-10)
  static const double platformFeeRate = 0.05;

  /// Caregiver service price for [duration], rounded to the nearest rupiah.
  static int caregiverPriceFor(VisitDuration duration) =>
      (caregiverPricePer30Minutes * duration.minutes / 30).round();

  /// Platform service fee for a given caregiver price. (FR-P-10)
  static int platformFeeFor(int caregiverPrice) =>
      (caregiverPrice * platformFeeRate).round();

  /// Estimated Grab fare for [duration].
  ///
  /// Delegates to [PlatformPolicy.mockGrabFare]; the platform obtains the fare
  /// separately (FR-P-10).
  static int estimateGrabFare(VisitDuration duration) =>
      PlatformPolicy.mockGrabFare(duration);

  /// Itemized price for [duration]. (FR-P-11)
  static PriceBreakdown breakdown(VisitDuration duration) {
    final caregiverPrice = caregiverPriceFor(duration);
    return PriceBreakdown(
      caregiverPrice: caregiverPrice,
      platformFee: platformFeeFor(caregiverPrice),
      grabFare: estimateGrabFare(duration),
    );
  }

  /// Compensation paid to the caregiver when the care seeker ends early.
  /// (FR-CS-16, FR-P-22)
  ///
  /// The base is [PlatformPolicy.earlyEndCompensationBase] and the rate is
  /// [PlatformPolicy.earlyEndCompensationRate]. Both are kept in one place
  /// because the team has not confirmed them.
  static int earlyEndCompensation(PriceBreakdown price) {
    final base = switch (PlatformPolicy.earlyEndCompensationBase) {
      EarlyEndCompensationBase.quotedTotal => price.total,
      EarlyEndCompensationBase.caregiverServicePrice => price.caregiverPrice,
    };
    return (base * PlatformPolicy.earlyEndCompensationRate).round();
  }

  /// Caregiver service earnings released on normal completion. The platform
  /// keeps its fee and settles the Grab fare separately, so the caregiver
  /// receives the caregiver service price. (FR-P-21)
  static int caregiverEarnings(PriceBreakdown price) => price.caregiverPrice;

  /// Compensation paid to the caregiver after an SOS. (FR-P-24)
  ///
  /// The SRS says the platform applies the "configured caregiver compensation
  /// policy", so this reuses the early-end policy.
  /// TODO(team): confirm the SOS compensation. (FR-P-24, SRS open decision 5)
  static int sosCompensation(PriceBreakdown price) =>
      earlyEndCompensation(price);

  /// Amount returned to the care seeker when the session ends early: the part
  /// of the visit that was not used. (FR-CS-16)
  ///
  /// With the current policy the caregiver is paid half the quoted total and
  /// the care seeker gets the other half back.
  /// TODO(team): confirm how the fee and Grab fare are treated.
  /// (FR-P-22, SRS open decision 3)
  static int earlyEndRefund(PriceBreakdown price) =>
      price.total - earlyEndCompensation(price);
}
