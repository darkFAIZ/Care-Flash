import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_data.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/features/arrival_verification/domain/entities/safety_button_payload.dart';
import 'package:care_merchant/features/arrival_verification/presentation/bloc/arrival_verification_bloc.dart';

void main() {
  group('ArrivalVerificationBloc 2-Stage Handover', () {
    late MockPlatformApiClient client;

    setUp(() {
      client = MockPlatformApiClient(latency: Duration.zero);
    });

    tearDown(() {
      client.dispose();
    });

    test('initial state is ArrivalInitial', () {
      final bloc = ArrivalVerificationBloc(apiClient: client);
      expect(bloc.state, const ArrivalInitial());
      bloc.close();
    });

    blocTest<ArrivalVerificationBloc, ArrivalVerificationState>(
      'VerifyClientCodeSubmitted fails with invalid PIN',
      build: () => ArrivalVerificationBloc(apiClient: client),
      seed: () => const Stage1AwaitingCode(trip: MockData.sampleAcceptedTrip),
      act: (bloc) => bloc.add(const VerifyClientCodeSubmitted('000000')),
      expect: () => [
        const Stage1AwaitingCode(
          trip: MockData.sampleAcceptedTrip,
          isVerifying: true,
        ),
        const Stage1AwaitingCode(
          trip: MockData.sampleAcceptedTrip,
          isVerifying: false,
          errorMessage: 'Invalid 6-digit client code. Please check with care seeker.',
        ),
      ],
    );

    blocTest<ArrivalVerificationBloc, ArrivalVerificationState>(
      'VerifyClientCodeSubmitted succeeds with valid PIN and advances to Stage 2 QR generation',
      build: () => ArrivalVerificationBloc(apiClient: client),
      seed: () => const Stage1AwaitingCode(trip: MockData.sampleAcceptedTrip),
      act: (bloc) => bloc.add(const VerifyClientCodeSubmitted('123456')),
      expect: () => [
        const Stage1AwaitingCode(
          trip: MockData.sampleAcceptedTrip,
          isVerifying: true,
        ),
        isA<Stage2AwaitingScan>().having(
          (s) => s.payload.bookingId,
          'bookingId',
          MockData.sampleAcceptedTrip.bookingId,
        ),
      ],
    );

    blocTest<ArrivalVerificationBloc, ArrivalVerificationState>(
      'SeekerScanConfirmed transitions to HandoverComplete',
      build: () => ArrivalVerificationBloc(apiClient: client),
      seed: () => Stage2AwaitingScan(
        trip: MockData.sampleAcceptedTrip,
        payload: SafetyButtonPayload(
          bookingId: MockData.sampleAcceptedTrip.bookingId,
          buttonToken: 'BTN-TOK-9988',
          qrDataUri: 'uri',
          nfcPayloadString: 'payload',
          issuedAt: DateTime.now(),
        ),
      ),
      act: (bloc) => bloc.add(const SeekerScanConfirmed()),
      expect: () => [
        isA<HandoverComplete>(),
      ],
    );
  });
}
