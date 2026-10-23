import 'package:care_core/care_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/theme.dart';

const String _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://aqdbcytptkwcjuyglffz.supabase.co',
);
const String _supabaseKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_NSNNC6JanSLV4LXIBc213A_eosl8rZG',
);
const bool _offlineMode = String.fromEnvironment('BACKEND_URL') == 'mock';
bool _supabaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await loadPreferences();
  await _startApp();
}

Future<void> _startApp() async {
  try {
    if (_offlineMode) {
      await _startOffline();
      return;
    }
    if (_supabaseKey.isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is missing. Pass it with --dart-define when running or building the app.');
    }
    if (!_supabaseInitialized) {
      await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
      _supabaseInitialized = true;
    }
    final platform = SupabaseCareSeekerPlatform(Supabase.instance.client);
    await platform.initialize();
    runApp(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareFlashApp(),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        title: 'Care-Flash',
        theme: CareFlashTheme.light(),
        darkTheme: CareFlashTheme.dark(),
        home: SupabaseConnectionScreen(
          appName: 'Care-Flash',
          error: error.toString(),
          onRetry: _startApp,
          onUseOffline: _startOffline,
        ),
      ),
    );
  }
}

Future<void> _startOffline() async {
  final platform = await MockCarePlatform.create();
  runApp(
    ProviderScope(
      overrides: [platformProvider.overrideWithValue(platform)],
      child: const CareFlashApp(),
    ),
  );
}
