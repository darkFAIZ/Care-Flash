import 'dart:async';

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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Demo controls', style: theme.textTheme.titleLarge),
                const Spacer(),
                Text('Debug only', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Drive the mock platform by hand while showing the app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-advance'),
              subtitle: const Text('The mock moves through steps on its own'),
              value: _autoAdvance,
              onChanged: (value) {
                setState(() => _autoAdvance = value);
                platform.setAutoAdvance(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next review rejects the ID'),
              subtitle: const Text(
                'Turn on to show the rejection and resubmit path',
              ),
              value: _nextVerificationFails,
              onChanged: (value) {
                setState(() => _nextVerificationFails = value);
                platform.setNextVerificationFails(value);
              },
            ),
            const Divider(height: 24),
            Text(
              'Simulate the care seeker',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _action('Send a request', platform.simulateIncomingRequest),
                _action('Cancel booking', platform.simulateCareSeekerCancel),
                _action(
                  'Confirm caregiver code',
                  platform.simulateCareSeekerCodeConfirmation,
                ),
                _action(
                  'Scan the button',
                  () => platform.simulateCareSeekerButtonScan(),
                ),
                _action('End early', platform.simulateCareSeekerEndEarly),
              ],
            ),
            if (platform.debugClientCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Caregiver verification code: '
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

  Widget _action(String label, VoidCallback onTap) =>
      FilledButton.tonal(onPressed: onTap, child: Text(label));
}
