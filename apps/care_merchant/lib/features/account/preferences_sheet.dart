import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

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
    final mode = ref.watch(themeModeProvider);
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
          for (final item in AppLanguage.values)
            RadioListTile<AppLanguage>(
              value: item,
              groupValue: language,
              title: Text(item.label),
              onChanged: (value) {
                if (value != null)
                  ref.read(languageProvider.notifier).select(value);
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              id ? 'Tampilan' : 'Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final item in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: item,
              groupValue: mode,
              title: Text(_modeName(item, id)),
              onChanged: (value) {
                if (value != null)
                  ref.read(themeModeProvider.notifier).select(value);
              },
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
