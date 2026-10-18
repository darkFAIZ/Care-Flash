import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    );
  }
}
