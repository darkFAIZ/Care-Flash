import 'dart:async';

import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
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
    try {
      await ref.read(platformProvider).acceptRequest();
      if (mounted) context.go(HomeShell.route);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept this request: $error')),
      );
      setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Decline this request?'),
        content: const AppText(
          'The care seeker will be offered to another caregiver. Declining '
          'does not affect your rating.',
        ),
        actions: [
          AppButton(
            label: 'Keep viewing',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: 'Decline',
            expand: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(platformProvider).declineRequest();
      if (mounted) context.go(HomeShell.route);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not decline this request: $error')),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(incomingRequestProvider).value;

    if (booking == null) {
      // The request was withdrawn or expired. Send the caregiver back home.
      return Scaffold(
        appBar: AppBar(title: const AppText('Request')),
        body: const EmptyState(
          icon: Icons.info_outline,
          title: 'This request is no longer available.',
        ),
      );
    }

    final remaining = _remaining(booking);

    return Scaffold(
      appBar: AppBar(title: const AppText('Request')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  _countdownBanner(theme, remaining),
                  const SizedBox(height: AppSpacing.lg),
                  AppText(booking.requestReference,
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(booking.helpType.label,
                      style: theme.textTheme.headlineSmall),
                  if (booking.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(booking.description!,
                        style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _metaCard(theme, booking),
                  const SizedBox(height: AppSpacing.lg),
                  _ExpectedPayCard(price: booking.price),
                  const SizedBox(height: AppSpacing.lg),
                  BoundaryChecklistCard(checklist: booking.checklist),
                  const SizedBox(height: AppSpacing.lg),
                  _PrivacyNote(theme: theme),
                ],
              ),
            ),
            _actions(),
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
        padding: AppSpacing.page,
        child: Row(
          children: [
            Icon(
              urgent ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: urgent
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppText(
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: const AppText('Duration'),
            trailing: AppText(booking.duration.label),
          ),
          ListTile(
            leading: const Icon(Icons.event_rounded),
            title: const AppText('Requested for'),
            trailing: AppText(_formatDate(booking.scheduledAt)),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Decline',
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : _decline,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: 'Accept',
              onPressed: _busy ? null : _accept,
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
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('Expected caregiver pay',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  'Your service price for this visit. The care seeker pays the '
                  'Grab fare separately, so it is never deducted from your pay.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (price != null)
            AppText(
              formatIdr(price!.caregiverPrice),
              style: theme.textTheme.titleMedium,
            ),
        ],
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
        Icon(Icons.lock_outline,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppText(
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
