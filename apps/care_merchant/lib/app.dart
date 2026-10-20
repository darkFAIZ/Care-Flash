import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/phone_frame.dart';
import 'core/router.dart';
import 'core/theme.dart';

/// Root widget for Care-Merchant. (AGENTS.md §5)
class CareMerchantApp extends ConsumerWidget {
  const CareMerchantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Care-Merchant',
      debugShowCheckedModeBanner: false,
      theme: CareMerchantTheme.light(),
      darkTheme: CareMerchantTheme.dark(),
      routerConfig: router,
      // On the web (the Edge demo windows) keep the mobile aspect ratio; on a
      // phone/desktop window the app fills the screen as usual.
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!kIsWeb) return content;
        return PhoneFrame(label: 'Care-Merchant · caregiver', child: content);
      },
    );
  }
}
