import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'confirmed_screen.dart';
import 'widgets/price_breakdown_card.dart';

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
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: Text('This booking is no longer active.')),
      );
    }

    if (!booking.isPayable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This booking has already been paid.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(ConfirmedScreen.route),
                child: const Text('View booking'),
              ),
            ],
          ),
        ),
      );
    }

    final price = booking.price ?? Pricing.breakdown(booking.duration);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PriceBreakdownCard(price: price, title: 'Amount due'),
          const SizedBox(height: 16),
          Text('Payment method', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final method in methods) ...[
            Card(
              color: _selected?.id == method.id
                  ? theme.colorScheme.secondaryContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  _selected?.id == method.id
                      ? Icons.check_circle
                      : Icons.account_balance_wallet_outlined,
                  color: _selected?.id == method.id
                      ? theme.colorScheme.primary
                      : null,
                ),
                title: Text(method.displayLabel),
                onTap: _paying
                    ? null
                    : () => setState(() => _selected = method),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text(
            'Demo checkout only: this confirms the booking in Supabase but '
            'does not charge a real payment method.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: (_paying || _selected == null) ? null : _pay,
                child: _paying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Pay ${formatIdr(price.serviceTotal)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
