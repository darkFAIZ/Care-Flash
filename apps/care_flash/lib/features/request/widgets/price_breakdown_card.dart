import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';

/// Itemized price card reused by the estimate, caregiver and payment screens.
/// (FR-CS-8, FR-CS-10, FR-P-11)
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    super.key,
    required this.price,
    this.title = 'Price estimate',
  });

  final PriceBreakdown price;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _Line(label: 'Caregiver service', amount: price.caregiverPrice),
            _Line(label: 'Platform fee (5%)', amount: price.platformFee),
            _Line(label: 'Estimated Grab fare', amount: price.grabFare),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium),
                Text(
                  formatIdr(price.total),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(formatIdr(amount), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
