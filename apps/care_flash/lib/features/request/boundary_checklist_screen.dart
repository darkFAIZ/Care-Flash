import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'request_draft.dart';
import 'schedule_screen.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 2: allowed tasks, off-limits tasks and off-limit rooms matching Stitch. (FR-CS-5)
class BoundaryChecklistScreen extends ConsumerStatefulWidget {
  const BoundaryChecklistScreen({super.key});

  static const String route = '/boundaries';

  @override
  ConsumerState<BoundaryChecklistScreen> createState() =>
      _BoundaryChecklistScreenState();
}

class _BoundaryChecklistScreenState
    extends ConsumerState<BoundaryChecklistScreen> {
  late Set<String> _allowed;
  late Set<String> _disallowed;
  late Set<OffLimitRoom> _offLimit;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final existing =
        ref.read(requestDraftProvider).checklist ?? BoundaryChecklist.suggested;
    _allowed = {...existing.allowedTasks};
    _disallowed = {...existing.disallowedTasks};
    _offLimit = {...existing.offLimitRooms};
    _note = TextEditingController(text: existing.offLimitNote ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(requestDraftProvider.notifier).setChecklist(
          BoundaryChecklist(
            allowedTasks: _allowed.toList(),
            disallowedTasks: _disallowed.toList(),
            offLimitRooms: _offLimit.toList(),
            offLimitNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
        );
    context.push(ScheduleScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WizardScaffold(
      title: 'Set your boundaries',
      step: 2,
      totalSteps: 4,
      primaryLabel: 'Next: schedule',
      primaryEnabled: _allowed.isNotEmpty,
      onPrimary: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Allowed Tasks Card
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
                      Icons.check_circle_rounded,
                      color: WarmEmpathyColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Allowed & Encouraged',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tick what the caregiver may do. (FR-CS-5)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final task in BoundaryChecklist.standardAllowedTasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: WarmEmpathyColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: CheckboxListTile(
                        value: _allowed.contains(task),
                        title: Text(
                          task,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: WarmEmpathyColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: WarmEmpathyColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        onChanged: (checked) => setState(() {
                          checked == true ? _allowed.add(task) : _allowed.remove(task);
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Strict Boundaries Card
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
                      Icons.cancel_rounded,
                      color: WarmEmpathyColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Strict Boundaries',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Kept off limits for your safety.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WarmEmpathyColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final task in BoundaryChecklist.standardDisallowedTasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: WarmEmpathyColors.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: CheckboxListTile(
                        value: _disallowed.contains(task),
                        title: Text(
                          task,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: WarmEmpathyColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: WarmEmpathyColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        onChanged: (checked) => setState(() {
                          checked == true
                              ? _disallowed.add(task)
                              : _disallowed.remove(task);
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Off-Limit Rooms Card
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
                      Icons.do_not_disturb_on_rounded,
                      color: WarmEmpathyColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Designated Off-Limit Areas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final room in OffLimitRoom.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: WarmEmpathyColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: CheckboxListTile(
                        value: _offLimit.contains(room),
                        title: Text(
                          room.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: WarmEmpathyColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: WarmEmpathyColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        onChanged: (checked) => setState(() {
                          checked == true ? _offLimit.add(room) : _offLimit.remove(room);
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Special Instructions
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: WarmEmpathyColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WarmEmpathyColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Boundaries / Special Instructions',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: WarmEmpathyColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: WarmEmpathyColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    controller: _note,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: WarmEmpathyColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Ring buzzer twice, park in visitor slot 12',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: WarmEmpathyColors.outline,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
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
