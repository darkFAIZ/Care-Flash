import 'package:care_backend/care_backend.dart';
import 'package:care_core/care_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets the event loop settle so a WebSocket snapshot can be delivered and
/// applied to the remote platform's cached state.
Future<void> pump([int milliseconds = 20]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

/// Polls [condition] until it holds, failing the test after a timeout.
Future<void> waitUntil(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting${reason == null ? '' : ' for $reason'}');
    }
    await pump(10);
  }
}

HelpRequest helpRequest() => HelpRequest(
      helpType: HelpType.takeCare,
      description: 'Company while I study.',
      checklist: BoundaryChecklist.suggested,
      location: VisitLocation.mockPresets.first,
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      duration: VisitDuration.sixty,
    );

void main() {
  late CareBackendServer server;
  late CareBackendClient seekerClient;
  late CareBackendClient caregiverClient;
  late RemoteCarePlatform seeker;
  late RemoteCaregiverPlatform caregiver;

  CaregiverAccount? caregiverAccount;
  Booking? caregiverOffer;
  Booking? caregiverActive;
  Booking? seekerActive;
  EarningsSummary? earnings;
  List<FeedbackReceived> feedback = const [];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = CareBackendServer(port: 0);
    await server.start();
    final url = 'ws://localhost:${server.boundPort}';

    seekerClient = CareBackendClient(url);
    caregiverClient = CareBackendClient(url);
    seeker = RemoteCarePlatform(seekerClient);
    caregiver = RemoteCaregiverPlatform(caregiverClient);
    await seeker.connect();
    await caregiver.connect();

    caregiverAccount = null;
    caregiverOffer = null;
    caregiverActive = null;
    seekerActive = null;
    earnings = null;
    feedback = const [];

    // Persistent listeners so no pushed snapshot is missed.
    caregiver.watchCurrentCaregiver().listen((value) => caregiverAccount = value);
    caregiver.watchIncomingRequest().listen((value) => caregiverOffer = value);
    caregiver.watchActiveBooking().listen((value) => caregiverActive = value);
    caregiver.watchEarnings().listen((value) => earnings = value);
    caregiver.watchFeedbackReceived().listen((value) => feedback = value);
    seeker.watchActiveBooking().listen((value) => seekerActive = value);
    await pump();
  });

  tearDown(() async {
    seeker.dispose();
    caregiver.dispose();
    await seekerClient.close();
    await caregiverClient.close();
    await server.stop();
  });

  test('a live request flows from Care-Flash to Care-Merchant and back', () async {
    final caregiverAuth = await caregiver.signUp(
      name: 'Ayu Lestari',
      email: 'ayu@campus.ac.id',
      password: 'secret1',
      gender: Gender.female,
    );
    expect(caregiverAuth.success, isTrue);
    final caregiverId = caregiverAuth.user!.id;

    await caregiver.submitVerification(
      ktpNumber: '3174012501990001',
      documentLabel: 'KTP',
    );
    await caregiver.completeSafetyModule();
    await caregiver.updateAvailability(CaregiverAvailability.available);
    await waitUntil(
      () => caregiverAccount?.canReceiveRequests == true,
      reason: 'the caregiver to be available',
    );

    final seekerAuth =
        await seeker.signUp(name: 'Sari', email: 'sari@campus.ac.id', password: 'secret1');
    expect(seekerAuth.success, isTrue);

    final booking = await seeker.submitRequest(helpRequest());
    expect(booking.status, BookingStatus.matched);
    expect(booking.caregiver?.id, caregiverId);

    final payment =
        await seeker.pay(bookingId: booking.id, method: MockData.paymentMethods.first);
    expect(payment.success, isTrue);
    await waitUntil(
      () => caregiverOffer?.status == BookingStatus.paidPending,
      reason: 'the request to reach the caregiver',
    );
    final clientCode = caregiverOffer!.clientCode!;

    await caregiver.acceptRequest();
    await waitUntil(
      () => caregiverActive?.status == BookingStatus.confirmed,
      reason: 'the caregiver to accept',
    );

    await caregiver.startTrip();
    await waitUntil(() => caregiverActive?.status == BookingStatus.caregiverTravelling);
    await caregiver.markArrived();
    await waitUntil(() => caregiverActive?.status == BookingStatus.arrived);

    final codeResult = await caregiver.verifyClientCode(clientCode);
    expect(codeResult.success, isTrue);
    await waitUntil(
      () => seekerActive?.status == BookingStatus.codeVerified,
      reason: 'the care seeker to see the verified code',
    );

    final safetyButtonId = seekerActive!.safetyButtonId!;
    final button = await seeker.verifySafetyButton(
      ButtonVerification(
        method: ButtonVerificationMethod.qr,
        payload: safetyButtonId,
      ),
    );
    expect(button.success, isTrue);
    await waitUntil(
      () => caregiverActive?.status == BookingStatus.active,
      reason: 'the session to start',
    );

    await caregiver.completeSession();
    await waitUntil(
      () => earnings?.earnings.isNotEmpty == true,
      reason: 'earnings to be credited',
    );
    expect(earnings!.availableBalance, greaterThan(0));
    expect(earnings!.earnings.first.kind, EarningKind.session);

    await seeker.rateCaregiver(
      CaregiverRating(
        bookingId: booking.id,
        caregiverId: caregiverId,
        stars: 5,
        comment: 'Kind and punctual.',
      ),
    );
    await waitUntil(
      () => feedback.isNotEmpty,
      reason: 'the rating to reach the caregiver',
    );
    expect(feedback.first.stars, 5);
  });

  test('a request reports no match when no caregiver is available', () async {
    await seeker.signUp(name: 'Sari', email: 'sari@campus.ac.id', password: 'secret1');
    final booking = await seeker.submitRequest(helpRequest());
    expect(booking.status, BookingStatus.noMatch);
  });
}
