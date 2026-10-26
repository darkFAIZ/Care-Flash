import 'dart:convert';

import 'package:care_backend/care_backend.dart';
import 'package:care_domain/care_domain.dart';
import 'package:test/test.dart';

void main() {
  group('authentication', () {
    test('sign up returns a token that resumes the same account', () {
      final state = CareBackendState();
      final auth = state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      );

      expect(auth['success'], isTrue);
      final token = auth['token']! as String;
      final user = auth['user']! as Map<String, Object?>;

      final session = state.resumeSession(token);
      expect(session, isNotNull);
      expect(session!['role'], 'seeker');
      expect((session['user']! as Map<String, Object?>)['id'], user['id']);
    });

    test('passwords are salted and hashed, never stored in plain text', () {
      final state = CareBackendState();
      state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      );
      state.caregiverSignUp(
        name: 'Ayu',
        email: 'ayu@campus.ac.id',
        password: 'secret1',
        gender: Gender.female,
      );

      final saved = jsonEncode(state.toJson());
      expect(saved.contains('secret1'), isFalse);

      final seekers = state.toJson()['seekerCredentials']! as Map<String, Object?>;
      final credential = seekers['sari@campus.ac.id']! as Map<String, Object?>;
      expect(credential['salt'], isA<String>());
      expect(credential['hash'], isNot('secret1'));
      expect((credential['hash']! as String).length, greaterThan(20));
    });

    test('wrong passwords and duplicate emails are rejected', () {
      final state = CareBackendState();
      state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      );

      expect(
        state.seekerSignIn(email: 'sari@campus.ac.id', password: 'wrongpw')['success'],
        isFalse,
      );
      expect(
        state.seekerSignUp(
          name: 'Other',
          email: ' sari@campus.ac.id ',
          password: 'secret2',
        )['success'],
        isFalse,
        reason: 'emails are compared after trimming',
      );
      final ok = state.seekerSignIn(
        email: 'sari@campus.ac.id',
        password: 'secret1',
      );
      expect(ok['success'], isTrue);
      expect(ok['token'], isA<String>());
    });

    test('signing out revokes only that token', () {
      final state = CareBackendState();
      final first = state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      )['token']! as String;
      final second = state.seekerSignIn(
        email: 'sari@campus.ac.id',
        password: 'secret1',
      )['token']! as String;

      state.signOut(first);
      expect(state.resumeSession(first), isNull);
      expect(state.resumeSession(second), isNotNull);
    });

    test('expired tokens are rejected', () {
      var now = DateTime(2026, 1, 1);
      final state = CareBackendState(clock: () => now);
      final token = state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      )['token']! as String;

      now = now.add(const Duration(days: 31));
      expect(state.resumeSession(token), isNull);
    });

    test('accounts and sessions survive a state round trip', () {
      var now = DateTime(2026, 1, 1);
      final state = CareBackendState(clock: () => now);
      state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      );
      final caregiverId = (state.caregiverSignUp(
        name: 'Ayu',
        email: 'ayu@campus.ac.id',
        password: 'secret1',
        gender: Gender.female,
      )['user']! as Map<String, Object?>)['id']! as String;
      final seekerId = (state.seekerSignIn(
        email: 'sari@campus.ac.id',
        password: 'secret1',
      )['user']! as Map<String, Object?>)['id']! as String;
      state.updateSeekerAvatar(seekerId, avatarDataUrl: 'data:image/png;base64,AAAA');
      state.updateCaregiverAvatar(caregiverId,
          avatarDataUrl: 'data:image/png;base64,BBBB');
      final token = state.seekerSignIn(
        email: 'sari@campus.ac.id',
        password: 'secret1',
      )['token']! as String;

      // Simulates writing to disk and starting the server again.
      final restored = CareBackendState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
        clock: () => now,
      );

      expect(
        restored.seekerSignIn(
          email: 'sari@campus.ac.id',
          password: 'secret1',
        )['success'],
        isTrue,
      );
      expect(
        restored.caregiverSignIn(
          email: 'ayu@campus.ac.id',
          password: 'secret1',
        )['success'],
        isTrue,
      );
      expect(restored.resumeSession(token), isNotNull);
      expect(
        (restored.seekerSnapshot(seekerId)['currentUser']
            as Map<String, Object?>)['avatarDataUrl'],
        'data:image/png;base64,AAAA',
      );
      expect(
        (restored.caregiverSnapshot(caregiverId)['currentCaregiver']
            as Map<String, Object?>)['avatarDataUrl'],
        'data:image/png;base64,BBBB',
      );
    });

    test('a restored session that already expired is dropped', () {
      var now = DateTime(2026, 1, 1);
      final state = CareBackendState(clock: () => now);
      final token = state.seekerSignUp(
        name: 'Sari',
        email: 'sari@campus.ac.id',
        password: 'secret1',
      )['token']! as String;

      now = now.add(const Duration(days: 31));
      final restored = CareBackendState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
        clock: () => now,
      );
      expect(restored.resumeSession(token), isNull);
    });

    test('the Residential ID number must be 16 digits', () {
      final state = CareBackendState();
      final id = (state.caregiverSignUp(
        name: 'Ayu',
        email: 'ayu@campus.ac.id',
        password: 'secret1',
        gender: Gender.female,
      )['user']! as Map<String, Object?>)['id']! as String;

      expect(
        () => state.submitVerification(
          id,
          residentialIdNumber: '123',
          documentLabel: 'Residential ID',
        ),
        throwsStateError,
      );
      state.submitVerification(
        id,
        residentialIdNumber: '3174012501990001',
        documentLabel: 'Residential ID',
      );
      expect(
        CaregiverAccount.fromJson(
          state.caregiverSnapshot(id)['currentCaregiver']! as Map<String, Object?>,
        ).verificationStatus,
        VerificationStatus.approved,
      );
    });
  });
}
