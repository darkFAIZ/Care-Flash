import 'package:care_flash_core/auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'auth_failures.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository({firebase.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;

  @override
  Stream<AuthUser?> get authStateChanges => _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> signUpWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on firebase.FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  AuthUser? _mapUser(firebase.User? user) {
    if (user == null) return null;
    return AuthUser(id: user.uid, email: user.email ?? '');
  }

  AuthFailure _mapException(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'wrong-password':
        return const WrongPasswordFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return const UnknownAuthFailure();
    }
  }
}
