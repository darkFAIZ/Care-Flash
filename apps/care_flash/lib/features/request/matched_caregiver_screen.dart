import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../home/home_shell.dart';
import 'payment_screen.dart';
import 'widgets/price_estimate_card.dart';

/// The matched caregiver, visit summary and price matching caregiver_match_summary.
class MatchedCaregiverScreen extends ConsumerWidget {
  const MatchedCaregiverScreen({super.key});

  static const String route = '/caregiver';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    if (booking == null || booking.caregiver == null) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Your caregiver')),
        body: EmptyState(
          icon: Icons.info_outline,
          title: 'This booking is no longer active.',
          actionLabel: 'Back home',
          onAction: () => context.go(HomeShell.route),
        ),
      );
    }

    final caregiver = booking.caregiver!;
    final price = booking.price ?? Pricing.breakdown(booking.duration);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.pageGutter,
        title: Row(
          children: [
            Text(
              'Your caregiver',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: WarmEmpathyColors.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.sm,
        ),
        children: [
          // Celebration / Confirmed Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WarmEmpathyColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: WarmEmpathyColors.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: WarmEmpathyColors.secondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'BOOKING #${booking.requestReference}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WarmEmpathyColors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Caregiver Found & Confirmed!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WarmEmpathyColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${caregiver.name} has accepted your request and is preparing for today\'s visit.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Caregiver Details Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WarmEmpathyColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 68,
                            height: 68,
                            color: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.4),
                            child: UserAvatar(
                              name: caregiver.name,
                              avatarDataUrl: caregiver.avatarDataUrl,
                              radius: 34,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: WarmEmpathyColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: WarmEmpathyColors.secondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caregiver.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: WarmEmpathyColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: WarmEmpathyColors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                caregiver.ratingLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: WarmEmpathyColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(142 reviews)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: WarmEmpathyColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: WarmEmpathyColors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Responds in ~2 mins',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: WarmEmpathyColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (caregiver.identityVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WarmEmpathyColors.secondaryFixed.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: WarmEmpathyColors.onSecondaryFixedVariant,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Identity ✓',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: WarmEmpathyColors.onSecondaryFixedVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (caregiver.safetyBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WarmEmpathyColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.medical_services_rounded,
                              color: WarmEmpathyColors.onSecondaryContainer,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Safety & First-Aid Certified ✓',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: WarmEmpathyColors.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '“Compassionate licensed caregiver with 6+ years supporting seniors and post-recovery patients. Calm, punctual, and attentive.”',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WarmEmpathyColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Visit Details Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WarmEmpathyColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visit Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: WarmEmpathyColors.primaryFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'On Schedule',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WarmEmpathyColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _detailTile(
                  context,
                  icon: Icons.volunteer_activism_rounded,
                  label: 'TYPE OF HELP',
                  value: booking.helpType.label,
                ),
                const SizedBox(height: AppSpacing.sm),
                _detailTile(
                  context,
                  icon: Icons.calendar_month_rounded,
                  label: 'SCHEDULE',
                  value: formatVisitTime(booking.scheduledAt),
                ),
                const SizedBox(height: AppSpacing.sm),
                _detailTile(
                  context,
                  icon: Icons.location_on_rounded,
                  label: 'LOCATION',
                  value: booking.location.label,
                ),
                const SizedBox(height: AppSpacing.sm),
                _detailTile(
                  context,
                  icon: Icons.door_front_door_rounded,
                  label: 'HOUSEHOLD PREFERENCES',
                  value: 'Shoe-free home, tea prep allowed, off-limits rooms respected',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Price Breakdown Card
          PriceEstimateCard(price: price, title: 'Price'),
          const SizedBox(height: AppSpacing.lg),
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
          child: AppButton(
            onPressed: () => context.go(PaymentScreen.route),
            label: 'Continue to payment · ${formatIdr(price.total)}',
          ),
        ),
      ),
    );
  }

  Widget _detailTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: WarmEmpathyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: WarmEmpathyColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: WarmEmpathyColors.onSecondaryContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: WarmEmpathyColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
