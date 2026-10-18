import '../models/payment.dart';

/// Payment for a booking. (FR-CS-11)
///
/// Card details are handled by the payment provider and never stored here.
/// (DC-CS-2)
abstract interface class PaymentRepository {
  /// Payment methods offered in the app. (AGENTS.md §5)
  List<PaymentMethod> availableMethods();

  /// Attempts to pay the total for [bookingId]. On success the booking moves to
  /// paid-pending and a client verification code is generated. (FR-CS-11, FR-CS-12)
  Future<PaymentResult> pay({
    required String bookingId,
    required PaymentMethod method,
  });
}
