import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Payment info page: the methods available to the care seeker.
///
/// Only the method labels are shown. Card details are never stored by the app.
/// (DC-CS-2)
class PaymentInfoScreen extends ConsumerWidget {
  const PaymentInfoScreen({super.key});

  static const String route = '/payment-info';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods = ref.watch(platformProvider).availableMethods();

    return Scaffold(
      appBar: AppBar(title: const AppText('Payment info')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          const SectionHeader(title: 'Saved payment methods'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final method in methods)
                  ListTile(
                    leading: Icon(_iconFor(method.type)),
                    title: AppText(method.displayLabel),
                    subtitle: AppText(method.type.label),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Add payment method',
            icon: Icons.add_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: AppText('Adding a payment method is coming soon.'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: AppText(
                    'Card details are handled by the payment provider and are '
                    'never stored in the app.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PaymentMethodType type) => switch (type) {
        PaymentMethodType.mastercard => Icons.credit_card_rounded,
        _ => Icons.account_balance_wallet_outlined,
      };
}
