import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/create_account_screen.dart';
import '../features/account/edit_profile_screen.dart';
import '../features/account/login_screen.dart';
import '../features/account/splash_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/booking/button_handover_screen.dart';
import '../features/booking/client_code_screen.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/safety_module_screen.dart';
import '../features/onboarding/verification_status_screen.dart';
import '../features/requests/incoming_request_screen.dart';
import '../features/session/report_care_seeker_screen.dart';
import '../features/session/session_screen.dart';

/// App routes for Care-Merchant.
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
      // Onboarding and verification. (FR-CM-2 to FR-CM-4)
      GoRoute(
        path: OnboardingScreen.route,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: VerificationStatusScreen.route,
        builder: (context, state) => const VerificationStatusScreen(),
      ),
      GoRoute(
        path: SafetyModuleScreen.route,
        builder: (context, state) => const SafetyModuleScreen(),
      ),
      // Profile editing. (Phase 5)
      GoRoute(
        path: EditProfileScreen.route,
        builder: (context, state) => const EditProfileScreen(),
      ),
      // Incoming request. (FR-CM-7 to FR-CM-9)
      GoRoute(
        path: IncomingRequestScreen.route,
        builder: (context, state) => const IncomingRequestScreen(),
      ),
      // Accepted booking: trip, verification, handover and session.
      // (FR-CM-10 to FR-CM-20)
      GoRoute(
        path: BookingScreen.route,
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: ClientCodeScreen.route,
        builder: (context, state) => const ClientCodeScreen(),
      ),
      GoRoute(
        path: ButtonHandoverScreen.route,
        builder: (context, state) => const ButtonHandoverScreen(),
      ),
      GoRoute(
        path: SessionScreen.route,
        builder: (context, state) => const SessionScreen(),
      ),
      GoRoute(
        path: ReportCareSeekerScreen.route,
        builder: (context, state) => const ReportCareSeekerScreen(),
      ),
    ],
  );
});
