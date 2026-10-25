import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
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

/// Home page: greeting, the Need Help action and the ongoing activity card.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final booking = ref.watch(activeBookingProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const AppText('Care-Flash'),
        actions: [
          IconButton(
            tooltip: trText(context, 'Help and support'),
            onPressed: () => context.push(HelpSupportScreen.route),
            icon: const Icon(Icons.support_agent_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: AppSpacing.page,
            children: [
              AppText(
                'Hi, ${user?.name.split(' ').first ?? 'there'}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                'How can we help you today?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NeedHelpCard(
                onTap: () {
                  if (booking != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: AppText(
                          'You already have an ongoing request.',
                        ),
                      ),
                    );
                    context.push(_ongoingRoute(booking));
                    return;
                  }
                  ref.read(requestDraftProvider.notifier).reset();
                  context.push(HelpRequestScreen.route);
                },
              ),
              if (booking != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Ongoing activity'),
                const SizedBox(height: AppSpacing.xs),
                _OngoingActivityCard(booking: booking),
              ],
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Quick actions'),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.credit_card_rounded,
                      label: 'Payment info',
                      onTap: () => context.push(PaymentInfoScreen.route),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.support_agent_rounded,
                      label: 'Help & support',
                      onTap: () => context.push(HelpSupportScreen.route),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 36,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              'Need help?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Request a nearby verified caregiver for a short visit.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Start a request',
              icon: Icons.add_rounded,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingActivityCard extends StatelessWidget {
  const _OngoingActivityCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caregiver = booking.caregiver;
    final target = _ongoingRoute(booking);
    final localizations = MaterialLocalizations.of(context);
    final visitDate = localizations.formatMediumDate(booking.scheduledAt);
    final visitTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(booking.scheduledAt),
    );
    return AppCard(
      onTap: () => context.push(target),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: StatusChip(
                  label: booking.status.label,
                  tint: AppStatusTint.info,
                  icon: booking.status.isSessionStarted
                      ? Icons.favorite_rounded
                      : Icons.schedule_rounded,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            caregiver?.name ?? booking.helpType.label,
            style: theme.textTheme.titleMedium,
          ),
          if (caregiver != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(booking.helpType.label, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _VisitDetail(
                icon: Icons.place_outlined,
                label: booking.location.label,
              ),
              _VisitDetail(icon: Icons.event_outlined, label: visitDate),
              _VisitDetail(
                icon: Icons.schedule_outlined,
                label: '$visitTime · ${booking.duration.label}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'Ref ${booking.requestReference}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.arrow_outward_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText(
                  'View booking details',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitDetail extends StatelessWidget {
  const _VisitDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        AppText(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      compact: true,
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: AppSpacing.sm),
          AppText(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
