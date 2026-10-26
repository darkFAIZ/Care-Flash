import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'boundary_checklist_screen.dart';
import 'request_draft.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 1: choose the type of help and add a short note matching Stitch start_care_request_1_4.
class HelpRequestScreen extends ConsumerStatefulWidget {
  const HelpRequestScreen({super.key});

  static const String route = '/help-request';

  @override
  ConsumerState<HelpRequestScreen> createState() => _HelpRequestScreenState();
}

class _HelpRequestScreenState extends ConsumerState<HelpRequestScreen> {
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(
      text: ref.read(requestDraftProvider).description,
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(requestDraftProvider);
    final controller = ref.read(requestDraftProvider.notifier);

    return WizardScaffold(
      title: 'What do you need?',
      step: 1,
      totalSteps: 4,
      primaryLabel: 'Next: boundaries',
      primaryEnabled: draft.helpType != null,
      onPrimary: () => context.push(BoundaryChecklistScreen.route),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.diversity_1_rounded,
                      color: WarmEmpathyColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Select Care Support',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Required',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WarmEmpathyColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the primary focus of your visit today. You can personalize extra details below.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: WarmEmpathyColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Help Type Cards
            for (final type in HelpType.values) ...[
              _HelpTypeOptionCard(
                type: type,
                selected: draft.helpType == type,
                onTap: () => controller.setHelpType(type),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.md),

            // Optional Caregiver Notes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: WarmEmpathyColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Optional Notes for Caregiver',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Encouraged',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: WarmEmpathyColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: WarmEmpathyColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Add sensitive details, entry codes, or loved one preferences...',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.outline,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: controller.setDescription,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTypeOptionCard extends StatelessWidget {
  const _HelpTypeOptionCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final HelpType type;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (type) {
        HelpType.takeCare => Icons.volunteer_activism_rounded,
        HelpType.dropMedicine => Icons.medication_rounded,
        HelpType.feelUnsafe => Icons.health_and_safety_rounded,
        HelpType.emotionalSupport => Icons.sentiment_satisfied_alt_rounded,
      };

  String get _description => switch (type) {
        HelpType.takeCare =>
          'Daily assistance, warm companionship, mealtime company & gentle senior check-in.',
        HelpType.dropMedicine =>
          'Prescription pharmacy pick-up, secure doorstep delivery, and scheduled dosage reminder.',
        HelpType.feelUnsafe =>
          'Safety escort to clinic or home, calm physical presence, watchful eye & de-escalation.',
        HelpType.emotionalSupport =>
          'Empathetic active listening, anxiety grounding, quiet companionship, and heartfelt comfort.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? WarmEmpathyColors.primary.withValues(alpha: 0.06)
              : WarmEmpathyColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? WarmEmpathyColors.primary
                : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? WarmEmpathyColors.primary
                      : WarmEmpathyColors.outlineVariant,
                  width: selected ? 6 : 2,
                ),
                color: selected
                    ? WarmEmpathyColors.primary
                    : Colors.transparent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _icon,
                            size: 18,
                            color: selected
                                ? WarmEmpathyColors.primary
                                : WarmEmpathyColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? WarmEmpathyColors.primary
                                  : WarmEmpathyColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (type == HelpType.takeCare)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: WarmEmpathyColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Most Popular',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WarmEmpathyColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WarmEmpathyColors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
