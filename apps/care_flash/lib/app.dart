import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

/// Root widget for Care-Flash. (AGENTS.md §5)
class CareFlashApp extends ConsumerWidget {
  const CareFlashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Care-Flash',
      debugShowCheckedModeBanner: false,
      theme: CareFlashTheme.light(),
      darkTheme: CareFlashTheme.dark(),
      routerConfig: router,
    );
  }
}
