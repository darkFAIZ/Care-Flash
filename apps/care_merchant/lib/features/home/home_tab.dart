import 'package:care_core/care_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../booking/booking_screen.dart';
import '../demo/demo_controls_sheet.dart';
import '../onboarding/onboarding_screen.dart';
import '../onboarding/safety_module_screen.dart';
import '../requests/incoming_request_screen.dart';

/// The caregiver's main screen: onboarding status, an incoming request, or the
/// currently accepted booking. (FR-CM-6, FR-CM-7, FR-CM-10)
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregiver = ref.watch(caregiverStateProvider).value;
    final offer = ref.watch(incomingRequestProvider).value;
    final active = ref.watch(activeBookingProvider).value;

    if (caregiver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
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
          _StatusHeader(caregiver: caregiver),
          const SizedBox(height: 16),
          if (!_needsOnboarding(caregiver) && active != null) ...[
            _ActiveBookingCard(booking: active),
          ] else if (!_needsOnboarding(caregiver) && offer != null) ...[
            _RequestCard(booking: offer),
          ] else if (_needsOnboarding(caregiver)) ...[
            _OnboardingCard(caregiver: caregiver),
          ] else ...[
            _WaitingCard(caregiver: caregiver),
          ],
        ],
      ),
    );
  }

  bool _needsOnboarding(CaregiverAccount caregiver) =>
      !caregiver.isVerified || !caregiver.safetyModuleCompleted;
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.caregiver});

  final CaregiverAccount caregiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = caregiver.availability == CaregiverAvailability.available;
    final canReceive = caregiver.canReceiveRequests;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                caregiver.name.isNotEmpty
                    ? caregiver.name[0].toUpperCase()
                    : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caregiver.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        canReceive ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: canReceive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          canReceive
                              ? 'Available for requests'
                              : available
                              ? 'Finish onboarding to receive requests'
                              : 'Unavailable',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (caregiver.isVerified)
              Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.caregiver});

  final CaregiverAccount caregiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = caregiver.verificationStatus;

    final (title, body, route, cta) = switch (status) {
      VerificationStatus.notSubmitted => (
        'Verify your account',
        'Submit your residential ID and identity card so a care seeker can trust who arrives. '
            'You also need the safety badge before requests arrive.',
        OnboardingScreen.route,
        'Start verification',
      ),
      VerificationStatus.pending => (
        'Verification in review',
        'Your identity card is being reviewed. Complete the safety module while '
            'you wait.',
        SafetyModuleScreen.route,
        'Open the safety module',
      ),
      VerificationStatus.rejected => (
        'Verification needs attention',
        caregiver.rejectionReason ?? 'Your submission was not accepted.',
        OnboardingScreen.route,
        'Resubmit identity details',
      ),
      VerificationStatus.approved => (
        'Get your safety badge',
        'Complete the safety module to start receiving requests.',
        SafetyModuleScreen.route,
        'Open the safety module',
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == VerificationStatus.rejected
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: status == VerificationStatus.rejected
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push(route),
              child: Text(cta),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.caregiver});

  final CaregiverAccount caregiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = caregiver.availability == CaregiverAvailability.available;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              available
                  ? Icons.hourglass_top
                  : Icons.do_not_disturb_on_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              available ? 'Waiting for a request' : 'You are unavailable',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              available
                  ? 'When a care seeker nearby asks for help, the request '
                        'appears here. You have 60 seconds to respond.'
                  : 'Turn availability on in your profile to receive requests.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final foreground = dark ? scheme.onPrimaryContainer : scheme.onPrimary;
    final start = dark ? scheme.primaryContainer : scheme.primary;
    final end = dark
        ? Color.lerp(scheme.primaryContainer, scheme.tertiary, .16)!
        : const Color(0xFF34489F);
    final price = booking.price;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'New request',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.requestReference,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foreground.withValues(alpha: .8),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.helpType.label,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (booking.description != null) ...[
              const SizedBox(height: 4),
              Text(
                booking.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground.withValues(alpha: .9),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Meta(
                  icon: Icons.schedule,
                  label: booking.duration.label,
                  color: foreground.withValues(alpha: .9),
                ),
                _Meta(
                  icon: Icons.event,
                  label: _formatDate(booking.scheduledAt),
                  color: foreground.withValues(alpha: .9),
                ),
                if (price != null)
                  _Meta(
                    icon: Icons.payments_outlined,
                    label: '${formatIdr(price.caregiverPrice)} to you',
                    color: foreground.withValues(alpha: .9),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push(IncomingRequestScreen.route),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.surface,
                foregroundColor: scheme.primary,
                elevation: 0,
              ),
              child: const Text('View and respond'),
            ),
          ],
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

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = switch (booking.status) {
      BookingStatus.confirmed => 'Start your trip',
      BookingStatus.caregiverTravelling => 'Mark your arrival',
      BookingStatus.arrived => 'Share your identity code',
      BookingStatus.codeVerified => 'Hand over the safety button',
      BookingStatus.active => 'Open the session',
      _ => 'Open booking',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.status.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(booking.helpType.label, style: theme.textTheme.bodyLarge),
            Text(
              booking.location.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push(BookingScreen.route),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
