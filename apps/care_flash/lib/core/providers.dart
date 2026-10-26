import 'dart:async';

import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The mock platform is created in `main()` and injected here. This keeps the
/// app independent of how the platform is built, so an HTTP implementation can
/// replace the mock later without changing the widgets. (AGENTS.md §5)
final platformProvider = Provider<CareSeekerPlatform>((ref) {
  throw StateError('platformProvider must be overridden in ProviderScope.');
});

/// The signed-in care seeker, or null when signed out. (FR-CS-1)
final authStateProvider = StreamProvider<CareSeeker?>((ref) {
  return ref.watch(platformProvider).watchCurrentUser();
});

/// The current open booking, or null. (FR-CS-21)
final activeBookingProvider = StreamProvider<Booking?>((ref) {
  return ref.watch(platformProvider).watchActiveBooking();
});

/// Past and finished bookings for the activity page.
final bookingHistoryProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(platformProvider).watchBookingHistory();
});

/// Preferences loaded in main(). Widget tests do not call main(), so the
/// cache stays null there and the app falls back to English.
SharedPreferences? _preferences;

/// Loads the small preferences before the first frame (language, appearance).
Future<void> loadPreferences() async {
  _preferences ??= await SharedPreferences.getInstance();
}

/// The selected app language. English is the P1 default; Bahasa Indonesia is
/// the second language. The choice is saved on this device. (FR-CS-3)
class LanguageController extends Notifier<AppLanguage> {
  static const _preferenceKey = 'app.language';

  @override
  AppLanguage build() {
    final code = _preferences?.getString(_preferenceKey);
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.english;
  }

  void select(AppLanguage language) {
    state = language;
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.setString(_preferenceKey, language.code));
    }
  }
}

final languageProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
