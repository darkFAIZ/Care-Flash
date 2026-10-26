import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../booking/booking_screen.dart';
import '../demo/demo_controls_sheet.dart';
import '../onboarding/onboarding_screen.dart';
import '../onboarding/safety_module_screen.dart';
import '../requests/incoming_request_screen.dart';

/// The caregiver's main screen matching Warm Empathy Healthcare Stitch design:
/// status header, today's pulse ribbon, availability hero card, filter chips,
/// incoming request card or active session card. (FR-CM-6, FR-CM-7, FR-CM-10)
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caregiver = ref.watch(caregiverStateProvider).value;
    final offer = ref.watch(incomingRequestProvider).value;
    final active = ref.watch(activeBookingProvider).value;
    final earnings = ref.watch(earningsProvider).value;

    if (caregiver == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final available = caregiver.availability == CaregiverAvailability.available;
    final canReceive = caregiver.canReceiveRequests;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'CareMerchant',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: CareMerchantColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (caregiver.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CareMerchantColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      size: 11,
                                      color: CareMerchantColors.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Verified',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: CareMerchantColors.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: canReceive
                                    ? CareMerchantColors.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              canReceive
                                  ? 'Available for Care'
                                  : available
                                      ? 'Complete onboarding'
                                      : 'Unavailable',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // SOS Quick Tap Pill
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CareMerchant Emergency SOS ready')),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: CareMerchantColors.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emergency,
                            size: 16,
                            color: CareMerchantColors.error,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'SOS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: CareMerchantColors.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (kDebugMode)
                    IconButton(
                      tooltip: trText(context, 'Demo controls'),
                      icon: const Icon(Icons.bug_report_outlined),
                      onPressed: () => showDemoControls(context),
                    ),
                  UserAvatar(name: caregiver.name, radius: 16),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Today's Pulse Summary Ribbon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CareMerchantColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CareMerchantColors.secondaryContainer,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 18,
                        color: CareMerchantColors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Pulse",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          earnings != null && earnings.availableBalance > 0
                              ? '${earnings.earnings.length} Done • ${formatIdr(earnings.availableBalance)}'
                              : '2 Done • \$118 Earned',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CareMerchantColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: CareMerchantColors.tertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '100% Accept',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Availability Hero Toggle Card
          _AvailabilityHeroCard(
            caregiver: caregiver,
            available: available,
            canReceive: canReceive,
          ),
          const SizedBox(height: 12),

          // Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  context: context,
                  label: 'All Requests',
                  badge: offer != null ? '1' : '0',
                  isSelected: true,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  context: context,
                  label: 'Immediate / Today',
                  badge: offer != null ? '1' : '0',
                  isSelected: false,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  context: context,
                  label: 'Scheduled Later',
                  badge: '0',
                  isSelected: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Content based on State
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

  Widget _filterChip({
    required BuildContext context,
    required String label,
    required String badge,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? CareMerchantColors.primary
            : CareMerchantColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: CareMerchantColors.primary.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : CareMerchantColors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: isSelected
                    ? Colors.white
                    : CareMerchantColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityHeroCard extends ConsumerWidget {
  const _AvailabilityHeroCard({
    required this.caregiver,
    required this.available,
    required this.canReceive,
  });

  final CaregiverAccount caregiver;
  final bool available;
  final bool canReceive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final platform = ref.read(platformProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CareMerchantColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: canReceive
                            ? CareMerchantColors.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Available for requests',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: available
                                      ? CareMerchantColors.secondaryContainer
                                      : CareMerchantColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  available ? 'ON' : 'OFF',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: available
                                        ? CareMerchantColors.onSecondaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            canReceive
                                ? 'Receiving Instant Care Requests within 10 miles'
                                : 'Turn on to start receiving requests nearby',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: available,
                activeColor: CareMerchantColors.primary,
                onChanged: (val) {
                  platform.updateAvailability(
                    val
                        ? CaregiverAvailability.available
                        : CaregiverAvailability.unavailable,
                  );
                },
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radar_rounded,
                    size: 15,
                    color: CareMerchantColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'High demand in Downtown (+15% surge)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: CareMerchantColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                'Radius: 10 mi',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: CareMerchantColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
          'Submit your KTP so a care seeker can trust who arrives. '
              'You also need the safety badge before requests arrive.',
          OnboardingScreen.route,
          'Start verification',
        ),
      VerificationStatus.pending => (
          'Verification in review',
          'Your KTP is being reviewed. Complete the safety module while '
              'you wait.',
          SafetyModuleScreen.route,
          'Open the safety module',
        ),
      VerificationStatus.rejected => (
          'Verification needs attention',
          caregiver.rejectionReason ?? 'Your submission was not accepted.',
          OnboardingScreen.route,
          'Resubmit your KTP',
        ),
      VerificationStatus.approved => (
          'Get your safety badge',
          'Complete the safety module to start receiving requests.',
          SafetyModuleScreen.route,
          'Open the safety module',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CareMerchantColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == VerificationStatus.rejected
                      ? CareMerchantColors.errorContainer
                      : CareMerchantColors.secondaryContainer,
                ),
                child: Icon(
                  status == VerificationStatus.rejected
                      ? Icons.error_outline
                      : Icons.verified_user_outlined,
                  size: 18,
                  color: status == VerificationStatus.rejected
                      ? CareMerchantColors.error
                      : CareMerchantColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(route),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(cta),
          ),
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CareMerchantColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available
                  ? CareMerchantColors.secondaryContainer
                  : CareMerchantColors.surfaceContainerHigh,
            ),
            child: Icon(
              available ? Icons.radar_rounded : Icons.do_not_disturb_on_outlined,
              size: 32,
              color: available
                  ? CareMerchantColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            available ? 'Waiting for a request' : 'You are unavailable',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            available
                ? 'When a care seeker nearby asks for help, the request appears here. You have 60 seconds to respond.'
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

    return Container(
      decoration: BoxDecoration(
        color: CareMerchantColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgent Countdown Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: CareMerchantColors.errorContainer,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timelapse_rounded,
                      size: 16,
                      color: CareMerchantColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'New request • Expiring in 01:45',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: CareMerchantColors.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Auto-declines soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: CareMerchantColors.onErrorContainer.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seeker Header & Photo Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: CareMerchantColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: CareMerchantColors.primary,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: CareMerchantColors.primary,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                booking.requestReference,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: CareMerchantColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'for Care Recipient',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: CareMerchantColors.tertiary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '4.9 • 14 previous completed visits',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CareMerchantColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.helpType.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CareMerchantColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                if (booking.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    booking.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Logistics Snippet Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CareMerchantColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: CareMerchantColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Today • ${_formatDate(booking.scheduledAt)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: CareMerchantColors.primaryFixedDim.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking.duration.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: CareMerchantColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 15,
                            color: CareMerchantColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '1.2 miles away • Downtown District',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Payout Breakdown Highlight
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CareMerchantColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Total Payout',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Base fee + transit subsidy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: CareMerchantColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price != null
                                ? formatIdr(price.caregiverPrice)
                                : '\$62.00',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: CareMerchantColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Net to bank',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Household Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tagChip(
                      icon: Icons.pets,
                      label: 'Pet-friendly',
                      color: CareMerchantColors.tertiary,
                    ),
                    _tagChip(
                      icon: Icons.do_not_step,
                      label: 'Shoe-free home',
                      color: CareMerchantColors.primary,
                    ),
                    _tagChip(
                      icon: Icons.elevator,
                      label: 'Elevator access',
                      color: CareMerchantColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Actions
                FilledButton(
                  onPressed: () => context.push(IncomingRequestScreen.route),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: CareMerchantColors.primary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View and respond',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CareMerchantColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D4947),
            ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CareMerchantColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CareMerchantColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Session Live • Encrypted GPS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: CareMerchantColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'CareGuard Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CareMerchantColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.status.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            booking.helpType.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: CareMerchantColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            booking.location.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(BookingScreen.route),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
