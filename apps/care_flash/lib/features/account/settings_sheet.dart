import 'package:flutter/material.dart';

/// Opens the settings overlay. (AGENTS.md §5: settings overlay)
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
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
            SwitchListTile(
              value: _pushNotifications,
              onChanged: (value) =>
                  setState(() => _pushNotifications = value),
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
