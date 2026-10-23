import 'dart:async';

import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The caregiver-side mock platform is created in `main()` and injected here.
/// This keeps the app independent of how the platform is built, so an HTTP
/// implementation can replace the mock later without changing the widgets.
/// (AGENTS.md §5)
final platformProvider = Provider<CaregiverPlatform>((ref) {
  throw StateError('platformProvider must be overridden in ProviderScope.');
});

/// The signed-in caregiver, or null when signed out. (FR-CM-1)
final caregiverStateProvider = StreamProvider<CaregiverAccount?>((ref) {
  return ref.watch(platformProvider).watchCurrentCaregiver();
});

/// The request currently offered to this caregiver, or null. (FR-CM-7)
final incomingRequestProvider = StreamProvider<Booking?>((ref) {
  return ref.watch(platformProvider).watchIncomingRequest();
});

/// The booking this caregiver has accepted, or null. (FR-CM-10)
final activeBookingProvider = StreamProvider<Booking?>((ref) {
  return ref.watch(platformProvider).watchActiveBooking();
});

/// Finished bookings, for the history and earnings screens. (FR-CM-21)
final bookingHistoryProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(platformProvider).watchBookingHistory();
});

/// The caregiver's earnings: available balance, pending earnings, transaction
/// history and payout status. (FR-CM-21, FR-CM-22, FR-P-29)
final earningsProvider = StreamProvider<EarningsSummary>((ref) {
  return ref.watch(platformProvider).watchEarnings();
});

/// Feedback the care seeker left about this caregiver, shown in Care-Merchant.
/// (FR-CM-23, FR-P-27)
final feedbackReceivedProvider = StreamProvider<List<FeedbackReceived>>((ref) {
  return ref.watch(platformProvider).watchFeedbackReceived();
});

/// The care-seeker ratings this caregiver has already submitted, so the
/// feedback screen can hide visits that no longer need a rating. (FR-CM-24)
final careSeekerRatingsProvider = StreamProvider<List<CareSeekerRating>>((ref) {
  return ref.watch(platformProvider).watchCareSeekerRatings();
});

/// Preferences loaded in main(). Widget tests do not call main(), so the
/// cache stays null there and the app falls back to English.
SharedPreferences? _preferences;

Future<void> loadPreferences() async {
  _preferences ??= await SharedPreferences.getInstance();
}

/// The selected app language. The choice is saved on this device. (FR-CM-3)
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
