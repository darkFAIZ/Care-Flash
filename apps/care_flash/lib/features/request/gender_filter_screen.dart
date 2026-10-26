import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import 'matching_screen.dart';
import 'request_draft.dart';
import 'widgets/price_estimate_card.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 4: caregiver gender preference and preliminary estimate matching Stitch.
class GenderFilterScreen extends ConsumerWidget {
  const GenderFilterScreen({super.key});

  static const String route = '/gender-filter';

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(requestDraftProvider);
    await ref.read(platformProvider).submitRequest(draft.toHelpRequest());
    if (context.mounted) {
      context.go(MatchingScreen.route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(requestDraftProvider);
    final controller = ref.read(requestDraftProvider.notifier);
    final duration = draft.duration ?? VisitDuration.sixty;
    final price = Pricing.breakdown(duration);

    return WizardScaffold(
      title: 'Caregiver preference',
      step: 4,
      totalSteps: 4,
      primaryLabel: 'Find a caregiver',
      primaryEnabled: draft.canSubmit,
      onPrimary: () => _submit(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preferred Caregiver Gender Card
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
                    const Icon(
                      Icons.diversity_3_rounded,
                      color: WarmEmpathyColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Preferred Caregiver',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final filter in GenderFilter.values) ...[
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.setGenderFilter(filter),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: draft.genderFilter == filter
                                  ? WarmEmpathyColors.primary.withValues(alpha: 0.1)
                                  : WarmEmpathyColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: draft.genderFilter == filter
                                    ? WarmEmpathyColors.primary
                                    : Colors.transparent,
                                width: draft.genderFilter == filter ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  switch (filter) {
                                    GenderFilter.female => Icons.female_rounded,
                                    GenderFilter.male => Icons.male_rounded,
                                    GenderFilter.both => Icons.all_inclusive_rounded,
                                  },
                                  color: draft.genderFilter == filter
                                      ? WarmEmpathyColors.primary
                                      : WarmEmpathyColors.onSurfaceVariant,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  filter.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: draft.genderFilter == filter
                                        ? WarmEmpathyColors.primary
                                        : WarmEmpathyColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (filter != GenderFilter.values.last)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Verified Caregiver Pool Spotlight
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: WarmEmpathyColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
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
                              '14 Verified Caregivers Ready',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: WarmEmpathyColors.onSurface,
                              ),
                            ),
                            Text(
                              'Average response time: 2 mins',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: WarmEmpathyColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Preliminary Estimate Card
          PriceEstimateCard(price: price, title: 'Preliminary estimate'),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'The final price is confirmed after a caregiver is matched. '
            'Payment is only taken once you approve it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: WarmEmpathyColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
