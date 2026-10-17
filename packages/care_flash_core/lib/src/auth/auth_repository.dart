import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<void> signInWithEmailAndPassword({required String email, required String password});
  Future<void> signUpWithEmailAndPassword({required String email, required String password});
  Future<void> signOut();
}
