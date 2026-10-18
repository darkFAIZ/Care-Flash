import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import 'gender_filter_screen.dart';
import 'request_draft.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 3: location, date, time and duration. (FR-CS-6)
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  static const String route = '/schedule';

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _scheduledAt = ref.read(requestDraftProvider).scheduledAt;
  }

  Future<void> _pickDate() async {
    final base = _scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null) {
      return;
    }
    _setSchedule(
      DateTime(picked.year, picked.month, picked.day, base.hour, base.minute),
    );
  }

  Future<void> _pickTime() async {
    final base = _scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) {
      return;
    }
    _setSchedule(
      DateTime(base.year, base.month, base.day, picked.hour, picked.minute),
    );
  }

  void _setSchedule(DateTime value) {
    setState(() => _scheduledAt = value);
    ref.read(requestDraftProvider.notifier).setSchedule(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(requestDraftProvider);
    final controller = ref.read(requestDraftProvider.notifier);

    return WizardScaffold(
      title: 'When and where',
      step: 3,
      totalSteps: 4,
      primaryLabel: 'Next: preference',
      primaryEnabled: draft.location != null &&
          _scheduledAt != null &&
          draft.duration != null,
      onPrimary: () => context.push(GenderFilterScreen.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Where', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final location in VisitLocation.mockPresets) ...[
            Card(
              color: draft.location?.label == location.label
                  ? theme.colorScheme.secondaryContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  draft.location?.label == location.label
                      ? Icons.check_circle
                      : Icons.place_outlined,
                  color: draft.location?.label == location.label
                      ? theme.colorScheme.primary
                      : null,
                ),
                title: Text(location.label),
                subtitle: Text(location.address),
                onTap: () => controller.setLocation(location),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Text('When', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Date'),
                  subtitle: Text(
                    _scheduledAt == null
                        ? 'Choose a date'
                        : formatVisitTime(_scheduledAt!).split(',').first,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Time'),
                  subtitle: Text(
                    _scheduledAt == null
                        ? 'Choose a time'
                        : formatClock(_scheduledAt!),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('How long', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final duration in VisitDuration.values)
                ChoiceChip(
                  label: Text(duration.label),
                  selected: draft.duration == duration,
                  onSelected: (_) => controller.setDuration(duration),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
