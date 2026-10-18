import 'dart:async';

import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../common/boundary_checklist_card.dart';
import '../home/home_shell.dart';

/// The incoming request detail with the accept and decline actions. (FR-CM-7 to
/// FR-CM-9)
///
/// The care seeker's location and private client code are deliberately not
/// shown here, because the caregiver must not see them before accepting.
/// (FR-CM-8, UI-CM-2, DC-CM-2)
class IncomingRequestScreen extends ConsumerStatefulWidget {
  const IncomingRequestScreen({super.key});

  static const String route = '/request';

  @override
  ConsumerState<IncomingRequestScreen> createState() =>
      _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends ConsumerState<IncomingRequestScreen> {
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Refresh the countdown once a second while the request is offered.
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

  Future<void> _accept() async {
    setState(() => _busy = true);
    await ref.read(platformProvider).acceptRequest();
    if (!mounted) {
      return;
    }
    context.go(HomeShell.route);
  }

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline this request?'),
        content: const Text(
          'The care seeker will be offered to another caregiver. Declining '
          'does not affect your rating.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep viewing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    await ref.read(platformProvider).declineRequest();
    if (!mounted) {
      return;
    }
    context.go(HomeShell.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(incomingRequestProvider).value;

    if (booking == null) {
      // The request was withdrawn or expired. Send the caregiver back home.
      return Scaffold(
        appBar: AppBar(title: const Text('Request')),
        body: const Center(child: Text('This request is no longer available.')),
      );
    }

    final remaining = _remaining(booking);

    return Scaffold(
      appBar: AppBar(title: const Text('Request')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _countdownBanner(theme, remaining),
                  const SizedBox(height: 16),
                  Text(booking.requestReference,
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(booking.helpType.label,
                      style: theme.textTheme.headlineSmall),
                  if (booking.description != null) ...[
                    const SizedBox(height: 8),
                    Text(booking.description!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: 16),
                  _metaCard(theme, booking),
                  const SizedBox(height: 16),
                  _ExpectedPayCard(price: booking.price),
                  const SizedBox(height: 16),
                  BoundaryChecklistCard(checklist: booking.checklist),
                  const SizedBox(height: 16),
                  _PrivacyNote(theme: theme),
                ],
              ),
            ),
            _actions(theme),
          ],
        ),
      ),
    );
  }

  Duration _remaining(Booking booking) {
    final deadline = booking.createdAt
        .add(PlatformPolicy.caregiverResponseTimeout);
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Widget _countdownBanner(ThemeData theme, Duration remaining) {
    final seconds = remaining.inSeconds;
    final urgent = seconds <= 15;
    return Card(
      color: urgent
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              urgent ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: urgent
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                seconds > 0
                    ? 'Respond within ${_formatDuration(remaining)}'
                    : 'The response window has closed.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: urgent
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  Widget _metaCard(ThemeData theme, Booking booking) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Duration'),
            trailing: Text(booking.duration.label),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Requested for'),
            trailing: Text(_formatDate(booking.scheduledAt)),
          ),
        ],
      ),
    );
  }

  Widget _actions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : _decline,
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _busy ? null : _accept,
              child: const Text('Accept'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _ExpectedPayCard extends StatelessWidget {
  const _ExpectedPayCard({required this.price});

  final PriceBreakdown? price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expected caregiver pay',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Your service price for this visit. The platform fee and '
                    'Grab fare are handled separately.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (price != null)
              Text(
                formatIdr(price!.caregiverPrice),
                style: theme.textTheme.titleMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'For privacy, the care seeker\'s location and verification code stay '
            'hidden until you accept the request.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
