import 'dart:async';

import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Opens the debug-only Demo Controls sheet. (AGENTS.md §5)
///
/// Care-Flash and Care-Merchant are separate processes, so this sheet drives the
/// mock platform's simulation of the care seeker by hand during a demo.
Future<void> showDemoControls(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _DemoControlsSheet(),
  );
}

class _DemoControlsSheet extends ConsumerStatefulWidget {
  const _DemoControlsSheet();

  @override
  ConsumerState<_DemoControlsSheet> createState() => _DemoControlsSheetState();
}

class _DemoControlsSheetState extends ConsumerState<_DemoControlsSheet> {
  bool _autoAdvance = true;
  bool _nextVerificationFails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = ref.read(platformProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          0,
          AppSpacing.pageGutter,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                AppText('Demo controls', style: theme.textTheme.titleLarge),
                const Spacer(),
                AppText('Debug only', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Drive the mock platform by hand while showing the app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: AppSpacing.xl),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const AppText('Auto-advance'),
              subtitle: const AppText('The mock moves through steps on its own'),
              value: _autoAdvance,
              onChanged: (value) {
                setState(() => _autoAdvance = value);
                platform.setAutoAdvance(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const AppText('Next review rejects the ID'),
              subtitle: const AppText('Turn on to show the rejection and resubmit path'),
              value: _nextVerificationFails,
              onChanged: (value) {
                setState(() => _nextVerificationFails = value);
                platform.setNextVerificationFails(value);
              },
            ),
            const Divider(height: AppSpacing.xl),
            AppText('Simulate the care seeker', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _action('Send a request', platform.simulateIncomingRequest),
                _action('Cancel booking', platform.simulateCareSeekerCancel),
                _action(
                  'Present client code',
                  () => unawaited(
                    platform.verifyClientCode(platform.debugClientCode ?? ''),
                  ),
                ),
                _action(
                  'Care seeker scans the button',
                  () => platform.simulateCareSeekerButtonScan(),
                ),
                _action('End early', platform.simulateCareSeekerEndEarly),
              ],
            ),
            if (platform.debugClientCode != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppText(
                'The care seeker is showing client code '
                '${platform.debugClientCode}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action(String label, VoidCallback onTap) => AppButton(
        label: label,
        variant: AppButtonVariant.secondary,
        expand: false,
        onPressed: onTap,
      );
}
