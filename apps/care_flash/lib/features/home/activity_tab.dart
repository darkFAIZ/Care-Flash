import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

/// Activity page: the ongoing activity and past bookings.
class ActivityTab extends ConsumerWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(activeBookingProvider).value;
    final history = ref.watch(bookingHistoryProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const AppText('Activity')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          const SectionHeader(title: 'Ongoing activity'),
          const SizedBox(height: AppSpacing.xs),
          if (booking == null)
            _EmptyCard(
              message: 'You have no ongoing activity right now.',
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: AppText(booking.status.label),
                subtitle: AppText(booking.helpType.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(
                  booking.status.isSessionStarted ? '/session' : '/caregiver',
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Past bookings'),
          const SizedBox(height: AppSpacing.xs),
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
    final theme = Theme.of(context);
    return AppCard(
      compact: true,
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: AppText(message)),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.history_rounded),
          title: AppText(booking.helpType.label),
          isThreeLine: showPayment,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '${booking.status.label} · ${_formatDate(booking.createdAt)}',
              ),
              if (showPayment) ...[
                const SizedBox(height: AppSpacing.xs),
                _PaymentLine(booking: booking),
              ],
            ],
          ),
          trailing: price == null
              ? null
              : AppText(
                  formatIdr(price.total),
                  style: theme.textTheme.bodyMedium,
                ),
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
          Icon(Icons.replay_rounded, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: AppText(
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
    return AppText(
      booking.paymentStatus!.label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
