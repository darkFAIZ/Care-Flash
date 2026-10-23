import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../home/home_shell.dart';
import 'payment_screen.dart';
import 'widgets/price_breakdown_card.dart';

/// The matched caregiver, the visit summary and the itemized price, with the
/// action that moves on to payment. (FR-CS-10)
class MatchedCaregiverScreen extends ConsumerWidget {
  const MatchedCaregiverScreen({super.key});

  static const String route = '/caregiver';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null || booking.caregiver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your caregiver')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text('This booking is no longer active.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(HomeShell.route),
                child: const Text('Back home'),
              ),
            ],
          ),
        ),
      );
    }

    final caregiver = booking.caregiver!;
    final price = booking.price ?? Pricing.breakdown(booking.duration);

    return Scaffold(
      appBar: AppBar(title: const Text('Your caregiver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CaregiverCard(caregiver: caregiver),
          const SizedBox(height: 16),
          _VisitSummaryCard(booking: booking),
          const SizedBox(height: 16),
          PriceBreakdownCard(price: price, title: 'Price'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: () => context.go(PaymentScreen.route),
            child: Text(
              'Continue to payment · ${formatIdr(price.serviceTotal)}',
            ),
          ),
        ),
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  const _CaregiverCard({required this.caregiver});

  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                caregiver.name.isNotEmpty
                    ? caregiver.name[0].toUpperCase()
                    : '?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(caregiver.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 4),
                Text(caregiver.ratingLabel, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (caregiver.identityVerified)
                  const Chip(
                    avatar: Icon(Icons.school_outlined, size: 18),
                    label: Text('Identity verified'),
                  ),
                if (caregiver.safetyBadge)
                  const Chip(
                    avatar: Icon(Icons.verified_user_outlined, size: 18),
                    label: Text('Safety trained'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Visit details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(
              context,
              Icons.volunteer_activism_outlined,
              'Help type',
              booking.helpType.label,
            ),
            _row(
              context,
              Icons.place_outlined,
              'Location',
              booking.location.label,
            ),
            _row(
              context,
              Icons.event_outlined,
              'When',
              formatVisitTime(booking.scheduledAt),
            ),
            _row(
              context,
              Icons.timer_outlined,
              'Duration',
              booking.duration.label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
