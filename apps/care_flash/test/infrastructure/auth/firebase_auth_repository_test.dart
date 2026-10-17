import 'package:care_flash/infrastructure/auth/auth_failures.dart';
import 'package:care_flash/infrastructure/auth/firebase_auth_repository.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FirebaseAuthRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    repository = FirebaseAuthRepository(firebaseAuth: mockAuth);
  });

  group('FirebaseAuthRepository', () {
    test('currentUser returns mapped AuthUser when user is logged in', () async {
      final mockUser = MockUser(uid: 'user_123', email: 'test@example.com');
      mockAuth.mockUser = mockUser;

      await repository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      final user = repository.currentUser;
      expect(user, isNotNull);
      expect(user?.id, 'user_123');
      expect(user?.email, 'test@example.com');
    });

    test('currentUser returns null when no user is logged in', () {
      expect(repository.currentUser, isNull);
    });

    test('signOut clears current user', () async {
      final mockUser = MockUser(uid: 'user_123', email: 'test@example.com');
      mockAuth.mockUser = mockUser;

      await repository.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(repository.currentUser, isNotNull);

      await repository.signOut();
      expect(repository.currentUser, isNull);
    });

    test('signUpWithEmailAndPassword creates user and updates currentUser', () async {
      await repository.signUpWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'password123',
      );

      expect(repository.currentUser?.email, 'newuser@example.com');
    });

    test('authStateChanges emits correct stream events', () async {
      expectLater(
        repository.authStateChanges,
        emitsInOrder([
          isNull,
          predicate((user) => user != null && (user as dynamic).email == 'stream@example.com'),
        ]),
      );

      await repository.signUpWithEmailAndPassword(
        email: 'stream@example.com',
        password: 'password123',
      );
    });
  });
}
