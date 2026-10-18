import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/platform_api_client.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../ride_transit/domain/entities/grab_ride_info.dart';
import '../../domain/entities/request_offer.dart';

// Events
abstract class MatchingEvent extends Equatable {
  const MatchingEvent();
  @override
  List<Object?> get props => [];
}

class StartListeningOffers extends MatchingEvent {
  const StartListeningOffers();
}

class OfferReceived extends MatchingEvent {
  final RequestOffer offer;

  const OfferReceived(this.offer);

  @override
  List<Object?> get props => [offer];
}

class MatchingTick extends MatchingEvent {
  final int secondsRemaining;

  const MatchingTick(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

class AcceptOfferRequested extends MatchingEvent {
  final String requestReference;

  const AcceptOfferRequested(this.requestReference);

  @override
  List<Object?> get props => [requestReference];
}

class DeclineOfferRequested extends MatchingEvent {
  final String requestReference;

  const DeclineOfferRequested(this.requestReference);

  @override
  List<Object?> get props => [requestReference];
}

class TriggerSimulatedOffer extends MatchingEvent {
  const TriggerSimulatedOffer();
}

class DismissOfferDialog extends MatchingEvent {
  const DismissOfferDialog();
}

// States
abstract class MatchingState extends Equatable {
  const MatchingState();
  @override
  List<Object?> get props => [];
}

class MatchingInitial extends MatchingState {
  const MatchingInitial();
}

class MatchingListening extends MatchingState {
  const MatchingListening();
}

class OfferIncoming extends MatchingState {
  final RequestOffer offer;
  final int secondsRemaining;

  const OfferIncoming({
    required this.offer,
    required this.secondsRemaining,
  });

  OfferIncoming copyWith({
    RequestOffer? offer,
    int? secondsRemaining,
  }) {
    return OfferIncoming(
      offer: offer ?? this.offer,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }

  @override
  List<Object?> get props => [offer, secondsRemaining];
}

class OfferAccepting extends MatchingState {
  const OfferAccepting();
}

class OfferAccepted extends MatchingState {
  final AcceptedTrip trip;

  const OfferAccepted(this.trip);

  @override
  List<Object?> get props => [trip];
}

class OfferDeclined extends MatchingState {
  const OfferDeclined();
}

class OfferTimeout extends MatchingState {
  const OfferTimeout();
}

class MatchingError extends MatchingState {
  final String message;

  const MatchingError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MatchingBloc extends Bloc<MatchingEvent, MatchingState> {
  final PlatformApiClient apiClient;
  StreamSubscription<RequestOffer>? _requestSubscription;
  Timer? _tickerTimer;

  MatchingBloc({required this.apiClient}) : super(const MatchingInitial()) {
    on<StartListeningOffers>(_onStartListeningOffers);
    on<OfferReceived>(_onOfferReceived);
    on<MatchingTick>(_onMatchingTick);
    on<AcceptOfferRequested>(_onAcceptOfferRequested);
    on<DeclineOfferRequested>(_onDeclineOfferRequested);
    on<TriggerSimulatedOffer>(_onTriggerSimulatedOffer);
    on<DismissOfferDialog>(_onDismissOfferDialog);

    _requestSubscription = apiClient.requestStream.listen((offer) {
      add(OfferReceived(offer));
    });
  }

  void _onStartListeningOffers(
    StartListeningOffers event,
    Emitter<MatchingState> emit,
  ) {
    emit(const MatchingListening());
  }

  void _onOfferReceived(
    OfferReceived event,
    Emitter<MatchingState> emit,
  ) {
    _tickerTimer?.cancel();
    emit(OfferIncoming(offer: event.offer, secondsRemaining: 30));

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentRemaining = 30 - timer.tick;
      if (currentRemaining <= 0) {
        timer.cancel();
        add(const MatchingTick(0));
      } else {
        add(MatchingTick(currentRemaining));
      }
    });
  }

  void _onMatchingTick(
    MatchingTick event,
    Emitter<MatchingState> emit,
  ) {
    if (event.secondsRemaining <= 0) {
      _tickerTimer?.cancel();
      emit(const OfferTimeout());
    } else {
      final currentState = state;
      if (currentState is OfferIncoming) {
        emit(currentState.copyWith(secondsRemaining: event.secondsRemaining));
      }
    }
  }

  Future<void> _onAcceptOfferRequested(
    AcceptOfferRequested event,
    Emitter<MatchingState> emit,
  ) async {
    _tickerTimer?.cancel();
    emit(const OfferAccepting());
    try {
      final trip = await apiClient.acceptOffer(event.requestReference);
      emit(OfferAccepted(trip));
    } catch (e) {
      emit(MatchingError(e.toString()));
    }
  }

  Future<void> _onDeclineOfferRequested(
    DeclineOfferRequested event,
    Emitter<MatchingState> emit,
  ) async {
    _tickerTimer?.cancel();
    try {
      await apiClient.declineOffer(event.requestReference);
      emit(const OfferDeclined());
    } catch (e) {
      emit(MatchingError(e.toString()));
    }
  }

  void _onTriggerSimulatedOffer(
    TriggerSimulatedOffer event,
    Emitter<MatchingState> emit,
  ) {
    final offer = MockData.sampleOffer();
    apiClient.simulateIncomingOffer(offer);
  }

  void _onDismissOfferDialog(
    DismissOfferDialog event,
    Emitter<MatchingState> emit,
  ) {
    _tickerTimer?.cancel();
    emit(const MatchingListening());
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}
