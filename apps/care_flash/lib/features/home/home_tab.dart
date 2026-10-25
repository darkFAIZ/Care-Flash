import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../payment_info/payment_info_screen.dart';
import '../request/confirmed_screen.dart';
import '../request/help_request_screen.dart';
import '../request/matched_caregiver_screen.dart';
import '../request/matching_screen.dart';
import '../request/request_draft.dart';
import '../support/help_support_screen.dart';

/// The screen the ongoing-activity card should open for [booking]. (FR-CS-21)
String _ongoingRoute(Booking booking) {
  if (booking.status.isSessionStarted) {
    return '/session';
  }
  return switch (booking.status) {
    BookingStatus.matching || BookingStatus.noMatch => MatchingScreen.route,
    BookingStatus.matched => MatchedCaregiverScreen.route,
    _ => ConfirmedScreen.route,
  };
}

/// Home page matching the Stitch care_seeker_home design.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final booking = ref.watch(activeBookingProvider).value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.pageGutter,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: WarmEmpathyColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: WarmEmpathyColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CarePulse',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: WarmEmpathyColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Home',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: trText(context, 'Help and support'),
            onPressed: () => context.push(HelpSupportScreen.route),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: WarmEmpathyColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: WarmEmpathyColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.md,
        ),
        children: [
          // Greeting Header
          Row(
            children: [
              Text(
                'Hi, ${user?.name.split(' ').first ?? 'there'}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WarmEmpathyColors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'How can we help you today?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: WarmEmpathyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Recent Activity Snippet Banner if booking exists
          if (booking != null) ...[
            _OngoingActivityBanner(booking: booking),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Primary Highlight Card (Need Help / In-home care)
          _NeedHelpCard(
            onTap: () {
              if (booking != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: AppText('You already have an ongoing request.'),
                  ),
                );
                context.push(_ongoingRoute(booking));
                return;
              }
              ref.read(requestDraftProvider.notifier).reset();
              context.push(HelpRequestScreen.route);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Quick Actions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WarmEmpathyColors.onSurface,
                ),
              ),
              Text(
                'All shortcuts',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: WarmEmpathyColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Actions Grid (2-column cards)
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.credit_card_rounded,
                  title: 'Payment Info',
                  subtitle: 'Manage cards & credits',
                  badge: 'Visa ••4821',
                  onTap: () => context.push(PaymentInfoScreen.route),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  subtitle: 'Chat with CarePulse Assistant',
                  badge: 'Live',
                  isLive: true,
                  onTap: () => context.push(HelpSupportScreen.route),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Verified Caregiver Showcase
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Caregivers Near You',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: WarmEmpathyColors.onSurface,
                ),
              ),
              Text(
                'Browse 42',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: WarmEmpathyColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WarmEmpathyColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.5),
                    child: const Icon(
                      Icons.person_rounded,
                      color: WarmEmpathyColors.secondary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Evelyn Ross, RN',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: WarmEmpathyColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: WarmEmpathyColors.secondary,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Post-op & Senior Mobility Support',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WarmEmpathyColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: WarmEmpathyColors.amber,
                            size: 15,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '4.9 (118)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: WarmEmpathyColors.tertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: WarmEmpathyColors.outline)),
                          const SizedBox(width: 6),
                          Text(
                            '0.8 miles away',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WarmEmpathyColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Emergency SOS Direct Contact Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: WarmEmpathyColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: WarmEmpathyColors.onError,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency SOS',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: WarmEmpathyColors.onErrorContainer,
                        ),
                      ),
                      Text(
                        'Tap for 24/7 Crisis Dispatch',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WarmEmpathyColors.onErrorContainer.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.call_rounded, color: WarmEmpathyColors.onError, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Call',
                        style: TextStyle(
                          color: WarmEmpathyColors.onError,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Recent Activity Snippet Banner matching Stitch.
class _OngoingActivityBanner extends StatelessWidget {
  const _OngoingActivityBanner({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caregiver = booking.caregiver;
    final target = _ongoingRoute(booking);

    return InkWell(
      onTap: () => context.push(target),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: WarmEmpathyColors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: WarmEmpathyColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: WarmEmpathyColors.onSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ONGOING & UPCOMING VISIT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WarmEmpathyColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caregiver == null
                        ? '${booking.status.label} • Ref ${booking.requestReference}'
                        : '${booking.status.label} • ${caregiver.name}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: WarmEmpathyColors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: WarmEmpathyColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Text(
                'View Details',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: WarmEmpathyColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary Highlight Card ("Need in-home care?") matching Stitch gradient style.
class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WarmEmpathyColors.primary,
            WarmEmpathyColors.primaryContainer,
            WarmEmpathyColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: WarmEmpathyColors.primary.withValues(alpha: 0.25),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: WarmEmpathyColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Fast matching',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Need in-home care?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Request a nearby verified caregiver for a short visit, routine companionship, or nursing assistance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: WarmEmpathyColors.onPrimaryContainer,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WarmEmpathyColors.surfaceContainerLowest,
                foregroundColor: WarmEmpathyColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Start a request',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action 2-column card matching Stitch.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.isLive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final bool isLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: WarmEmpathyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: WarmEmpathyColors.primary,
                    size: 20,
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: WarmEmpathyColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: WarmEmpathyColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WarmEmpathyColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WarmEmpathyColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (!isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: WarmEmpathyColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Text(
                    'Start chat',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WarmEmpathyColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: WarmEmpathyColors.primary,
                    size: 14,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
