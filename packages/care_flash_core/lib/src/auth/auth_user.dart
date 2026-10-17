import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? displayName;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
  });

  @override
  List<Object?> get props => [id, email, displayName];
}
