import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_data.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/features/auth_onboarding/domain/entities/caregiver_user.dart';
import 'package:care_merchant/features/availability/presentation/bloc/availability_bloc.dart';

void main() {
  group('AvailabilityBloc', () {
    late MockPlatformApiClient client;

    setUp(() {
      client = MockPlatformApiClient(latency: Duration.zero);
    });

    tearDown(() {
      client.dispose();
    });

    test('initial state has correct defaults', () {
      final bloc = AvailabilityBloc(apiClient: client);
      expect(bloc.state, const AvailabilityInitial());
      bloc.close();
    });

    blocTest<AvailabilityBloc, AvailabilityState>(
      'Toggle fails when safetyBadgeEarned is false',
      build: () => AvailabilityBloc(apiClient: client),
      seed: () => const AvailabilityLoaded(
        isAvailable: false,
        profile: MockData.pendingCaregiver,
      ),
      act: (bloc) => bloc.add(const ToggleAvailability(true)),
      expect: () => [
        const AvailabilityLoaded(
          isAvailable: false,
          profile: MockData.pendingCaregiver,
          errorMessage:
              'Safety badge and approved verification required to go online.',
        ),
      ],
    );

    blocTest<AvailabilityBloc, AvailabilityState>(
      'Toggle succeeds optimistically when verified with safety badge',
      build: () => AvailabilityBloc(apiClient: client),
      seed: () => const AvailabilityLoaded(
        isAvailable: false,
        profile: MockData.verifiedCaregiver,
      ),
      act: (bloc) => bloc.add(const ToggleAvailability(true)),
      expect: () => [
        const AvailabilityLoaded(
          isAvailable: true,
          profile: MockData.verifiedCaregiver,
        ),
      ],
      verify: (_) async {
        final profile = await client.getProfile();
        expect(profile.isAvailable, isTrue);
      },
    );
  });
}
