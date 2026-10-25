import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/appearance.dart';

Future<void> showMerchantPreferences(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _PreferencesSheet(),
    );

class _PreferencesSheet extends ConsumerWidget {
  const _PreferencesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final appearance = ref.watch(appearanceProvider);
    final mode = appearance.mode;
    final id = language == AppLanguage.bahasaIndonesia;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              id ? 'Preferensi' : 'Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              id ? 'Bahasa' : 'Language',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<AppLanguage>(
            groupValue: language,
            onChanged: (value) {
              if (value != null) {
                ref.read(languageProvider.notifier).select(value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: item,
                    title: Text(item.label),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              id ? 'Tampilan' : 'Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value != null) {
                ref.read(appearanceProvider.notifier).setMode(value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: item,
                    title: Text(_modeName(item, id)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _modeName(ThemeMode mode, bool id) => switch (mode) {
    ThemeMode.system => id ? 'Ikuti perangkat' : 'System default',
    ThemeMode.light => id ? 'Terang' : 'Light',
    ThemeMode.dark => id ? 'Gelap' : 'Dark',
  };
}
