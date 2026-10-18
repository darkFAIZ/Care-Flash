/// Itemized price shown before payment. (FR-CS-8, FR-CS-10, FR-P-11)
///
/// All amounts are whole Indonesian rupiah (IDR).
class PriceBreakdown {
  const PriceBreakdown({
    required this.caregiverPrice,
    required this.platformFee,
    required this.grabFare,
  });

  /// Caregiver service price at IDR 25,000 per 30 minutes. (FR-P-9)
  final int caregiverPrice;

  /// Platform service fee, 5 percent of [caregiverPrice]. (FR-P-10)
  final int platformFee;

  /// Estimated Grab fare, mocked for now. (AGENTS.md §5)
  final int grabFare;

  /// Caregiver price + platform fee + Grab fare. (FR-P-11)
  int get total => caregiverPrice + platformFee + grabFare;

  Map<String, Object?> toJson() => {
        'caregiverPrice': caregiverPrice,
        'platformFee': platformFee,
        'grabFare': grabFare,
      };

  factory PriceBreakdown.fromJson(Map<String, Object?> json) => PriceBreakdown(
        caregiverPrice: json['caregiverPrice']! as int,
        platformFee: json['platformFee']! as int,
        grabFare: json['grabFare']! as int,
      );
}
