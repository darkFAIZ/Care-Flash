import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

/// Activity page: the ongoing activity and past bookings.
class ActivityTab extends ConsumerWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;
    final history = ref.watch(bookingHistoryProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ongoing activity', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (booking == null)
            _EmptyCard(message: 'You have no ongoing activity right now.')
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(booking.status.label),
                subtitle: Text(booking.helpType.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  booking.status.isSessionStarted ? '/session' : '/caregiver',
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Past bookings', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (history.isEmpty)
            _EmptyCard(message: 'Your finished bookings will appear here.')
          else
            ...history.map((item) => _HistoryCard(booking: item)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = booking.price;
    final showPayment = booking.paymentStatus != null || booking.hasRefund;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(booking.helpType.label),
        isThreeLine: showPayment,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${booking.status.label} · ${_formatDate(booking.createdAt)}'),
            if (showPayment) ...[
              const SizedBox(height: 4),
              _PaymentLine(booking: booking),
            ],
          ],
        ),
        trailing: price == null
            ? null
            : Text(
                formatIdr(price.serviceTotal),
                style: theme.textTheme.bodyMedium,
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Shows the refund or payment status of a finished booking. (FR-CS-12,
/// FR-CS-17, FR-P-23)
class _PaymentLine extends StatelessWidget {
  const _PaymentLine({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (booking.hasRefund) {
      final full = booking.isRefunded;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${full ? 'Refunded' : 'Partly refunded'} · '
              '${formatIdr(booking.refundAmount!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      booking.paymentStatus!.label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
