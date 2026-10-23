/// Pure-Dart domain for the Care-Flash platform: models, enums, formatting,
/// pricing rules, platform policy and the repository interfaces the apps are
/// programmed against.
///
/// This package intentionally has no Flutter dependency so it can be shared by
/// the Flutter apps (via `care_core`) and the pure-Dart demo backend. (AGENTS.md
/// §5)
library;

export 'src/enums.dart';
export 'src/formatting.dart';
export 'src/platform_policy.dart';
export 'src/platforms.dart';
export 'src/pricing/pricing.dart';
export 'src/pricing/refund_policy.dart';
export 'src/models/account.dart';
export 'src/models/booking.dart';
export 'src/models/boundary_checklist.dart';
export 'src/models/button_code.dart';
export 'src/models/caregiver_account.dart';
export 'src/models/earnings.dart';
export 'src/models/feedback.dart';
export 'src/models/help_request.dart';
export 'src/models/location.dart';
export 'src/models/payment.dart';
export 'src/models/pricing.dart';
export 'src/models/safety.dart';
export 'src/repositories/auth_repository.dart';
export 'src/repositories/booking_repository.dart';
export 'src/repositories/caregiver_repository.dart';
export 'src/repositories/demo_controls.dart';
export 'src/repositories/payment_repository.dart';
