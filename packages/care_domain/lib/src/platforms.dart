import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/caregiver_repository.dart';
import 'repositories/demo_controls.dart';
import 'repositories/payment_repository.dart';

/// The full care-seeker platform surface used by the Care-Flash app.
///
/// Bundles the seeker-facing repositories and the debug demo hooks behind one
/// type so the app's `platformProvider` can be satisfied by either the local
/// mock or a remote (backend-connected) implementation. (AGENTS.md §5)
abstract interface class CareSeekerPlatform
    implements
        AuthRepository,
        BookingRepository,
        PaymentRepository,
        DemoControls {}

/// The full caregiver platform surface used by the Care-Merchant app.
///
/// Bundles [CaregiverRepository] and [CaregiverDemoControls] plus the debug
/// client-code convenience behind one type, so the app's `platformProvider`
/// can be satisfied by either the local mock or a remote implementation.
/// (AGENTS.md §5)
abstract interface class CaregiverPlatform
    implements CaregiverRepository, CaregiverDemoControls {
  /// The client code of the booking currently offered to this caregiver, if
  /// any. Debug-only convenience so the Demo Controls sheet and the client-code
  /// screen can present the code without a real care seeker reading it off a
  /// screen. (FR-CM-13)
  String? get debugClientCode;
}
