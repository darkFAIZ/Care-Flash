import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'app_card.dart';
import 'price_row.dart';
import 'app_text.dart';

/// Itemised price: caregiver price, 5% platform fee, Grab fare, then total.
///
/// The data comes in as [AppPriceLine]s, so each app formats its own amounts.
/// (FR-CS-8, FR-P-11)
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    super.key,
    this.title = 'Price breakdown',
    required this.lines,
    required this.total,
    this.note,
  });

  final String title;
  final List<AppPriceLine> lines;
  final AppPriceLine total;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final line in lines) ...[
            PriceRow.fromLine(line),
            const SizedBox(height: AppSpacing.sm),
          ],
          Container(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          PriceRow.fromLine(total),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(
              note!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
