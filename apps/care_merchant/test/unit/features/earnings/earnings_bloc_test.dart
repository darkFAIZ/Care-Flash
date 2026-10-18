import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_data.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/features/earnings/presentation/bloc/earnings_bloc.dart';

void main() {
  group('EarningsBloc', () {
    late MockPlatformApiClient client;

    setUp(() {
      client = MockPlatformApiClient(latency: Duration.zero);
    });

    tearDown(() {
      client.dispose();
    });

    test('initial state is EarningsInitial', () {
      final bloc = EarningsBloc(apiClient: client);
      expect(bloc.state, const EarningsInitial());
      bloc.close();
    });

    blocTest<EarningsBloc, EarningsState>(
      'FetchEarningsRequested emits [EarningsLoading, EarningsLoaded] with ledger',
      build: () => EarningsBloc(apiClient: client),
      act: (bloc) => bloc.add(const FetchEarningsRequested()),
      expect: () => [
        const EarningsLoading(),
        EarningsLoaded(ledger: MockData.sampleEarnings),
      ],
    );

    blocTest<EarningsBloc, EarningsState>(
      'WithdrawalRequested successfully updates ledger balance',
      build: () => EarningsBloc(apiClient: client),
      seed: () => EarningsLoaded(ledger: MockData.sampleEarnings),
      act: (bloc) => bloc.add(const WithdrawalRequested(
        amountIdr: 50000,
        bankName: 'BCA',
        accountNumber: '1234567890',
      )),
      expect: () => [
        isA<EarningsLoaded>()
            .having(
              (s) => s.ledger.availableBalanceIdr,
              'balance',
              MockData.sampleEarnings.availableBalanceIdr - 50000,
            )
            .having((s) => s.successMessage, 'success', isNotNull),
      ],
    );

    blocTest<EarningsBloc, EarningsState>(
      'WithdrawalRequested fails if amount exceeds available balance',
      build: () => EarningsBloc(apiClient: client),
      seed: () => EarningsLoaded(ledger: MockData.sampleEarnings),
      act: (bloc) => bloc.add(const WithdrawalRequested(
        amountIdr: 99999999,
        bankName: 'BCA',
        accountNumber: '1234567890',
      )),
      expect: () => [
        isA<EarningsLoaded>().having(
          (s) => s.errorMessage,
          'error',
          'Insufficient available balance for withdrawal.',
        ),
      ],
    );
  });
}
