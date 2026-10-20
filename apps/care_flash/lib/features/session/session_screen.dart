import 'dart:async';

import 'package:care_core/care_core.dart';
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
        title: const Text('End the session early?'),
        content: const Text(
          'The caregiver is paid for the time already spent. The unused part '
          'of the visit is refunded to you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End early'),
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
        appBar: AppBar(title: const Text('Session')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'There is no session running right now.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(HomeShell.route),
                  child: const Text('Back home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final start = _sessionStart(booking);
    final elapsed = DateTime.now().difference(start);
    final caregiver = booking.caregiver;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Session in progress'),
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
          _StatusCard(elapsed: elapsed, location: booking.location.label),
          const SizedBox(height: 16),
          if (caregiver != null) ...[
            _CaregiverCard(caregiver: caregiver),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Safety button',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
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
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Help type', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(booking.helpType.label),
                  const SizedBox(height: 12),
                  Text('Visit window', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${formatVisitTime(booking.scheduledAt)} · '
                    '${booking.duration.label}',
                  ),
                ],
              ),
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
              FilledButton.icon(
                onPressed: () => context.push(ReportScreen.route),
                icon: const Icon(Icons.support_agent),
                label: const Text('Report a problem'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _endEarly,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('End session early'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_run,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Session running',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _elapsedLabel(elapsed),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Time spent with your caregiver',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
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
