import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_data.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/features/auth_onboarding/domain/entities/caregiver_user.dart';
import 'package:care_merchant/features/auth_onboarding/presentation/bloc/auth_bloc.dart';

void main() {
  group('AuthBloc', () {
    late MockPlatformApiClient client;
    late AuthBloc authBloc;

    setUp(() {
      client = MockPlatformApiClient(
        latency: Duration.zero,
        initialProfile: MockData.pendingCaregiver,
      );
      authBloc = AuthBloc(apiClient: client);
    });

    tearDown(() {
      authBloc.close();
      client.dispose();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, NeedsVerification] when pending caregiver logs in',
      build: () => authBloc,
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'budi.santoso@itb.ac.id',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        NeedsVerification(MockData.pendingCaregiver),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when verified caregiver logs in',
      build: () {
        final verifiedClient = MockPlatformApiClient(
          latency: Duration.zero,
          initialProfile: MockData.verifiedCaregiver,
        );
        return AuthBloc(apiClient: verifiedClient);
      },
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'alya.putri@ui.ac.id',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        const Authenticated(MockData.verifiedCaregiver),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'transitions from NeedsVerification to Authenticated after SafetyModuleCompleted',
      build: () => authBloc,
      seed: () => NeedsVerification(MockData.pendingCaregiver),
      act: (bloc) => bloc.add(const SafetyModuleCompleted()),
      expect: () => [
        const AuthLoading(),
        Authenticated(MockData.pendingCaregiver.copyWith(
          safetyBadgeEarned: true,
          verificationStatus: VerificationStatus.approved,
        )),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] on LogoutRequested',
      build: () => authBloc,
      seed: () => const Authenticated(MockData.verifiedCaregiver),
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        const Unauthenticated(),
      ],
    );
  });
}
