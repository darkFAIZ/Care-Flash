import 'package:care_core/care_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/create_account_screen.dart';
import '../features/account/edit_profile_screen.dart';
import '../features/account/login_screen.dart';
import '../features/account/splash_screen.dart';
import '../features/home/home_shell.dart';
import '../features/payment_info/payment_info_screen.dart';
import '../features/rating/rating_screen.dart';
import '../features/request/boundary_checklist_screen.dart';
import '../features/request/confirmed_screen.dart';
import '../features/request/caregiver_code_screen.dart';
import '../features/request/gender_filter_screen.dart';
import '../features/request/help_request_screen.dart';
import '../features/request/matched_caregiver_screen.dart';
import '../features/request/matching_screen.dart';
import '../features/request/payment_screen.dart';
import '../features/request/schedule_screen.dart';
import '../features/safety/scan_safety_button_screen.dart';
import '../features/session/report_screen.dart';
import '../features/session/session_screen.dart';
import '../features/support/help_support_screen.dart';

/// App routes for Care-Flash.
///
/// Every screen referenced here is implemented; navigation can be exercised end
/// to end. (AGENTS.md §8)
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.route,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: SplashScreen.route,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.route,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: CreateAccountScreen.route,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: HomeShell.route,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: PaymentInfoScreen.route,
        builder: (context, state) => const PaymentInfoScreen(),
      ),
      GoRoute(
        path: HelpSupportScreen.route,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      // Profile editing. (Phase 5)
      GoRoute(
        path: EditProfileScreen.route,
        builder: (context, state) => const EditProfileScreen(),
      ),
      // Request flow. (FR-CS-4 to FR-CS-12)
      GoRoute(
        path: HelpRequestScreen.route,
        builder: (context, state) => const HelpRequestScreen(),
      ),
      GoRoute(
        path: BoundaryChecklistScreen.route,
        builder: (context, state) => const BoundaryChecklistScreen(),
      ),
      GoRoute(
        path: ScheduleScreen.route,
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: GenderFilterScreen.route,
        builder: (context, state) => const GenderFilterScreen(),
      ),
      GoRoute(
        path: MatchingScreen.route,
        builder: (context, state) => const MatchingScreen(),
      ),
      GoRoute(
        path: MatchedCaregiverScreen.route,
        builder: (context, state) => const MatchedCaregiverScreen(),
      ),
      GoRoute(
        path: PaymentScreen.route,
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: ConfirmedScreen.route,
        builder: (context, state) => const ConfirmedScreen(),
      ),
      GoRoute(
        path: CaregiverCodeScreen.route,
        builder: (context, state) => const CaregiverCodeScreen(),
      ),
      // Safety, session, report and rating. (FR-CS-13 to FR-CS-20)
      GoRoute(
        path: ScanSafetyButtonScreen.qrRoute,
        builder: (context, state) =>
            const ScanSafetyButtonScreen(method: ButtonVerificationMethod.qr),
      ),
      GoRoute(
        path: ScanSafetyButtonScreen.nfcRoute,
        builder: (context, state) =>
            const ScanSafetyButtonScreen(method: ButtonVerificationMethod.nfc),
      ),
      GoRoute(
        path: SessionScreen.route,
        builder: (context, state) => const SessionScreen(),
      ),
      GoRoute(
        path: ReportScreen.route,
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: RatingScreen.route,
        builder: (context, state) => const RatingScreen(),
      ),
    ],
  );
});
