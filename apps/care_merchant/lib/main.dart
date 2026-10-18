import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = await MockCaregiverPlatform.create();
  runApp(
    ProviderScope(
      overrides: [platformProvider.overrideWithValue(platform)],
      child: const CareMerchantApp(),
    ),
  );
}
