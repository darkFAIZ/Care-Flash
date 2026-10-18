import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/features/active_session/domain/entities/active_session.dart';
import 'package:care_merchant/features/active_session/presentation/bloc/active_session_bloc.dart';

void main() {
  group('ActiveSessionBloc', () {
    late MockPlatformApiClient client;
    const testSession = ActiveSession(
      sessionId: 'SES-001',
      bookingId: 'BK-9812',
      careSeekerName: 'Ibu Ratna',
      totalDurationSeconds: 3600,
      remainingSeconds: 3600,
      basePayoutIdr: 50000,
      boundaries: [
        BoundaryItem(id: 'b1', title: 'Light walking support only'),
        BoundaryItem(id: 'b2', title: 'No lifting > 15kg'),
      ],
    );

    setUp(() {
      client = MockPlatformApiClient(latency: Duration.zero);
    });

    tearDown(() {
      client.dispose();
    });

    test('initial state is ActiveSessionInitial', () {
      final bloc = ActiveSessionBloc(apiClient: client);
      expect(bloc.state, const ActiveSessionInitial());
      bloc.close();
    });

    blocTest<ActiveSessionBloc, ActiveSessionState>(
      'SosEmergencyTriggered immediately ends session with caregiver compensation protected',
      build: () => ActiveSessionBloc(apiClient: client),
      seed: () => const ActiveSessionRunning(session: testSession),
      act: (bloc) => bloc.add(const SosEmergencyTriggered()),
      expect: () => [
        isA<ActiveSessionSosTriggered>().having(
          (s) => s.protectedEarningsIdr,
          'earnings',
          50000,
        ),
      ],
    );

    blocTest<ActiveSessionBloc, ActiveSessionState>(
      'SeekerEarlyEndReceived calculates 50% compensation rule',
      build: () => ActiveSessionBloc(apiClient: client),
      seed: () => const ActiveSessionRunning(session: testSession),
      act: (bloc) => bloc.add(const SeekerEarlyEndReceived()),
      expect: () => [
        isA<ActiveSessionEarlyEnded>().having(
          (s) => s.compensationEarningsIdr,
          'earnings',
          25000, // 50% of 50000
        ),
      ],
    );

    blocTest<ActiveSessionBloc, ActiveSessionState>(
      'CompleteSessionRequested awards 100% earnings',
      build: () => ActiveSessionBloc(apiClient: client),
      seed: () => const ActiveSessionRunning(session: testSession),
      act: (bloc) => bloc.add(const CompleteSessionRequested()),
      expect: () => [
        isA<ActiveSessionCompleted>().having(
          (s) => s.finalEarningsIdr,
          'earnings',
          50000,
        ),
      ],
    );

    blocTest<ActiveSessionBloc, ActiveSessionState>(
      'ToggleBoundary toggles acknowledged status',
      build: () => ActiveSessionBloc(apiClient: client),
      seed: () => const ActiveSessionRunning(session: testSession),
      act: (bloc) => bloc.add(const ToggleBoundary('b1')),
      expect: () => [
        isA<ActiveSessionRunning>().having(
          (s) => s.session.boundaries.first.isAcknowledged,
          'acknowledged',
          true,
        ),
      ],
    );
  });
}
