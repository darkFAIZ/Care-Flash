import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/platform_api_client.dart';
import '../../domain/entities/caregiver_user.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String university;
  final CaregiverGender gender;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.university,
    required this.gender,
  });

  @override
  List<Object?> get props => [email, password, fullName, university, gender];
}

class StudentIdSubmitted extends AuthEvent {
  final String studentIdNumber;
  final String photoUrl;

  const StudentIdSubmitted({
    required this.studentIdNumber,
    required this.photoUrl,
  });

  @override
  List<Object?> get props => [studentIdNumber, photoUrl];
}

class SafetyModuleCompleted extends AuthEvent {
  const SafetyModuleCompleted();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthRequested extends AuthEvent {
  const CheckAuthRequested();
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final CaregiverProfile profile;

  const Authenticated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class NeedsVerification extends AuthState {
  final CaregiverProfile profile;

  const NeedsVerification(this.profile);

  @override
  List<Object?> get props => [profile];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final PlatformApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<StudentIdSubmitted>(_onStudentIdSubmitted);
    on<SafetyModuleCompleted>(_onSafetyModuleCompleted);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthRequested>(_onCheckAuthRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await apiClient.login(event.email, event.password);
      if (profile.verificationStatus == VerificationStatus.approved &&
          profile.safetyBadgeEarned) {
        emit(Authenticated(profile));
      } else {
        emit(NeedsVerification(profile));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await apiClient.register(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        university: event.university,
        gender: event.gender,
      );
      emit(NeedsVerification(profile));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onStudentIdSubmitted(
    StudentIdSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await apiClient.submitStudentId(
        event.studentIdNumber,
        event.photoUrl,
      );
      emit(NeedsVerification(profile));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSafetyModuleCompleted(
    SafetyModuleCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await apiClient.completeSafetyModule();
      if (profile.verificationStatus == VerificationStatus.approved &&
          profile.safetyBadgeEarned) {
        emit(Authenticated(profile));
      } else {
        emit(NeedsVerification(profile));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated());
  }

  Future<void> _onCheckAuthRequested(
    CheckAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await apiClient.getProfile();
      if (profile.verificationStatus == VerificationStatus.approved &&
          profile.safetyBadgeEarned) {
        emit(Authenticated(profile));
      } else {
        emit(NeedsVerification(profile));
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }
}
