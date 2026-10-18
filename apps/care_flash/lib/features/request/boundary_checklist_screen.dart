import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'request_draft.dart';
import 'schedule_screen.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 2: allowed tasks, off-limits tasks and off-limit rooms. (FR-CS-5)
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
          _SectionHeader(
            title: 'Allowed during the visit',
            subtitle: 'Tick what the caregiver may do. (FR-CS-5)',
          ),
          for (final task in BoundaryChecklist.standardAllowedTasks)
            CheckboxListTile(
              value: _allowed.contains(task),
              title: Text(task),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                checked == true ? _allowed.add(task) : _allowed.remove(task);
              }),
            ),
          const SizedBox(height: 12),
          _SectionHeader(
            title: 'Not allowed',
            subtitle: 'Kept off limits for your safety.',
          ),
          for (final task in BoundaryChecklist.standardDisallowedTasks)
            CheckboxListTile(
              value: _disallowed.contains(task),
              title: Text(task),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                checked == true
                    ? _disallowed.add(task)
                    : _disallowed.remove(task);
              }),
            ),
          const SizedBox(height: 12),
          _SectionHeader(title: 'Off-limit rooms'),
          for (final room in OffLimitRoom.values)
            CheckboxListTile(
              value: _offLimit.contains(room),
              title: Text(room.label),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) => setState(() {
                checked == true ? _offLimit.add(room) : _offLimit.remove(room);
              }),
            ),
          const SizedBox(height: 12),
          Text('Other boundaries (optional)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. no shoes indoors'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
