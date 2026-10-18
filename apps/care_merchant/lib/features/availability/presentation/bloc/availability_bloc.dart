import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/platform_api_client.dart';
import '../../../auth_onboarding/domain/entities/caregiver_user.dart';

// Events
abstract class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();
  @override
  List<Object?> get props => [];
}

class LoadAvailability extends AvailabilityEvent {
  final CaregiverProfile profile;

  const LoadAvailability(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ToggleAvailability extends AvailabilityEvent {
  final bool isAvailable;

  const ToggleAvailability(this.isAvailable);

  @override
  List<Object?> get props => [isAvailable];
}

// States
abstract class AvailabilityState extends Equatable {
  const AvailabilityState();
  @override
  List<Object?> get props => [];
}

class AvailabilityInitial extends AvailabilityState {
  const AvailabilityInitial();
}

class AvailabilityLoaded extends AvailabilityState {
  final bool isAvailable;
  final CaregiverProfile profile;
  final bool isUpdating;
  final String? errorMessage;

  const AvailabilityLoaded({
    required this.isAvailable,
    required this.profile,
    this.isUpdating = false,
    this.errorMessage,
  });

  AvailabilityLoaded copyWith({
    bool? isAvailable,
    CaregiverProfile? profile,
    bool? isUpdating,
    String? errorMessage,
  }) {
    return AvailabilityLoaded(
      isAvailable: isAvailable ?? this.isAvailable,
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isAvailable, profile, isUpdating, errorMessage];
}

// BLoC
class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  final PlatformApiClient apiClient;

  AvailabilityBloc({required this.apiClient})
      : super(const AvailabilityInitial()) {
    on<LoadAvailability>(_onLoadAvailability);
    on<ToggleAvailability>(_onToggleAvailability);
  }

  void _onLoadAvailability(
    LoadAvailability event,
    Emitter<AvailabilityState> emit,
  ) {
    emit(AvailabilityLoaded(
      isAvailable: event.profile.isAvailable,
      profile: event.profile,
    ));
  }

  Future<void> _onToggleAvailability(
    ToggleAvailability event,
    Emitter<AvailabilityState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AvailabilityLoaded) return;

    // Safety rule check: verification approved and safety badge earned
    final profile = currentState.profile;
    if (event.isAvailable &&
        (profile.verificationStatus != VerificationStatus.approved ||
            !profile.safetyBadgeEarned)) {
      emit(currentState.copyWith(
        isAvailable: false,
        errorMessage:
            'Safety badge and approved verification required to go online.',
      ));
      return;
    }

    // Optimistic update
    final previousAvailability = currentState.isAvailable;
    emit(currentState.copyWith(
      isAvailable: event.isAvailable,
      errorMessage: null,
    ));

    try {
      await apiClient.setAvailability(event.isAvailable);
    } catch (e) {
      // Rollback on failure
      emit(currentState.copyWith(
        isAvailable: previousAvailability,
        errorMessage: 'Failed to update availability. Please try again.',
      ));
    }
  }
}
