import 'dart:async';

import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import '../rating/rating_screen.dart';
import 'report_screen.dart';

/// The running care session: live status, the time spent so far, the safety
/// button notice and the actions to report a problem or end early.
/// (FR-CS-14, FR-CS-16, FR-CS-17)
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  static const String route = '/session';

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _ticker;
  DateTime? _startedAt;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _goToRating() {
    if (_navigated) {
      return;
    }
    _navigated = true;
    context.go(RatingScreen.route);
  }

  DateTime _sessionStart(Booking booking) {
    if (_startedAt != null) {
      return _startedAt!;
    }
    DateTime? start;
    for (final update in booking.updates) {
      if (update.status == BookingStatus.active) {
        start = update.at;
      }
    }
    _startedAt = start ?? booking.createdAt;
    return _startedAt!;
  }

  Future<void> _endEarly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('End the session early?'),
        content: const AppText(
          'The caregiver is paid for the time already spent. The unused part '
          'of the visit is refunded to you.',
        ),
        actions: [
          AppButton(
            label: 'Keep going',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton(
            label: 'End early',
            variant: AppButtonVariant.danger,
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(platformProvider).endEarly();
    if (mounted) {
      _goToRating();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeBookingProvider, (previous, next) {
      final wasActive = previous?.value?.status == BookingStatus.active;
      final isActive = next.value?.status == BookingStatus.active;
      if (wasActive && !isActive) {
        _goToRating();
      }
    });

    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null || booking.status != BookingStatus.active) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Session')),
        body: EmptyState(
          icon: Icons.event_available_outlined,
          title: 'There is no session running right now.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    final start = _sessionStart(booking);
    final elapsed = DateTime.now().difference(start);
    final caregiver = booking.caregiver;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppText('Session in progress'),
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
          _StatusCard(elapsed: elapsed, location: booking.location.label),
          const SizedBox(height: AppSpacing.lg),
          if (caregiver != null) ...[
            _CaregiverCard(caregiver: caregiver),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Safety button',
                  trailing: Icon(
                    Icons.shield_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  'The booking-linked safety button is with you. Press its '
                  'physical button at any time to instantly report an '
                  'emergency and end the session.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText('Help type', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                AppText(booking.helpType.label),
                const SizedBox(height: AppSpacing.md),
                AppText('Visit window', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  '${formatVisitTime(booking.scheduledAt)} · '
                  '${booking.duration.label}',
                ),
              ],
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
              // Report is red and prominent on purpose so it never reads the
              // same as End Early. (AGENTS.md §5)
              AppButton(
                label: 'Report a problem',
                icon: Icons.support_agent_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () => context.push(ReportScreen.route),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'End session early',
                icon: Icons.stop_circle_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: _endEarly,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _elapsedLabel(Duration elapsed) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(elapsed.inHours)}:${two(elapsed.inMinutes.remainder(60))}'
      ':${two(elapsed.inSeconds.remainder(60))}';
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.elapsed, required this.location});

  final Duration elapsed;
  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_run_rounded,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.sm),
                AppText(
                  'Session running',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              _elapsedLabel(elapsed),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Time spent with your caregiver',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              location,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: UserAvatar(name: caregiver.name, radius: 20),
        title: AppText(caregiver.name),
        subtitle: AppText(caregiver.ratingLabel),
        trailing: const Icon(Icons.star_rounded, color: Colors.amber),
      ),
    );
  }
}
