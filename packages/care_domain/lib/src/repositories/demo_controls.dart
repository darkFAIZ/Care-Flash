import '../enums.dart';

/// Debug-only hooks used by the Demo Controls sheet in each app (AGENTS.md §5).
///
/// Care-Flash and Care-Merchant are separate processes, so each app's mock
/// platform simulates the other side. These events let a demo drive those
/// simulations by hand. Real builds use an HTTP implementation and never call
/// this interface.
abstract interface class DemoControls {
  /// When true, the mock progresses through simulated steps on its own.
  void setAutoAdvance(bool enabled);

  /// Controls whether the next request finds a caregiver. (FR-CS-9)
  void setNextRequestMatches(bool matches);

  /// Forces the next payment attempt to fail so the retry flow can be shown.
  /// (FR-CS-11)
  void setNextPaymentFails(bool fails);

  /// Simulates the caregiver accepting the paid request. (FR-P-12)
  void simulateCaregiverAccept();

  /// Simulates the caregiver declining, which offers the request elsewhere.
  /// (FR-P-13)
  void simulateCaregiverDecline();

  /// Simulates the caregiver starting the trip to the care seeker. (FR-P-14)
  void simulateCaregiverTravelling();

  /// Simulates the caregiver arriving. (FR-CS-21)
  void simulateCaregiverArrival();

  /// Simulates the care seeker confirming (or rejecting) the caregiver code.
  /// (FR-P-16, FR-P-19)
  void simulateCaregiverCodeVerification({bool valid = true});

  /// Simulates scanning the safety button with the correct (or wrong)
  /// identifier, since the two apps cannot share memory in the mock.
  /// (FR-CS-13, FR-CS-14)
  void simulateButtonScan({
    ButtonVerificationMethod method = ButtonVerificationMethod.qr,
    bool valid = true,
  });

  /// Simulates a press of the physical safety button, which reports the
  /// incident. (HI-CS-2, FR-CS-17)
  void simulateButtonPress();

  /// Simulates the caregiver marking the work complete. (FR-P-21)
  void simulateSessionComplete();
}
