import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'confirmed_screen.dart';
import 'widgets/price_estimate_card.dart';

/// Payment for the matched booking. A failed attempt stays on this screen so
/// the care seeker can retry. (FR-CS-11)
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  static const String route = '/payment';

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod? _selected;
  bool _paying = false;
  String? _error;

  Future<void> _pay() async {
    final booking = ref.read(activeBookingProvider).value;
    final method = _selected;
    if (booking == null || method == null) {
      return;
    }
    setState(() {
      _paying = true;
      _error = null;
    });
    final result = await ref
        .read(platformProvider)
        .pay(bookingId: booking.id, method: method);
    if (!mounted) {
      return;
    }
    if (result.success) {
      context.go(ConfirmedScreen.route);
    } else {
      setState(() {
        _paying = false;
        _error = result.message ?? 'Payment failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final methods = ref.watch(platformProvider).availableMethods();
    _selected ??= methods.isNotEmpty ? methods.first : null;
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Payment')),
        body: const EmptyState(
          icon: Icons.info_outline,
          title: 'This booking is no longer active.',
        ),
      );
    }

    if (!booking.isPayable) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Payment')),
        body: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'This booking has already been paid.',
          actionLabel: 'View booking',
          onAction: () => context.go(ConfirmedScreen.route),
        ),
      );
    }

    final price = booking.price ?? Pricing.breakdown(booking.duration);

    return Scaffold(
      appBar: AppBar(title: const AppText('Payment')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          PriceEstimateCard(price: price, title: 'Amount due'),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Payment method'),
          const SizedBox(height: AppSpacing.xs),
          for (final method in methods) ...[
            AppCard(
              compact: true,
              highlighted: _selected?.id == method.id,
              onTap: _paying
                  ? null
                  : () => setState(() => _selected = method),
              child: Row(
                children: [
                  Icon(
                    _selected?.id == method.id
                        ? Icons.check_circle_rounded
                        : Icons.account_balance_wallet_outlined,
                    color: _selected?.id == method.id
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: AppText(method.displayLabel)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Card details are handled by the payment provider and are never '
            'stored by Care-Flash.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AppText(
                  _error!,
                  style: TextStyle(color: AppSemanticColors.of(context).danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                label: 'Pay ${formatIdr(price.total)}',
                loading: _paying,
                onPressed: (_paying || _selected == null) ? null : _pay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
