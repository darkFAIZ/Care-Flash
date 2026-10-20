import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Opens the language overlay. (FR-CS-3) English is P1; Bahasa Indonesia is P2.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'App language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final language in AppLanguage.values)
            ListTile(
              leading: Icon(
                language == selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: language == selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(language.label),
              onTap: () {
                ref.read(languageProvider.notifier).select(language);
                Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: 8),
          // TODO(team): load real translations once Bahasa Indonesia is ready.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Bahasa Indonesia is a preview and not fully translated yet.'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
