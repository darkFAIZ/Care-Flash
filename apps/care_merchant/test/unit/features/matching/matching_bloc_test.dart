import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_data.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/features/matching/presentation/bloc/matching_bloc.dart';

void main() {
  group('MatchingBloc', () {
    late MockPlatformApiClient client;

    setUp(() {
      client = MockPlatformApiClient(latency: Duration.zero);
    });

    tearDown(() {
      client.dispose();
    });

    test('initial state is MatchingInitial', () {
      final bloc = MatchingBloc(apiClient: client);
      expect(bloc.state, const MatchingInitial());
      bloc.close();
    });

    blocTest<MatchingBloc, MatchingState>(
      'transitions to OfferIncoming with 30s remaining when offer arrives',
      build: () => MatchingBloc(apiClient: client),
      act: (bloc) {
        final offer = MockData.sampleOffer();
        bloc.add(OfferReceived(offer));
      },
      expect: () => [
        isA<OfferIncoming>().having((s) => s.secondsRemaining, 'secondsRemaining', 30),
      ],
    );

    blocTest<MatchingBloc, MatchingState>(
      'AcceptOfferRequested transitions to OfferAccepted with AcceptedTrip',
      build: () => MatchingBloc(apiClient: client),
      seed: () => OfferIncoming(
        offer: MockData.sampleOffer(),
        secondsRemaining: 25,
      ),
      act: (bloc) => bloc.add(const AcceptOfferRequested('CR-2026-9812')),
      expect: () => [
        const OfferAccepting(),
        isA<OfferAccepted>().having((s) => s.trip.requestReference, 'ref', 'CR-2026-9812'),
      ],
    );

    blocTest<MatchingBloc, MatchingState>(
      'DeclineOfferRequested transitions to OfferDeclined without rating penalty',
      build: () => MatchingBloc(apiClient: client),
      seed: () => OfferIncoming(
        offer: MockData.sampleOffer(),
        secondsRemaining: 20,
      ),
      act: (bloc) => bloc.add(const DeclineOfferRequested('CR-2026-9812')),
      expect: () => [
        const OfferDeclined(),
      ],
    );

    blocTest<MatchingBloc, MatchingState>(
      'MatchingTick reaching 0 emits OfferTimeout',
      build: () => MatchingBloc(apiClient: client),
      seed: () => OfferIncoming(
        offer: MockData.sampleOffer(),
        secondsRemaining: 1,
      ),
      act: (bloc) => bloc.add(const MatchingTick(0)),
      expect: () => [
        const OfferTimeout(),
      ],
    );
  });
}
