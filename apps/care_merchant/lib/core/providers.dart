import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
