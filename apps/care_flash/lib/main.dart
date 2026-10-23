import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/providers.dart';

/// The shared demo backend to connect to, or empty to run fully offline.
///
/// Passed at build time:
/// `flutter run -d edge --dart-define=BACKEND_URL=ws://localhost:8080`.
/// When set, Care-Flash uses the real platform over WebSocket so it shares one
/// booking state with Care-Merchant; otherwise it falls back to the mock.
const String _backendUrl = String.fromEnvironment('BACKEND_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Plus Jakarta Sans ships with the app (packages/care_ui assets), so no
  // screen ever waits on a font download during the demo.
  GoogleFonts.config.allowRuntimeFetching = false;
  await loadPreferences();
  final CareSeekerPlatform platform;
  if (_backendUrl.isEmpty) {
    platform = await MockCarePlatform.create();
  } else {
    final remote = RemoteCarePlatform(CareBackendClient(_backendUrl));
    await remote.connect();
    platform = remote;
  }
  runApp(
    ProviderScope(
      overrides: [platformProvider.overrideWithValue(platform)],
      child: const CareFlashApp(),
    ),
  );
}
