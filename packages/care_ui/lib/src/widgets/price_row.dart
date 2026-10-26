import 'package:flutter/material.dart';
import 'app_text.dart';

/// One line of a price breakdown, as plain data so the card stays reusable.
@immutable
class AppPriceLine {
  const AppPriceLine({
    required this.label,
    required this.amount,
    this.hint,
    this.emphasised = false,
  });

  final String label;

  /// Already formatted, for example `IDR 25,000`.
  final String amount;
  final String? hint;
  final bool emphasised;
}

/// Label on the left, amount on the right, optional supporting note below.
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.label,
    required this.amount,
    this.hint,
    this.emphasised = false,
  });

  factory PriceRow.fromLine(AppPriceLine line, {Key? key}) {
    return PriceRow(
      key: key,
      label: line.label,
      amount: line.amount,
      hint: line.hint,
      emphasised: line.emphasised,
    );
  }

  final String label;
  final String amount;
  final String? hint;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = emphasised
        ? textTheme.titleSmall?.copyWith(color: scheme.onSurface)
        : textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final amountStyle = emphasised
        ? textTheme.titleMedium?.copyWith(color: scheme.onSurface)
        : textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: AppText(label, style: labelStyle)),
            const SizedBox(width: 12),
            AppText(amount, style: amountStyle, textAlign: TextAlign.right),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          AppText(
            hint!,
            style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
