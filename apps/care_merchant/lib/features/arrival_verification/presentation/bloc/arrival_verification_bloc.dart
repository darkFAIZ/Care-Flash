import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/platform_api_client.dart';
import '../../../ride_transit/domain/entities/grab_ride_info.dart';
import '../../domain/entities/safety_button_payload.dart';

// Events
abstract class ArrivalVerificationEvent extends Equatable {
  const ArrivalVerificationEvent();
  @override
  List<Object?> get props => [];
}

class InitializeArrival extends ArrivalVerificationEvent {
  final AcceptedTrip trip;

  const InitializeArrival(this.trip);

  @override
  List<Object?> get props => [trip];
}

class VerifyClientCodeSubmitted extends ArrivalVerificationEvent {
  final String code;

  const VerifyClientCodeSubmitted(this.code);

  @override
  List<Object?> get props => [code];
}

class ActivateSafetyButtonRequested extends ArrivalVerificationEvent {
  const ActivateSafetyButtonRequested();
}

class SeekerScanConfirmed extends ArrivalVerificationEvent {
  const SeekerScanConfirmed();
}

class SimulateSeekerScan extends ArrivalVerificationEvent {
  const SimulateSeekerScan();
}

// States
abstract class ArrivalVerificationState extends Equatable {
  const ArrivalVerificationState();
  @override
  List<Object?> get props => [];
}

class ArrivalInitial extends ArrivalVerificationState {
  const ArrivalInitial();
}

class Stage1AwaitingCode extends ArrivalVerificationState {
  final AcceptedTrip trip;
  final bool isVerifying;
  final String? errorMessage;

  const Stage1AwaitingCode({
    required this.trip,
    this.isVerifying = false,
    this.errorMessage,
  });

  Stage1AwaitingCode copyWith({
    AcceptedTrip? trip,
    bool? isVerifying,
    String? errorMessage,
  }) {
    return Stage1AwaitingCode(
      trip: trip ?? this.trip,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [trip, isVerifying, errorMessage];
}

class Stage2AwaitingScan extends ArrivalVerificationState {
  final AcceptedTrip trip;
  final SafetyButtonPayload payload;

  const Stage2AwaitingScan({
    required this.trip,
    required this.payload,
  });

  @override
  List<Object?> get props => [trip, payload];
}

class HandoverComplete extends ArrivalVerificationState {
  final AcceptedTrip trip;
  final SafetyButtonPayload payload;

  const HandoverComplete({
    required this.trip,
    required this.payload,
  });

  @override
  List<Object?> get props => [trip, payload];
}

class ArrivalError extends ArrivalVerificationState {
  final String message;

  const ArrivalError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ArrivalVerificationBloc
    extends Bloc<ArrivalVerificationEvent, ArrivalVerificationState> {
  final PlatformApiClient apiClient;
  StreamSubscription<bool>? _scanSubscription;

  ArrivalVerificationBloc({required this.apiClient})
      : super(const ArrivalInitial()) {
    on<InitializeArrival>(_onInitializeArrival);
    on<VerifyClientCodeSubmitted>(_onVerifyClientCodeSubmitted);
    on<ActivateSafetyButtonRequested>(_onActivateSafetyButtonRequested);
    on<SeekerScanConfirmed>(_onSeekerScanConfirmed);
    on<SimulateSeekerScan>(_onSimulateSeekerScan);

    _scanSubscription = apiClient.seekerButtonScanStream.listen((scanned) {
      if (scanned) {
        add(const SeekerScanConfirmed());
      }
    });
  }

  void _onInitializeArrival(
    InitializeArrival event,
    Emitter<ArrivalVerificationState> emit,
  ) {
    emit(Stage1AwaitingCode(trip: event.trip));
  }

  Future<void> _onVerifyClientCodeSubmitted(
    VerifyClientCodeSubmitted event,
    Emitter<ArrivalVerificationState> emit,
  ) async {
    final currentState = state;
    AcceptedTrip? trip;
    if (currentState is Stage1AwaitingCode) {
      trip = currentState.trip;
    }

    if (trip == null) return;

    emit(Stage1AwaitingCode(trip: trip, isVerifying: true));

    try {
      final isValid = await apiClient.verifyClientCode(trip.bookingId, event.code);
      if (!isValid) {
        emit(Stage1AwaitingCode(
          trip: trip,
          isVerifying: false,
          errorMessage:
              'Invalid 6-digit client code. Please check with care seeker.',
        ));
        return;
      }

      // Valid: automatically proceed to activate safety button and generate Stage 2 QR
      final payload = await apiClient.activateSafetyButton(trip.bookingId);
      emit(Stage2AwaitingScan(trip: trip, payload: payload));
    } catch (e) {
      emit(Stage1AwaitingCode(
        trip: trip,
        isVerifying: false,
        errorMessage: 'Verification failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onActivateSafetyButtonRequested(
    ActivateSafetyButtonRequested event,
    Emitter<ArrivalVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Stage1AwaitingCode) return;
    final trip = currentState.trip;

    try {
      final payload = await apiClient.activateSafetyButton(trip.bookingId);
      emit(Stage2AwaitingScan(trip: trip, payload: payload));
    } catch (e) {
      emit(ArrivalError(e.toString()));
    }
  }

  void _onSeekerScanConfirmed(
    SeekerScanConfirmed event,
    Emitter<ArrivalVerificationState> emit,
  ) {
    final currentState = state;
    if (currentState is Stage2AwaitingScan) {
      emit(HandoverComplete(
        trip: currentState.trip,
        payload: currentState.payload,
      ));
    }
  }

  void _onSimulateSeekerScan(
    SimulateSeekerScan event,
    Emitter<ArrivalVerificationState> emit,
  ) {
    final currentState = state;
    if (currentState is Stage2AwaitingScan) {
      apiClient.simulateSeekerButtonScan(currentState.trip.bookingId);
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}
