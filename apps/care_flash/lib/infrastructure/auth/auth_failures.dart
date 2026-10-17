import 'package:equatable/equatable.dart';

abstract class AuthFailure extends Equatable implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([super.message = 'Invalid email or password.']);
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure([super.message = 'Invalid email or password.']);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([super.message = 'An account already exists for that email.']);
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure([super.message = 'Network error. Please check your connection.']);
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([super.message = 'An unexpected authentication error occurred.']);
}
