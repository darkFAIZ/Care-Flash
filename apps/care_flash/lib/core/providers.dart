import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The mock platform is created in `main()` and injected here. This keeps the
/// app independent of how the platform is built, so an HTTP implementation can
/// replace the mock later without changing the widgets. (AGENTS.md §5)
final platformProvider = Provider<MockCarePlatform>((ref) {
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
  AppLanguage build() => AppLanguage.english;

  void select(AppLanguage language) => state = language;
}

final languageProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
