import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
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
        title: const AppText('Requests'),
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
          _StatusHeader(caregiver: caregiver),
          const SizedBox(height: AppSpacing.lg),
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

    return AppCard(
      child: Row(
        children: [
          UserAvatar(name: caregiver.name, radius: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(caregiver.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      canReceive
                          ? Icons.circle_rounded
                          : Icons.circle_outlined,
                      size: 12,
                      color: canReceive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: AppText(
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
          'Submit your Residential ID so a care seeker can trust who arrives. '
              'You also need the safety badge before requests arrive.',
          OnboardingScreen.route,
          'Start verification',
        ),
      VerificationStatus.pending => (
          'Verification in review',
          'Your Residential ID is being reviewed. Complete the safety module while '
              'you wait.',
          SafetyModuleScreen.route,
          'Open the safety module',
        ),
      VerificationStatus.rejected => (
          'Verification needs attention',
          caregiver.rejectionReason ?? 'Your submission was not accepted.',
          OnboardingScreen.route,
          'Resubmit your Residential ID',
        ),
      VerificationStatus.approved => (
          'Get your safety badge',
          'Complete the safety module to start receiving requests.',
          SafetyModuleScreen.route,
          'Open the safety module',
        ),
    };

    return AppCard(
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
                    ? AppSemanticColors.of(context).danger
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppText(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: cta, onPressed: () => context.push(route)),
        ],
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

    return AppCard(
      child: Column(
        children: [
          Icon(
            available
                ? Icons.hourglass_top_rounded
                : Icons.do_not_disturb_on_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            available ? 'Waiting for a request' : 'You are unavailable',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
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
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = booking.price;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText('New request', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(booking.requestReference,
              style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          AppText(booking.helpType.label, style: theme.textTheme.bodyLarge),
          if (booking.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              booking.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(
                  icon: Icons.schedule_rounded, label: booking.duration.label),
              _Meta(
                icon: Icons.event_rounded,
                label: _formatDate(booking.scheduledAt),
              ),
              if (price != null)
                _Meta(
                  icon: Icons.payments_outlined,
                  label: '${formatIdr(price.caregiverPrice)} to you',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'View and respond',
            onPressed: () => context.push(IncomingRequestScreen.route),
          ),
        ],
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
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        AppText(label, style: Theme.of(context).textTheme.bodySmall),
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
      BookingStatus.arrived => 'Verify the client code',
      BookingStatus.codeVerified => 'Hand over the safety button',
      BookingStatus.active => 'Open the session',
      _ => 'Open booking',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText(
                  booking.status.label,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(booking.helpType.label, style: theme.textTheme.bodyLarge),
          AppText(
            booking.location.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: action, onPressed: () => context.push(BookingScreen.route)),
        ],
      ),
    );
  }
}
