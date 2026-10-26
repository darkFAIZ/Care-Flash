import 'package:care_core/care_core.dart';
import 'package:care_core/src/supabase/booking_selection.dart';
import 'package:flutter_test/flutter_test.dart';

Booking _booking(String id, BookingStatus status, DateTime createdAt) =>
    Booking(
      id: id,
      requestReference: 'CF-$id',
      helpType: HelpType.takeCare,
      checklist: BoundaryChecklist.suggested,
      location: VisitLocation.mockPresets.first,
      scheduledAt: createdAt,
      duration: VisitDuration.sixty,
      genderFilter: GenderFilter.both,
      status: status,
      createdAt: createdAt,
    );

void main() {
  test(
    'a finished latest booking does not resurrect an older open request',
    () {
      final oldRequest = _booking(
        'old',
        BookingStatus.matched,
        DateTime(2026, 10, 24),
      );
      final completedRequest = _booking(
        'completed',
        BookingStatus.completed,
        DateTime(2026, 10, 25),
      );

      expect(latestOpenBooking([completedRequest, oldRequest]), isNull);
    },
  );

  test('a newer open booking is available after a finished booking', () {
    final finishedRequest = _booking(
      'finished',
      BookingStatus.completed,
      DateTime(2026, 10, 24),
    );
    final newRequest = _booking(
      'new',
      BookingStatus.matched,
      DateTime(2026, 10, 25),
    );

    expect(latestOpenBooking([newRequest, finishedRequest])?.id, 'new');
  });
}
