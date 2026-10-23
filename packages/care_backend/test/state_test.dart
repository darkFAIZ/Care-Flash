import 'package:care_backend/care_backend.dart';
import 'package:care_domain/care_domain.dart';
import 'package:test/test.dart';

void main() {
  late CareBackendState state;

  /// Signs a caregiver up and takes them through onboarding to "available".
  String onboardCaregiver({Gender gender = Gender.female}) {
    final auth = state.caregiverSignUp(
      name: 'Ayu Lestari',
      email: 'ayu@care.org',
      password: 'secret1',
      gender: gender,
    );
    final id = (auth['user'] as Map<String, Object?>)['id']! as String;
    state.submitVerification(
      id,
      residentialIdNumber: '220001',
      documentLabel: 'identity-card.jpg',
    );
    state.completeSafetyModule(id);
    state.updateAvailability(id, CaregiverAvailability.available);
    return id;
  }

  String signInSeeker() {
    state.seekerSignUp(
      name: 'Sari',
      email: 'sari@care.org',
      password: 'secret1',
    );
    final auth = state.seekerSignIn(
      email: 'sari@care.org',
      password: 'secret1',
    );
    return (auth['user'] as Map<String, Object?>)['id']! as String;
  }

  Map<String, Object?> helpRequestArgs() => {
    'helpType': HelpType.takeCare.name,
    'description': 'Need company while I study.',
    'checklist': BoundaryChecklist.suggested.toJson(),
    'location': VisitLocation.mockPresets.first.toJson(),
    'scheduledAt': DateTime.now()
        .add(const Duration(hours: 1))
        .toIso8601String(),
    'duration': VisitDuration.sixty.name,
    'genderFilter': GenderFilter.both.name,
  };

  setUp(() => state = CareBackendState());

  test('a seeker request reaches an available caregiver and completes', () {
    final caregiverId = onboardCaregiver();
    final seekerId = signInSeeker();

    // 1. The seeker submits and is matched to the available caregiver.
    final matched = state.submitRequest(seekerId, helpRequestArgs());
    expect(matched['status'], BookingStatus.matched.name);
    expect((matched['caregiver'] as Map<String, Object?>?)?['id'], caregiverId);

    final bookingId = matched['id']! as String;
    expect(matched['clientCode'], isNull);

    // 2. The seeker pays; the request is then offered to the caregiver.
    final payment = state.pay(seekerId, bookingId, PaymentMethodType.gopay);
    expect(payment['success'], true);

    final caregiverOffer = state.caregiverSnapshot(
      caregiverId,
    )['incomingRequest'];
    expect(caregiverOffer, isNotNull);
    expect(
      (caregiverOffer as Map<String, Object?>)['status'],
      BookingStatus.paidPending.name,
    );

    // 3. The caregiver accepts and walks the session forward.
    state.acceptRequest(caregiverId);
    state.startTrip(caregiverId);
    state.markArrived(caregiverId);

    final code =
        (state.caregiverSnapshot(caregiverId)['activeBooking']
                as Map<String, Object?>)['clientCode']!
            as String;
    final seekerBooking =
        state.seekerSnapshot(seekerId)['activeBooking'] as Map<String, Object?>;
    expect(seekerBooking['clientCode'], isNull);
    final codeResult = state.verifyCaregiverCode(seekerId, code);
    expect(codeResult['success'], true);

    // 4. The seeker verifies the physical safety button, starting the session.
    final safetyButtonId =
        (state.seekerSnapshot(seekerId)['activeBooking']
                as Map<String, Object?>)['safetyButtonId']!
            as String;
    final buttonResult = state.verifySafetyButton(
      seekerId,
      ButtonVerification(
        method: ButtonVerificationMethod.qr,
        payload: safetyButtonId,
      ),
    );
    expect(buttonResult['success'], true);

    // 5. The caregiver completes; earnings are credited.
    state.completeSession(caregiverId);
    final earnings =
        state.caregiverSnapshot(caregiverId)['earnings']
            as Map<String, Object?>;
    final earningsList = earnings['earnings']! as List<Object?>;
    expect(earningsList, isNotEmpty);
    final entry = earningsList.first! as Map<String, Object?>;
    expect(entry['kind'], EarningKind.session.name);
    expect(entry['amount'], greaterThan(0));

    // 6. The seeker rates the caregiver; the feedback reaches the caregiver.
    state.rateCaregiver(seekerId, {
      'bookingId': bookingId,
      'caregiverId': caregiverId,
      'stars': 5,
      'comment': 'Kind and punctual.',
    });
    final feedback =
        state.caregiverSnapshot(caregiverId)['feedbackReceived']
            as List<Object?>;
    expect(feedback, isNotEmpty);
    expect((feedback.first! as Map<String, Object?>)['stars'], 5);
  });

  test('an unverified caregiver is not offered requests', () {
    // Caregiver signs up but never completes onboarding.
    final auth = state.caregiverSignUp(
      name: 'Budi',
      email: 'budi@care.org',
      password: 'secret1',
      gender: Gender.male,
    );
    final caregiverId = (auth['user'] as Map<String, Object?>)['id']! as String;
    final seekerId = signInSeeker();

    final result = state.submitRequest(seekerId, helpRequestArgs());
    expect(result['status'], BookingStatus.noMatch.name);
    expect(state.caregiverSnapshot(caregiverId)['incomingRequest'], isNull);
  });

  test('a gender filter can exclude a caregiver of the wrong gender', () {
    onboardCaregiver(gender: Gender.female);
    final seekerId = signInSeeker();

    final args = helpRequestArgs()..['genderFilter'] = GenderFilter.male.name;
    final result = state.submitRequest(seekerId, args);
    expect(result['status'], BookingStatus.noMatch.name);
  });

  test('a new caregiver starts unsubmitted and is approved on submission', () {
    // The app routes `notSubmitted` into the onboarding form but `pending` into
    // a dead-end status screen, so signup must start unsubmitted. (FR-CM-2)
    final auth = state.caregiverSignUp(
      name: 'Budi',
      email: 'budi@care.org',
      password: 'secret1',
      gender: Gender.male,
    );
    final caregiverId = (auth['user'] as Map<String, Object?>)['id']! as String;
    expect(state.caregiverSnapshot(caregiverId)['currentCaregiver'], isNotNull);
    final fresh = CaregiverAccount.fromJson(
      state.caregiverSnapshot(caregiverId)['currentCaregiver']!
          as Map<String, Object?>,
    );
    expect(fresh.verificationStatus, VerificationStatus.notSubmitted);

    // Submitting the residential ID is auto-approved by the demo backend, so the
    // caregiver is never left stuck "under review".
    state.submitVerification(
      caregiverId,
      residentialIdNumber: '220001',
      documentLabel: 'identity-card.jpg',
    );
    final after = CaregiverAccount.fromJson(
      state.caregiverSnapshot(caregiverId)['currentCaregiver']!
          as Map<String, Object?>,
    );
    expect(after.verificationStatus, VerificationStatus.approved);
    expect(after.isVerified, isTrue);
  });
}
