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
import 'report_care_seeker_screen.dart';

/// The running session: a timer, the work checklist, and the complete, SOS and
/// report actions. (FR-CM-17 to FR-CM-20)
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  static const String route = '/booking/session';

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _ticker;
  bool _busy = false;
  final Set<String> _checked = {};

  @override
  void initState() {
    super.initState();
    // Refresh the timer once a second while the session runs. (FR-CM-17)
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

  DateTime _sessionStart(Booking booking) {
    for (final update in booking.updates.reversed) {
      if (update.status == BookingStatus.active) {
        return update.at;
      }
    }
    return booking.createdAt;
  }

  Future<void> _markComplete() async {
    setState(() => _busy = true);
    await ref.read(platformProvider).completeSession();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    await _showOutcome(
      title: 'Work marked complete',
      message:
          'The care seeker was notified and the visit is now in your history.',
    );
  }

  Future<void> _sos() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('Send an SOS?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText(
              'This alerts the care seeker\'s emergency contacts and support. '
              'Only use it if you are in danger.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: trText(context, 'What is happening?')),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton(
            label: 'Send SOS',
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
    final description = controller.text.trim();
    if (!mounted) {
      return;
    }
    setState(() => _busy = true);
    await ref.read(platformProvider).sos(
          description.isEmpty ? 'SOS raised during the session.' : description,
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    await _showOutcome(
      title: 'SOS sent',
      message:
          'Support and the care seeker\'s contacts were alerted. Your '
          'compensation was applied.',
    );
  }

  Future<void> _showOutcome({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: AppText(title),
        content: AppText(message),
        actions: [
          AppButton(
            label: 'Back home',
            expand: false,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(HomeShell.route);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null || !booking.isSessionActive) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const AppText('Session'),
        ),
        body: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'This session has ended.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    final start = _sessionStart(booking);
    final elapsed = DateTime.now().difference(start);
    final remaining = Duration(minutes: booking.durationMinutes) - elapsed;
    final overtime = remaining.isNegative;

    return Scaffold(
      appBar: AppBar(
        title: const AppText('Session in progress'),
        automaticallyImplyLeading: false,
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: trText(context, 'Demo controls'),
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  _TimerCard(
                    elapsed: elapsed,
                    remaining: remaining,
                    overtime: overtime,
                    theme: theme,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _workChecklist(theme, booking),
                ],
              ),
            ),
            _actions(theme),
          ],
        ),
      ),
    );
  }

  Widget _workChecklist(ThemeData theme, Booking booking) {
    final tasks = booking.checklist.allowedTasks;
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText('Work checklist', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Tick off each task as you go.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tasks.map(
            (task) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: AppText(task),
              value: _checked.contains(task),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _checked.add(task);
                } else {
                  _checked.remove(task);
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Mark work complete',
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: _busy ? null : _markComplete,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Report the care seeker',
            icon: Icons.report_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _busy
                ? null
                : () => context.push(ReportCareSeekerScreen.route),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'SOS',
            icon: Icons.sos_outlined,
            variant: AppButtonVariant.danger,
            onPressed: _busy ? null : _sos,
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.elapsed,
    required this.remaining,
    required this.overtime,
    required this.theme,
  });

  final Duration elapsed;
  final Duration remaining;
  final bool overtime;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          children: [
            Icon(
              Icons.timer_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              formatTimer(elapsed),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              overtime
                  ? 'Overtime by ${formatTimer(-remaining)}'
                  : 'Time remaining: ${formatTimer(remaining)}',
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
