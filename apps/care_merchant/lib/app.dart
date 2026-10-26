import 'package:care_ui/care_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/appearance.dart';
import 'core/providers.dart';
import 'core/phone_frame.dart';
import 'core/router.dart';
import 'core/theme.dart';

/// Root widget for Care-Merchant. (AGENTS.md §5)
class CareMerchantApp extends ConsumerWidget {
  const CareMerchantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appearance = ref.watch(appearanceProvider);
    final language = ref.watch(languageProvider);
    return MaterialApp.router(
      title: 'Care-Merchant',
      locale: Locale(language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: CareMerchantTheme.light(accent: appearance.accent),
      darkTheme: CareMerchantTheme.dark(accent: appearance.accent),
      themeMode: appearance.mode,
      routerConfig: router,
      // On the web (the Edge demo windows) keep the mobile aspect ratio; on a
      // phone/desktop window the app fills the screen as usual.
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) return content;
        return PhoneFrame(
          label: trText(context, 'Care-Merchant · caregiver'),
          child: content,
        );
      },
    );
  }
}
