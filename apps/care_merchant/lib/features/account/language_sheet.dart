import 'package:care_core/care_core.dart';
import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Opens the language overlay. (FR-CM-3) Both languages are fully available;
/// the choice is saved on the device.
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              0,
              AppSpacing.pageGutter,
              AppSpacing.sm,
            ),
            child: AppText(
              'App language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final language in AppLanguage.values)
            ListTile(
              leading: Icon(
                language == selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: language == selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: AppText(language.label),
              onTap: () {
                ref.read(languageProvider.notifier).select(language);
                Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
            child: AppText('Your choice is saved on this device.'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
