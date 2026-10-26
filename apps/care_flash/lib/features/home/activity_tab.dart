import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';

/// Activity page matching the Stitch activity_bookings design.
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  int _selectedTab = 0; // 0 = Ongoing & Upcoming, 1 = Past Bookings

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;
    final history = ref.watch(bookingHistoryProvider).value ?? const [];

    final ongoingCount = booking != null ? 1 : 0;
    final pastCount = history.length;

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
                  'Activity',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageGutter,
          vertical: AppSpacing.md,
        ),
        children: [
          // Segmented Tab Controller
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? WarmEmpathyColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: _selectedTab == 0
                            ? const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ongoing & Upcoming',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _selectedTab == 0
                                  ? WarmEmpathyColors.onPrimary
                                  : WarmEmpathyColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? WarmEmpathyColors.primaryContainer
                                  : WarmEmpathyColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '$ongoingCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _selectedTab == 0
                                    ? WarmEmpathyColors.onPrimaryContainer
                                    : WarmEmpathyColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? WarmEmpathyColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: _selectedTab == 1
                            ? const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Past Bookings',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _selectedTab == 1
                                  ? WarmEmpathyColors.onPrimary
                                  : WarmEmpathyColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? WarmEmpathyColors.primaryContainer
                                  : WarmEmpathyColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '$pastCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _selectedTab == 1
                                    ? WarmEmpathyColors.onPrimaryContainer
                                    : WarmEmpathyColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_selectedTab == 0) ...[
            // Ongoing & Upcoming View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: WarmEmpathyColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Session Now',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                if (booking != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: WarmEmpathyColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      booking.status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WarmEmpathyColors.onSecondaryFixed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (booking == null)
              _EmptyActivityCard(
                message: 'You have no ongoing activity right now.',
              )
            else
              _ActiveSessionLiveCard(booking: booking),
          ] else ...[
            // Past Bookings View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Past Care Records',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WarmEmpathyColors.onSurface,
                  ),
                ),
                Text(
                  '$pastCount Completed visits',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (history.isEmpty)
              _EmptyActivityCard(
                message: 'Your finished bookings will appear here.',
              )
            else
              ...history.map((item) => _PastBookingCard(booking: item)),
          ],
        ],
      ),
    );
  }
}

/// Live Session Tracking Card matching Stitch.
class _ActiveSessionLiveCard extends StatelessWidget {
  const _ActiveSessionLiveCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caregiver = booking.caregiver;
    final target = booking.status.isSessionStarted ? '/session' : '/caregiver';

    return InkWell(
      onTap: () => context.push(target),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: WarmEmpathyColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WarmEmpathyColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caregiver Info Header
            Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.5),
                        child: UserAvatar(
                          name: caregiver?.name ?? 'Caregiver',
                          avatarDataUrl: caregiver?.avatarDataUrl,
                          radius: 28,
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
                          size: 16,
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
                        caregiver?.name ?? 'Assigned Caregiver',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: WarmEmpathyColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.helpType.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WarmEmpathyColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: WarmEmpathyColors.amber,
                            size: 15,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            caregiver?.ratingLabel ?? '4.9',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: WarmEmpathyColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(124 visits)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WarmEmpathyColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: WarmEmpathyColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_rounded,
                        color: WarmEmpathyColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: WarmEmpathyColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: WarmEmpathyColors.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Live Countdown / Schedule Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: WarmEmpathyColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: WarmEmpathyColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: WarmEmpathyColors.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Status',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WarmEmpathyColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            booking.status.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: WarmEmpathyColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Scheduled',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WarmEmpathyColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        booking.duration.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: WarmEmpathyColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Protocol Checklist Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIVE CHECK-IN ROUTINE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: WarmEmpathyColors.surfaceBright,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WarmEmpathyColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: WarmEmpathyColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: WarmEmpathyColors.onSecondaryContainer,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Arrival & Safety Verified',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: WarmEmpathyColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '✓',
                    style: TextStyle(
                      color: WarmEmpathyColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick Actions: Emergency SOS & Family Share
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: WarmEmpathyColors.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.emergency_rounded,
                          color: WarmEmpathyColors.error,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Emergency SOS',
                          style: TextStyle(
                            color: WarmEmpathyColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: WarmEmpathyColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.share_rounded,
                          color: WarmEmpathyColors.onSecondaryFixed,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Share Visit',
                          style: TextStyle(
                            color: WarmEmpathyColors.onSecondaryFixed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Past Booking Card matching Stitch.
class _PastBookingCard extends StatelessWidget {
  const _PastBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = booking.price;
    final caregiver = booking.caregiver;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: WarmEmpathyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WarmEmpathyColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 1),
            blurRadius: 4,
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
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: WarmEmpathyColors.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(booking.createdAt),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: WarmEmpathyColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: WarmEmpathyColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSecondaryFixed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  color: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.4),
                  child: UserAvatar(
                    name: caregiver?.name ?? 'Caregiver',
                    avatarDataUrl: caregiver?.avatarDataUrl,
                    radius: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caregiver?.name ?? 'Assigned Caregiver',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                    Text(
                      '${booking.helpType.label} • ${booking.duration.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WarmEmpathyColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (price != null)
                Text(
                  formatIdr(price.total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WarmEmpathyColors.onSurface,
                  ),
                ),
            ],
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

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: WarmEmpathyColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WarmEmpathyColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: WarmEmpathyColors.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: WarmEmpathyColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
