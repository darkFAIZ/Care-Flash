import 'package:care_core/care_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';

/// Booking status after payment, together with the private client code the care
/// seeker shows on arrival. (FR-CS-12, FR-CS-21)
class ConfirmedScreen extends ConsumerWidget {
  const ConfirmedScreen({super.key});

  static const String route = '/confirmed';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your booking')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 56),
              const SizedBox(height: 16),
              const Text('This booking is closed.'),
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your booking'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Demo controls',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusHeader(booking: booking),
          if (booking.hasClientCode) ...[
            const SizedBox(height: 16),
            _ClientCodeCard(code: booking.clientCode!),
          ],
          if (booking.caregiver != null) ...[
            const SizedBox(height: 16),
            _CaregiverRow(caregiver: booking.caregiver!),
          ],
          const SizedBox(height: 16),
          _BookingDetails(booking: booking),
          const SizedBox(height: 16),
          Text('Status updates', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _Timeline(updates: booking.updates),
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
              if (booking.canVerifyButton) ...[
                FilledButton.icon(
                  onPressed: () => context.push('/scan-qr'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Verify safety button'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => context.go(HomeShell.route),
                child: const Text('Back home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _statusIcon(BookingStatus status) => switch (status) {
      BookingStatus.cancelled => Icons.cancel_outlined,
      BookingStatus.completed => Icons.check_circle_outline,
      BookingStatus.endedEarly => Icons.timer_off_outlined,
      BookingStatus.reported => Icons.report_outlined,
      BookingStatus.caregiverSos => Icons.sos_outlined,
      BookingStatus.active => Icons.directions_run,
      _ => Icons.schedule,
    };

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _statusIcon(booking.status),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.status.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reference ${booking.requestReference}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (booking.cancellationReason != null) ...[
              const SizedBox(height: 4),
              Text(
                booking.cancellationReason!.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClientCodeCard extends StatelessWidget {
  const _ClientCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.pin_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Your client code', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              code,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Show this code to your caregiver when they arrive. Do not share '
              'it before then.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client code copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverRow extends StatelessWidget {
  const _CaregiverRow({required this.caregiver});

  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(caregiver.name.isNotEmpty ? caregiver.name[0] : '?'),
        ),
        title: Text(caregiver.name),
        subtitle: Text(caregiver.ratingLabel),
        trailing: const Icon(Icons.star, color: Colors.amber),
      ),
    );
  }
}

class _BookingDetails extends StatelessWidget {
  const _BookingDetails({required this.booking});

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
            _row(context, 'Help type', booking.helpType.label),
            _row(context, 'Location', booking.location.label),
            _row(context, 'When', formatVisitTime(booking.scheduledAt)),
            _row(context, 'Duration', booking.duration.label),
            if (booking.price != null)
              _row(context, 'Total', formatIdr(booking.price!.total)),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.updates});

  final List<BookingUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (updates.isEmpty) {
      return Text('No updates yet.', style: theme.textTheme.bodyMedium);
    }
    return Column(
      children: [
        for (final update in updates)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.circle,
                    size: 10,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(update.status.label,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(update.message,
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        formatClock(update.at),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
