import 'package:care_domain/care_domain.dart';

Booking? latestOpenBooking(Iterable<Booking> bookings) {
  Booking? latest;
  for (final booking in bookings) {
    if (latest == null || booking.createdAt.isAfter(latest.createdAt)) {
      latest = booking;
    }
  }
  return latest?.status.isOpen == true ? latest : null;
}
