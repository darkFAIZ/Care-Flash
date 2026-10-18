import 'package:care_core/care_core.dart';
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
      appBar: AppBar(title: const Text('Payment info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Saved payment methods', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final method in methods)
                  ListTile(
                    leading: Icon(_iconFor(method.type)),
                    title: Text(method.displayLabel),
                    subtitle: Text(method.type.label),
                    trailing: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Adding a payment method is coming soon.'),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add payment method'),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Card details are handled by the payment provider and are '
                      'never stored in the app.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PaymentMethodType type) => switch (type) {
        PaymentMethodType.mastercard => Icons.credit_card,
        _ => Icons.account_balance_wallet_outlined,
      };
}
