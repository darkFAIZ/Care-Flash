import 'package:equatable/equatable.dart';

enum SessionOutcomeType {
  normalCompletion,
  careSeekerEarlyEnd,
  caregiverSosTriggered,
  preSessionDangerCancelled,
}

class BoundaryItem extends Equatable {
  final String id;
  final String title;
  final bool isAcknowledged;

  const BoundaryItem({
    required this.id,
    required this.title,
    this.isAcknowledged = false,
  });

  BoundaryItem copyWith({
    String? id,
    String? title,
    bool? isAcknowledged,
  }) {
    return BoundaryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  @override
  List<Object?> get props => [id, title, isAcknowledged];
}

class ActiveSession extends Equatable {
  final String sessionId;
  final String bookingId;
  final String careSeekerName;
  final int totalDurationSeconds;
  final int remainingSeconds;
  final List<BoundaryItem> boundaries;
  final bool isPaused;
  final SessionOutcomeType? outcome;
  final int basePayoutIdr;

  const ActiveSession({
    required this.sessionId,
    required this.bookingId,
    required this.careSeekerName,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.boundaries,
    this.isPaused = false,
    this.outcome,
    this.basePayoutIdr = 50000,
  });

  ActiveSession copyWith({
    String? sessionId,
    String? bookingId,
    String? careSeekerName,
    int? totalDurationSeconds,
    int? remainingSeconds,
    List<BoundaryItem>? boundaries,
    bool? isPaused,
    SessionOutcomeType? outcome,
    int? basePayoutIdr,
  }) {
    return ActiveSession(
      sessionId: sessionId ?? this.sessionId,
      bookingId: bookingId ?? this.bookingId,
      careSeekerName: careSeekerName ?? this.careSeekerName,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      boundaries: boundaries ?? this.boundaries,
      isPaused: isPaused ?? this.isPaused,
      outcome: outcome ?? this.outcome,
      basePayoutIdr: basePayoutIdr ?? this.basePayoutIdr,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        bookingId,
        careSeekerName,
        totalDurationSeconds,
        remainingSeconds,
        boundaries,
        isPaused,
        outcome,
        basePayoutIdr,
      ];
}
