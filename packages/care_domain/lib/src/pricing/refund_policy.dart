import '../models/booking.dart';
import '../platform_policy.dart';
import 'pricing.dart';

/// Why money is returned to the care seeker.
///
/// The SRS fixes the amount for some cases and leaves others open. Each case
/// below states what it pays and, where the SRS is silent, marks the default
/// with a TODO. (FR-P-13, FR-P-19, FR-P-22, FR-P-23, SRS open decision 3)
enum RefundReason {
  /// Report during the session, or the physical button was pressed. Full
  /// refund of the total, including the Grab fare. (FR-P-23, FR-CS-17)
  reportOrButtonPress,

  /// No caregiver accepted, so no ride was booked and nothing was used.
  /// Full refund of the total. (FR-P-13)
  noCaregiverAccepts,

  /// The client code or safety button failed to verify, cancelling the
  /// booking. (FR-P-18, FR-CM-14)
  failedVerification,

  /// The caregiver reported danger before the session started. (FR-P-19)
  dangerBeforeSession,

  /// The care seeker ended the session early. The caregiver keeps the early-end
  /// compensation and the unused remainder is returned. (FR-CS-16, FR-P-22)
  endedEarly,
}

/// Single configurable place for every refund the platform performs.
///
/// Screens never compute a refund themselves; the repository applies this
/// policy so the amount is identical in the mock and the real backend.
///
/// The care seeker pays the whole total (caregiver price + platform fee + Grab
/// fare) up front, so a refund always starts from that total. The caregiver
/// never pays for the ride. (FR-P-10, FR-P-11)
abstract final class RefundPolicy {
  /// Amount returned to the care seeker when a booking is refunded for
  /// [reason].
  static int refundFor(Booking booking, RefundReason reason) {
    final price = booking.price;
    if (price == null) {
      return 0;
    }
    return switch (reason) {
      // Full refund of the total, Grab fare included.
      RefundReason.reportOrButtonPress ||
      RefundReason.noCaregiverAccepts =>
        price.total,

      // The caregiver price and the platform fee are returned. The Grab fare
      // is kept because the ride may already have been taken.
      // TODO(team): confirm keeping the fare here; the SRS is undecided.
      // (SRS open decision 2 and 3)
      RefundReason.failedVerification ||
      RefundReason.dangerBeforeSession =>
        PlatformPolicy.keepGrabFareOnFailedBooking
            ? price.total - price.grabFare
            : price.total,

      // The unused remainder of the visit, after the caregiver's early-end
      // compensation. (FR-CS-16, FR-P-22)
      RefundReason.endedEarly => price.total - Pricing.earlyEndCompensation(price),
    };
  }

  /// True when the whole payment is returned, so the payment is marked refunded
  /// rather than partially refunded. (FR-P-23)
  static bool isFullRefund(RefundReason reason) => switch (reason) {
        RefundReason.reportOrButtonPress ||
        RefundReason.noCaregiverAccepts =>
          true,
        RefundReason.failedVerification ||
        RefundReason.dangerBeforeSession =>
          !PlatformPolicy.keepGrabFareOnFailedBooking,
        RefundReason.endedEarly => false,
      };

  /// Caregiver payout for a booking that ended before a full session, used by
  /// the early-end and SOS paths. (FR-P-22, FR-P-24)
  static int caregiverCompensationFor(Booking booking) {
    final price = booking.price;
    if (price == null) {
      return 0;
    }
    return Pricing.earlyEndCompensation(price);
  }
}
