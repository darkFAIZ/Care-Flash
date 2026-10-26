import 'package:care_ui/care_ui.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter, vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              value: _pushNotifications,
              onChanged: (value) =>
                  setState(() => _pushNotifications = value),
              title: const AppText('Push notifications'),
              subtitle: const AppText('Booking, arrival and safety updates'),
            ),
            SwitchListTile(
              value: _shareLocation,
              onChanged: (value) => setState(() => _shareLocation = value),
              title: const AppText('Share my location'),
              subtitle: const AppText('Used only for matching and your visit'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Privacy information',
              icon: Icons.privacy_tip_outlined,
              variant: AppButtonVariant.ghost,
              expand: false,
              onPressed: () => _showPrivacy(context),
            ),
            const SizedBox(height: AppSpacing.sm),
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
        title: const AppText('Privacy information'),
        content: const AppText(
          'Your location and incident evidence are used only for the booking, '
          'support and emergency response purposes. Card details are never '
          'stored by Care-Flash.',
        ),
        actions: [
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
