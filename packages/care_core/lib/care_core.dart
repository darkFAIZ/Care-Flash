/// Shared models, enums, pricing rules, repository interfaces and the mock
/// platform for the Care-Flash apps.
///
/// Care-Flash imports this package for the care seeker flow; Care-Merchant uses
/// the same models for the caregiver flow. See the SRS in `docs/` for the
/// requirements referenced in the code.
///
/// The pure-Dart domain (models, enums, pricing, policy and the repository
/// interfaces) lives in the `care_domain` package and is re-exported here so
/// the apps only ever depend on `care_core`. The Flutter-specific mock platform
/// is defined in this package. (AGENTS.md §5)
library;

export 'package:care_domain/care_domain.dart';

export 'src/mock/mock_care_platform.dart';
export 'src/mock/mock_caregiver_platform.dart';
export 'src/mock/mock_data.dart';

export 'src/remote/backend_client.dart';
export 'src/remote/backend_connection_screen.dart';
export 'src/remote/remote_care_platform.dart';
export 'src/remote/remote_caregiver_platform.dart';
