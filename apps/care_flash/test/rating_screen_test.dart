import 'package:care_core/care_core.dart';
import 'package:care_flash/core/providers.dart';
import 'package:care_flash/features/rating/rating_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingCarePlatform implements CareSeekerPlatform {
  @override
  Future<void> rateCaregiver(CaregiverRating rating) async {
    throw StateError('rating save failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('a failed feedback submission stops loading and can be retried', (
    tester,
  ) async {
    final booking = Booking(
      id: 'booking-1',
      requestReference: 'CF-12345',
      helpType: HelpType.takeCare,
      checklist: BoundaryChecklist.suggested,
      location: VisitLocation.mockPresets.first,
      scheduledAt: DateTime.now(),
      duration: VisitDuration.sixty,
      genderFilter: GenderFilter.both,
      caregiver: const Caregiver(
        id: 'caregiver-1',
        name: 'Ayu Lestari',
        gender: Gender.female,
      ),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformProvider.overrideWithValue(_FailingCarePlatform()),
          bookingHistoryProvider.overrideWith((ref) => Stream.value([booking])),
        ],
        child: const MaterialApp(home: RatingScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'We could not submit your feedback. Please check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Submit'), findsOneWidget);
  });
}
