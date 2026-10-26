import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/date_time_format.dart';
import '../../core/theme.dart';
import 'gender_filter_screen.dart';
import 'request_draft.dart';
import 'widgets/wizard_scaffold.dart';

/// Step 3: location, date, time and duration matching Stitch. (FR-CS-6)
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
          // Where Card Container
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
                      Icons.location_on_rounded,
                      color: WarmEmpathyColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Service Address',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final location in VisitLocation.mockPresets) ...[
                  InkWell(
                    onTap: () => controller.setLocation(location),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: draft.location?.label == location.label
                            ? WarmEmpathyColors.primary.withValues(alpha: 0.06)
                            : WarmEmpathyColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: draft.location?.label == location.label
                              ? WarmEmpathyColors.primary
                              : Colors.transparent,
                          width: draft.location?.label == location.label ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            draft.location?.label == location.label
                                ? Icons.check_circle_rounded
                                : Icons.place_outlined,
                            color: draft.location?.label == location.label
                                ? WarmEmpathyColors.primary
                                : WarmEmpathyColors.onSurfaceVariant,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: draft.location?.label == location.label
                                        ? WarmEmpathyColors.primary
                                        : WarmEmpathyColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  location.address,
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
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // When Card Container
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
                      Icons.schedule_rounded,
                      color: WarmEmpathyColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Schedule & Arrival Time',
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
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WarmEmpathyColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: WarmEmpathyColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Date',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: WarmEmpathyColors.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _scheduledAt == null
                                    ? 'Choose a date'
                                    : formatVisitTime(_scheduledAt!).split(',').first,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: WarmEmpathyColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WarmEmpathyColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: WarmEmpathyColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Time',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: WarmEmpathyColors.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _scheduledAt == null
                                    ? 'Choose a time'
                                    : formatClock(_scheduledAt!),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: WarmEmpathyColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Duration Card Container
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
                      Icons.timer_outlined,
                      color: WarmEmpathyColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Estimated Care Duration',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WarmEmpathyColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.8,
                  children: [
                    for (final duration in VisitDuration.values)
                      InkWell(
                        onTap: () => controller.setDuration(duration),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: draft.duration == duration
                                ? WarmEmpathyColors.primary
                                : WarmEmpathyColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: draft.duration == duration
                                ? const [
                                    BoxShadow(
                                      color: Color(0x18000000),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              duration.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: draft.duration == duration
                                    ? WarmEmpathyColors.onPrimary
                                    : WarmEmpathyColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
