import '../models/account.dart';

/// Account operations for the care seeker. (FR-CS-1, FR-CS-2)
///
/// The default implementation is the mock platform. It can be replaced by an
/// HTTP implementation later without changing the app (AGENTS.md §5).
abstract interface class AuthRepository {
  /// The signed-in care seeker, or null when signed out.
  CareSeeker? get currentUser;

  /// Emits the signed-in care seeker whenever the session changes.
  Stream<CareSeeker?> watchCurrentUser();

  /// Creates an account and signs the care seeker in. (FR-CS-1)
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Signs an existing care seeker in. (FR-CS-1)
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  /// Signs the care seeker out. (FR-CS-2)
  Future<void> signOut();
}
