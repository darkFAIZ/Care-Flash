import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
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
          const SectionHeader(title: 'Where'),
          const SizedBox(height: AppSpacing.xs),
          for (final location in VisitLocation.mockPresets) ...[
            AppCard(
              compact: true,
              highlighted: draft.location?.label == location.label,
              onTap: () => controller.setLocation(location),
              child: Row(
                children: [
                  Icon(
                    draft.location?.label == location.label
                        ? Icons.check_circle_rounded
                        : Icons.place_outlined,
                    color: draft.location?.label == location.label
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(location.label,
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 2),
                        AppText(
                          location.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'When'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const AppText('Date'),
                  subtitle: AppText(
                    _scheduledAt == null
                        ? 'Choose a date'
                        : formatVisitTime(_scheduledAt!).split(',').first,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const AppText('Time'),
                  subtitle: AppText(
                    _scheduledAt == null
                        ? 'Choose a time'
                        : formatClock(_scheduledAt!),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'How long'),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final duration in VisitDuration.values)
                ChoiceChip(
                  label: AppText(duration.label),
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
