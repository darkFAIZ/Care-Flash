import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:care_core/care_core.dart';
import '../../core/providers.dart';

/// Opens the settings overlay. (AGENTS.md §5: settings overlay)
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  // TODO(team): persist these preferences and wire them to real behaviour.
  bool _pushNotifications = true;
  bool _shareLocation = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                groupValue: ref.watch(themeModeProvider),
                title: Text(_modeLabel(mode)),
                onChanged: (value) {
                  if (value != null)
                    ref.read(themeModeProvider.notifier).select(value);
                },
              ),
            SwitchListTile(
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
              title: const Text('Push notifications'),
              subtitle: const Text('Booking, arrival and safety updates'),
            ),
            SwitchListTile(
              value: _shareLocation,
              onChanged: (value) => setState(() => _shareLocation = value),
              title: const Text('Share my location'),
              subtitle: const Text('Used only for matching and your visit'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showPrivacy(context),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: const Text('Privacy information'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _modeLabel(ThemeMode mode) {
    final id = ref.watch(languageProvider) == AppLanguage.bahasaIndonesia;
    return switch (mode) {
      ThemeMode.system => id ? 'Ikuti perangkat' : 'System default',
      ThemeMode.light => id ? 'Terang' : 'Light',
      ThemeMode.dark => id ? 'Gelap' : 'Dark',
    };
  }

  void _showPrivacy(BuildContext context) {
    // TODO(team): replace with the final privacy policy text.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy information'),
        content: const Text(
          'Your location and incident evidence are used only for the booking, '
          'support and emergency response purposes. Card details are never '
          'stored by Care-Flash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
