import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'boundary_checklist_screen.dart';
import 'request_draft.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 1: choose the type of help and add a short note. (FR-CS-4)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Type of help', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final type in HelpType.values) ...[
            _HelpTypeCard(
              type: type,
              selected: draft.helpType == type,
              onTap: () => controller.setHelpType(type),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Text('Notes for the caregiver (optional)',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Anything the caregiver should know?',
            ),
            onChanged: controller.setDescription,
          ),
        ],
      ),
    );
  }
}

class _HelpTypeCard extends StatelessWidget {
  const _HelpTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final HelpType type;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (type) {
        HelpType.takeCare => Icons.volunteer_activism_outlined,
        HelpType.dropMedicine => Icons.medication_outlined,
        HelpType.feelUnsafe => Icons.health_and_safety_outlined,
        HelpType.emotionalSupport => Icons.sentiment_satisfied_alt_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: ListTile(
        leading: Icon(
          _icon,
          color: selected ? theme.colorScheme.onSecondaryContainer : null,
        ),
        title: Text(type.label),
        subtitle: Text(type.description),
        trailing: selected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
