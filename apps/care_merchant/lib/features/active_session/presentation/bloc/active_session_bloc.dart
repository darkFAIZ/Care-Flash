import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/platform_api_client.dart';
import '../../domain/entities/active_session.dart';

// Events
abstract class ActiveSessionEvent extends Equatable {
  const ActiveSessionEvent();
  @override
  List<Object?> get props => [];
}

class StartActiveSession extends ActiveSessionEvent {
  final ActiveSession session;

  const StartActiveSession(this.session);

  @override
  List<Object?> get props => [session];
}

class SessionTick extends ActiveSessionEvent {
  final int remainingSeconds;

  const SessionTick(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}

class ToggleBoundary extends ActiveSessionEvent {
  final String boundaryId;

  const ToggleBoundary(this.boundaryId);

  @override
  List<Object?> get props => [boundaryId];
}

class CompleteSessionRequested extends ActiveSessionEvent {
  const CompleteSessionRequested();
}

class SosEmergencyTriggered extends ActiveSessionEvent {
  const SosEmergencyTriggered();
}

class SeekerEarlyEndReceived extends ActiveSessionEvent {
  const SeekerEarlyEndReceived();
}

// States
abstract class ActiveSessionState extends Equatable {
  const ActiveSessionState();
  @override
  List<Object?> get props => [];
}

class ActiveSessionInitial extends ActiveSessionState {
  const ActiveSessionInitial();
}

class ActiveSessionRunning extends ActiveSessionState {
  final ActiveSession session;

  const ActiveSessionRunning({required this.session});

  @override
  List<Object?> get props => [session];
}

class ActiveSessionCompleted extends ActiveSessionState {
  final ActiveSession session;
  final int finalEarningsIdr;

  const ActiveSessionCompleted({
    required this.session,
    required this.finalEarningsIdr,
  });

  @override
  List<Object?> get props => [session, finalEarningsIdr];
}

class ActiveSessionEarlyEnded extends ActiveSessionState {
  final ActiveSession session;
  final int compensationEarningsIdr;

  const ActiveSessionEarlyEnded({
    required this.session,
    required this.compensationEarningsIdr,
  });

  @override
  List<Object?> get props => [session, compensationEarningsIdr];
}

class ActiveSessionSosTriggered extends ActiveSessionState {
  final ActiveSession session;
  final int protectedEarningsIdr;

  const ActiveSessionSosTriggered({
    required this.session,
    required this.protectedEarningsIdr,
  });

  @override
  List<Object?> get props => [session, protectedEarningsIdr];
}

// BLoC
class ActiveSessionBloc extends Bloc<ActiveSessionEvent, ActiveSessionState> {
  final PlatformApiClient apiClient;
  Timer? _tickerTimer;
  StreamSubscription<SessionOutcomeType>? _outcomeSubscription;

  ActiveSessionBloc({required this.apiClient})
      : super(const ActiveSessionInitial()) {
    on<StartActiveSession>(_onStartActiveSession);
    on<SessionTick>(_onSessionTick);
    on<ToggleBoundary>(_onToggleBoundary);
    on<CompleteSessionRequested>(_onCompleteSessionRequested);
    on<SosEmergencyTriggered>(_onSosEmergencyTriggered);
    on<SeekerEarlyEndReceived>(_onSeekerEarlyEndReceived);

    _outcomeSubscription =
        apiClient.sessionOutcomeStream.listen((outcome) {
      if (outcome == SessionOutcomeType.careSeekerEarlyEnd) {
        add(const SeekerEarlyEndReceived());
      } else if (outcome == SessionOutcomeType.caregiverSosTriggered) {
        add(const SosEmergencyTriggered());
      }
    });
  }

  void _onStartActiveSession(
    StartActiveSession event,
    Emitter<ActiveSessionState> emit,
  ) {
    _tickerTimer?.cancel();
    emit(ActiveSessionRunning(session: event.session));

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = event.session.remainingSeconds - timer.tick;
      if (remaining <= 0) {
        timer.cancel();
        add(const SessionTick(0));
      } else {
        add(SessionTick(remaining));
      }
    });
  }

  void _onSessionTick(
    SessionTick event,
    Emitter<ActiveSessionState> emit,
  ) {
    final currentState = state;
    if (currentState is ActiveSessionRunning) {
      emit(ActiveSessionRunning(
        session: currentState.session.copyWith(
          remainingSeconds: event.remainingSeconds,
        ),
      ));
    }
  }

  void _onToggleBoundary(
    ToggleBoundary event,
    Emitter<ActiveSessionState> emit,
  ) {
    final currentState = state;
    if (currentState is ActiveSessionRunning) {
      final updatedBoundaries = currentState.session.boundaries.map((b) {
        if (b.id == event.boundaryId) {
          return b.copyWith(isAcknowledged: !b.isAcknowledged);
        }
        return b;
      }).toList();

      emit(ActiveSessionRunning(
        session: currentState.session.copyWith(boundaries: updatedBoundaries),
      ));
    }
  }

  Future<void> _onCompleteSessionRequested(
    CompleteSessionRequested event,
    Emitter<ActiveSessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ActiveSessionRunning) return;

    _tickerTimer?.cancel();
    try {
      await apiClient.markWorkCompleted(currentState.session.sessionId);
      emit(ActiveSessionCompleted(
        session: currentState.session,
        finalEarningsIdr: currentState.session.basePayoutIdr,
      ));
    } catch (_) {
      emit(ActiveSessionCompleted(
        session: currentState.session,
        finalEarningsIdr: currentState.session.basePayoutIdr,
      ));
    }
  }

  Future<void> _onSosEmergencyTriggered(
    SosEmergencyTriggered event,
    Emitter<ActiveSessionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ActiveSessionRunning) return;

    _tickerTimer?.cancel();
    try {
      await apiClient.triggerSos(currentState.session.sessionId);
    } catch (_) {}

    // Caregiver compensation is guaranteed/protected
    emit(ActiveSessionSosTriggered(
      session: currentState.session,
      protectedEarningsIdr: currentState.session.basePayoutIdr,
    ));
  }

  void _onSeekerEarlyEndReceived(
    SeekerEarlyEndReceived event,
    Emitter<ActiveSessionState> emit,
  ) {
    final currentState = state;
    if (currentState is! ActiveSessionRunning) return;

    _tickerTimer?.cancel();
    // 50% early termination rule
    final compensation = (currentState.session.basePayoutIdr * 0.5).round();
    emit(ActiveSessionEarlyEnded(
      session: currentState.session,
      compensationEarningsIdr: compensation,
    ));
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    _outcomeSubscription?.cancel();
    return super.close();
  }
}
