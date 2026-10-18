/// Shared models, enums, pricing rules, repository interfaces and the mock
/// platform for the Care-Flash apps.
///
/// Care-Flash imports this package for the care seeker flow; Care-Merchant uses
/// the same models for the caregiver flow. See the SRS in `docs/` for the
/// requirements referenced in the code.
library;

export 'src/enums.dart';
export 'src/formatting.dart';
export 'src/mock/mock_care_platform.dart';
export 'src/mock/mock_caregiver_platform.dart';
export 'src/mock/mock_data.dart';
export 'src/models/account.dart';
export 'src/models/booking.dart';
export 'src/models/boundary_checklist.dart';
export 'src/models/caregiver_account.dart';
export 'src/models/earnings.dart';
export 'src/models/feedback.dart';
export 'src/models/help_request.dart';
export 'src/models/location.dart';
export 'src/models/payment.dart';
export 'src/models/pricing.dart';
export 'src/models/safety.dart';
export 'src/platform_policy.dart';
export 'src/pricing/pricing.dart';
export 'src/repositories/auth_repository.dart';
export 'src/repositories/booking_repository.dart';
export 'src/repositories/caregiver_repository.dart';
export 'src/repositories/demo_controls.dart';
export 'src/repositories/payment_repository.dart';
