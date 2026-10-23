import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/theme.dart';

/// Both apps connect to this shared local service by default. Set to `mock` to
/// intentionally run this app as an independent offline demo.
const String _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'ws://localhost:8080',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _startApp();
}

Future<void> _startApp() async {
  try {
    final CaregiverPlatform platform;
    if (_backendUrl == 'mock') {
      platform = await MockCaregiverPlatform.create();
    } else {
      final remote = RemoteCaregiverPlatform(CareBackendClient(_backendUrl));
      await remote.connect();
      platform = remote;
    }
    runApp(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareMerchantApp(),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        title: 'Care-Merchant',
        theme: CareMerchantTheme.light(),
        darkTheme: CareMerchantTheme.dark(),
        home: BackendConnectionScreen(
          appName: 'Care-Merchant',
          backendUrl: _backendUrl,
          error: error.toString(),
          onRetry: _startApp,
          onUseOffline: _startOffline,
        ),
      ),
    );
  }
}

Future<void> _startOffline() async {
  final platform = await MockCaregiverPlatform.create();
  runApp(
    ProviderScope(
      overrides: [platformProvider.overrideWithValue(platform)],
      child: const CareMerchantApp(),
    ),
  );
}
