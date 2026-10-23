import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

/// Itemized price card reused by the estimate, caregiver and payment screens.
///
/// A thin wrapper over the shared `PriceBreakdownCard` so every screen shows
/// the same lines: caregiver price, the 5% platform fee, the Grab fare the
/// care seeker pays, then the total. (FR-CS-8, FR-CS-10, FR-P-11)
class PriceEstimateCard extends StatelessWidget {
  const PriceEstimateCard({
    super.key,
    required this.price,
    this.title = 'Price estimate',
  });

  final PriceBreakdown price;
  final String title;

  @override
  Widget build(BuildContext context) {
    return PriceBreakdownCard(
      title: title,
      lines: <AppPriceLine>[
        AppPriceLine(
          label: 'Caregiver service',
          amount: formatIdr(price.caregiverPrice),
        ),
        AppPriceLine(label: 'Platform fee (5%)', amount: formatIdr(price.platformFee)),
        // The care seeker pays the whole total up front, including the ride
        // to them. The caregiver never pays for Grab. (FR-P-10, FR-P-11)
        AppPriceLine(
          label: 'Grab fare (paid by you)',
          amount: formatIdr(price.grabFare),
          hint: "Estimated fare for the caregiver's trip to you.",
        ),
      ],
      total: AppPriceLine(
        label: 'Total',
        amount: formatIdr(price.total),
        emphasised: true,
      ),
    );
  }
}
