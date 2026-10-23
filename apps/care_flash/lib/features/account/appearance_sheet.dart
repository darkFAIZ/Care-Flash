import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance.dart';

/// Opens the appearance sheet: theme mode and accent colour. (Phase 5)
Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          0,
          AppSpacing.pageGutter,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Your choice is saved on this device.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: AppText('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: AppText('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: AppText('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {appearance.mode},
              onSelectionChanged: (selection) =>
                  controller.setMode(selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText('Accent colour', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            _AccentTile(
              label: 'Brand',
              color: AppBrand.careFlash,
              selected: appearance.accent == null,
              onTap: () => controller.setAccent(null),
            ),
            for (final accent in AppAccent.values)
              _AccentTile(
                label: accent.label,
                color: accent.seed,
                selected: appearance.accent == accent,
                onTap: () => controller.setAccent(accent),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentTile extends StatelessWidget {
  const _AccentTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppText(label, style: theme.textTheme.bodyLarge),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
