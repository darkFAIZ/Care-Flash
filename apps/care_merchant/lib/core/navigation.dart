import 'package:care_core/care_core.dart';

import '../features/account/login_screen.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/safety_module_screen.dart';
import '../features/onboarding/verification_status_screen.dart';

/// Where a caregiver should land after signing in, signing up, or on app start.
///
/// New and unverified accounts are routed into onboarding so the safety and
/// verification requirements are completed before requests arrive. (FR-CM-2 to
/// FR-CM-4)
String postAuthRoute(CaregiverAccount? caregiver) {
  if (caregiver == null) {
    return LoginScreen.route;
  }
  if (caregiver.verificationStatus == VerificationStatus.notSubmitted) {
    return OnboardingScreen.route;
  }
  if (!caregiver.isVerified) {
    // Pending or rejected: show the status and any rejection reason.
    return VerificationStatusScreen.route;
  }
  if (!caregiver.safetyModuleCompleted) {
    return SafetyModuleScreen.route;
  }
  return HomeShell.route;
}
