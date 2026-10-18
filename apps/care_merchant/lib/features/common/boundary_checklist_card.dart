import 'package:care_core/care_core.dart';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Boundary checklist', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (checklist.allowedTasks.isNotEmpty) ...[
              Text('Allowed', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ...checklist.allowedTasks.map(
                (task) => _line(theme, Icons.check_circle_outline, task),
              ),
              const SizedBox(height: 12),
            ],
            if (checklist.disallowedTasks.isNotEmpty) ...[
              Text('Not allowed', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ...checklist.disallowedTasks.map(
                (task) => _line(theme, Icons.cancel_outlined, task),
              ),
              const SizedBox(height: 12),
            ],
            if (checklist.offLimitRooms.isNotEmpty) ...[
              Text('Off limits', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ...checklist.offLimitRooms.map(
                (room) => _line(theme, Icons.meeting_room_outlined, room.label),
              ),
              if (checklist.offLimitNote != null &&
                  checklist.offLimitNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 28),
                  child: Text(
                    checklist.offLimitNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
}
