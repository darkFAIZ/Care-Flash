import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../demo/demo_controls_sheet.dart';
import '../home/home_shell.dart';
import 'matched_caregiver_screen.dart';

/// Matching status after the request is submitted. Also shows the no-match
/// fallback with a filter retry, since it is the matching step that fails.
/// (FR-CS-9)
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  static const String route = '/matching';

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  GenderFilter? _retryFilter;

  Future<void> _cancel() async {
    await ref
        .read(platformProvider)
        .cancelBooking(CancellationReason.userCancelled);
    if (mounted) {
      context.go(HomeShell.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeBookingProvider, (previous, next) {
      final booking = next.value;
      if (booking == null) {
        return;
      }
      if (booking.status == BookingStatus.matched) {
        context.go(MatchedCaregiverScreen.route);
      } else if (!booking.status.isOpen) {
        context.go(HomeShell.route);
      }
    });

    final theme = Theme.of(context);
    final booking = ref.watch(activeBookingProvider).value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppText('Finding a caregiver'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: trText(context, 'Demo controls'),
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showDemoControls(context),
            ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.page,
        child: booking == null
            ? EmptyState(
                icon: Icons.info_outline,
                title: 'No active request',
                message: 'There is nothing to match right now.',
                actionLabel: 'Back home',
                onAction: () => context.go(HomeShell.route),
              )
            : booking.status == BookingStatus.noMatch
                ? _noMatch(theme, booking)
                : _searching(theme, booking),
      ),
    );
  }

  Widget _searching(ThemeData theme, Booking booking) {
    final matched = booking.status == BookingStatus.matched;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            matched ? 'Caregiver found' : 'Looking for a nearby caregiver…',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'This usually takes under a minute. Please keep the app open.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Cancel request',
            variant: AppButtonVariant.secondary,
            onPressed: _cancel,
            expand: false,
          ),
        ],
      ),
    );
  }

  Widget _noMatch(ThemeData theme, Booking booking) {
    final selected = _retryFilter ?? booking.genderFilter;
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(Icons.search_off_rounded, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: AppSpacing.lg),
        AppText(
          'No caregiver found',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText(
          'No caregiver matches the current preference right now. Try a '
          'different gender preference, or cancel the request.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Caregiver preference'),
        const SizedBox(height: AppSpacing.xs),
        for (final filter in GenderFilter.values) ...[
          AppCard(
            compact: true,
            highlighted: selected == filter,
            onTap: () => setState(() => _retryFilter = filter),
            child: Row(
              children: [
                Icon(
                  selected == filter
                      ? Icons.check_circle_rounded
                      : Icons.person_outline,
                  color: selected == filter
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: AppText(filter.label)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Try again',
          onPressed: () =>
              ref.read(platformProvider).retryWithGenderFilter(selected),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Cancel request',
          variant: AppButtonVariant.ghost,
          onPressed: _cancel,
        ),
      ],
    );
  }
}
