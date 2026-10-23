import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
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
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Your booking')),
        body: EmptyState(
          icon: Icons.info_outline,
          title: 'This booking is closed.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppText('Your booking'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: trText(context, 'Demo controls'),
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          _StatusHeader(booking: booking),
          if (booking.hasClientCode) ...[
            const SizedBox(height: AppSpacing.lg),
            _ClientCodeCard(code: booking.clientCode!),
          ],
          if (booking.caregiver != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _CaregiverRow(caregiver: booking.caregiver!),
          ],
          const SizedBox(height: AppSpacing.lg),
          _BookingDetails(booking: booking),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Status updates'),
          const SizedBox(height: AppSpacing.xs),
          _Timeline(updates: booking.updates),
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
              if (booking.canVerifyButton) ...[
                AppButton(
                  label: 'Verify safety button',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () => context.push('/scan-qr'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                label: 'Back home',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(HomeShell.route),
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
      BookingStatus.active => Icons.directions_run_rounded,
      _ => Icons.schedule_rounded,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _statusIcon(booking.status),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    booking.status.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Reference ${booking.requestReference}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (booking.cancellationReason != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText(
                booking.cancellationReason!.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.of(context).danger,
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
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pin_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              AppText('Your client code', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            code,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'Your caregiver types this code into Care-Merchant to verify you. '
            'Do not share it before they arrive; you generate it, not them.',
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
                    const SnackBar(content: AppText('Client code copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: const AppText('Copy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaregiverRow extends StatelessWidget {
  const _CaregiverRow({required this.caregiver});

  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: UserAvatar(
          name: caregiver.name,
          avatarDataUrl: caregiver.avatarDataUrl,
          radius: 20,
        ),
        title: AppText(caregiver.name),
        subtitle: AppText(caregiver.ratingLabel),
        trailing: const Icon(Icons.star_rounded, color: Colors.amber),
      ),
    );
  }
}

class _BookingDetails extends StatelessWidget {
  const _BookingDetails({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Visit details'),
          const SizedBox(height: AppSpacing.md),
          _row(context, 'Help type', booking.helpType.label),
          _row(context, 'Location', booking.location.label),
          _row(context, 'When', formatVisitTime(booking.scheduledAt)),
          _row(context, 'Duration', booking.duration.label),
          if (booking.price != null) ...[
            // The care seeker paid the ride to them as part of the total.
            // (FR-P-10, FR-P-11)
            _row(
              context,
              'Grab fare (paid by you)',
              formatIdr(booking.price!.grabFare),
            ),
            _row(context, 'Total', formatIdr(booking.price!.total)),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'The Grab fare is included in your total and passed to Grab. '
              'Your caregiver never pays for the ride.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: AppText(
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
      return AppText('No updates yet.', style: theme.textTheme.bodyMedium);
    }
    return Column(
      children: [
        for (final update in updates)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.circle_rounded,
                    size: 10,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(update.status.label,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      AppText(update.message,
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      AppText(
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
