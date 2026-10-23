import 'package:care_core/care_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import 'caregiver_code_screen.dart';

/// Booking status after payment and care seeker ride coordination.
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
          if (booking.status == BookingStatus.confirmed ||
              booking.status == BookingStatus.caregiverTravelling ||
              booking.status == BookingStatus.arrived) ...[
            const SizedBox(height: 16),
            _GrabRideCard(status: booking.status),
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
              if (booking.status == BookingStatus.arrived) ...[
                FilledButton.icon(
                  onPressed: () => context.push(CaregiverCodeScreen.route),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Confirm caregiver identity'),
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

class _GrabRideCard extends StatelessWidget {
  const _GrabRideCard({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrived = status == BookingStatus.arrived;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_taxi_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your Grab ride',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Icon(
                  arrived ? Icons.check_circle : Icons.schedule,
                  color: arrived
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              arrived
                  ? 'Your caregiver has arrived. Confirm their identity before starting the visit.'
                  : 'You order and pay for the caregiver’s ride directly in Grab. Ride ordering and live status are not connected in this demo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
              _row(
                context,
                'Paid in Care-Flash',
                formatIdr(booking.price!.serviceTotal),
              ),
            if (booking.price != null)
              _row(
                context,
                'Grab ride (pay in Grab)',
                formatIdr(booking.price!.grabFare),
              ),
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
                      Text(
                        update.status.label,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(update.message, style: theme.textTheme.bodySmall),
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
