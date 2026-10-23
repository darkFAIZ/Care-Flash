import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

/// Read-only view of the care seeker's boundary checklist. (FR-CS-8, FR-CM-8)
///
/// Shared by the incoming request detail and the accepted booking screen so the
/// caregiver always sees the same boundaries.
class BoundaryChecklistCard extends StatelessWidget {
  const BoundaryChecklistCard({super.key, required this.checklist});

  final BoundaryChecklist checklist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText('Boundary checklist', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (checklist.allowedTasks.isNotEmpty) ...[
            AppText('Allowed', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...checklist.allowedTasks.map(
              (task) => _line(theme, Icons.check_circle_outline, task),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (checklist.disallowedTasks.isNotEmpty) ...[
            AppText('Not allowed', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...checklist.disallowedTasks.map(
              (task) => _line(theme, Icons.cancel_outlined, task),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (checklist.offLimitRooms.isNotEmpty) ...[
            AppText('Off limits', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...checklist.offLimitRooms.map(
              (room) => _line(theme, Icons.meeting_room_outlined, room.label),
            ),
            if (checklist.offLimitNote != null &&
                checklist.offLimitNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  left: 28,
                ),
                child: AppText(
                  checklist.offLimitNote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _line(ThemeData theme, IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppText(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}
