import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
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

/// The selected app language. English is the P1 default; Bahasa Indonesia is
/// P2 and only stored locally for now. (FR-CS-3)
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    _restore();
    return AppLanguage.english;
  }

  Future<void> select(AppLanguage language) async {
    state = language;
    await (await SharedPreferences.getInstance()).setString(
      'care_flash.language',
      language.code,
    );
  }

  Future<void> _restore() async {
    final code = (await SharedPreferences.getInstance()).getString(
      'care_flash.language',
    );
    final saved = AppLanguage.values
        .where((item) => item.code == code)
        .firstOrNull;
    if (saved != null) state = saved;
  }
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(
  LanguageController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await (await SharedPreferences.getInstance()).setString(
      'care_flash.theme',
      mode.name,
    );
  }

  Future<void> _restore() async {
    final value = (await SharedPreferences.getInstance()).getString(
      'care_flash.theme',
    );
    final saved = ThemeMode.values
        .where((mode) => mode.name == value)
        .firstOrNull;
    if (saved != null) state = saved;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
