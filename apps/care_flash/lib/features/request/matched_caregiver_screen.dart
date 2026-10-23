import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/providers.dart';
import '../home/home_shell.dart';
import 'payment_screen.dart';
import 'widgets/price_estimate_card.dart';

/// The matched caregiver, the visit summary and the itemized price, with the
/// action that moves on to payment. (FR-CS-10)
class MatchedCaregiverScreen extends ConsumerWidget {
  const MatchedCaregiverScreen({super.key});

  static const String route = '/caregiver';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      appBar: AppBar(title: const AppText('Your caregiver')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          _CaregiverCard(caregiver: caregiver),
          const SizedBox(height: AppSpacing.lg),
          _VisitSummaryCard(booking: booking),
          const SizedBox(height: AppSpacing.lg),
          PriceEstimateCard(price: price, title: 'Price'),
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
}

class _CaregiverCard extends StatelessWidget {
  const _CaregiverCard({required this.caregiver});

  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          UserAvatar(
            name: caregiver.name,
            avatarDataUrl: caregiver.avatarDataUrl,
            radius: 36,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(caregiver.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: AppSpacing.xs),
              AppText(caregiver.ratingLabel, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              if (caregiver.identityVerified)
                const StatusChip(
                  label: 'Identity verified',
                  icon: Icons.badge_outlined,
                  tint: AppStatusTint.info,
                ),
              if (caregiver.safetyBadge)
                const StatusChip(
                  label: 'Safety trained',
                  icon: Icons.verified_user_outlined,
                  tint: AppStatusTint.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Visit details'),
          const SizedBox(height: AppSpacing.md),
          _row(context, Icons.volunteer_activism_outlined, 'Help type',
              booking.helpType.label),
          _row(context, Icons.place_outlined, 'Location',
              booking.location.label),
          _row(context, Icons.event_outlined, 'When',
              formatVisitTime(booking.scheduledAt)),
          _row(context, Icons.timer_outlined, 'Duration',
              booking.duration.label),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          AppText(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: AppText(
              value,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
