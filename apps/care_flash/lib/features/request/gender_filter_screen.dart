import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'matching_screen.dart';
import 'request_draft.dart';
import 'widgets/price_estimate_card.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 4: caregiver gender preference plus the preliminary estimate, which is
/// the last step before submitting the request. (FR-CS-7, FR-CS-8)
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
          const SectionHeader(title: 'Preferred caregiver gender'),
          const SizedBox(height: AppSpacing.sm),
          for (final filter in GenderFilter.values) ...[
            AppCard(
              highlighted: draft.genderFilter == filter,
              onTap: () => controller.setGenderFilter(filter),
              child: Row(
                children: [
                  Icon(
                    draft.genderFilter == filter
                        ? Icons.check_circle_rounded
                        : Icons.person_outline,
                    color: draft.genderFilter == filter
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
          const SizedBox(height: AppSpacing.md),
          PriceEstimateCard(price: price, title: 'Preliminary estimate'),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'The final price is confirmed after a caregiver is matched. '
            'Payment is only taken once you approve it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
