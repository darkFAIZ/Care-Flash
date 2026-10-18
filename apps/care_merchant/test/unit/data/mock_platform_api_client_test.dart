import 'package:flutter_test/flutter_test.dart';
import 'package:care_merchant/data/mock/mock_platform_api_client.dart';
import 'package:care_merchant/data/mock/mock_data.dart';
import 'package:care_merchant/features/auth_onboarding/domain/entities/caregiver_user.dart';

void main() {
  group('MockPlatformApiClient', () {
    late MockPlatformApiClient client;

    setUp(() {
      client = MockPlatformApiClient(latency: Duration.zero);
    });

    tearDown(() {
      client.dispose();
    });

    test('login returns initial caregiver profile', () async {
      final profile = await client.login('test@test.com', 'password');
      expect(profile.id, MockData.verifiedCaregiver.id);
      expect(profile.safetyBadgeEarned, isTrue);
    });

    test('register updates profile to pending status without badge', () async {
      final profile = await client.register(
        email: 'new@univ.ac.id',
        password: 'pass',
        fullName: 'New Student',
        university: 'UI',
        gender: CaregiverGender.female,
      );
      expect(profile.fullName, 'New Student');
      expect(profile.verificationStatus, VerificationStatus.pending);
      expect(profile.safetyBadgeEarned, isFalse);
    });

    test('completeSafetyModule awards badge and approves profile', () async {
      final updated = await client.completeSafetyModule();
      expect(updated.safetyBadgeEarned, isTrue);
      expect(updated.verificationStatus, VerificationStatus.approved);
    });

    test('verifyClientCode accepts 123456 and rejects invalid PINs', () async {
      expect(await client.verifyClientCode('BK-1', '123456'), isTrue);
      expect(await client.verifyClientCode('BK-1', '000000'), isFalse);
    });

    test('requestPayout deducts from available balance', () async {
      final initial = await client.getEarningsLedger();
      final initialBalance = initial.availableBalanceIdr;

      final success = await client.requestPayout(50000, 'BCA', '1234567890');
      expect(success, isTrue);

      final updated = await client.getEarningsLedger();
      expect(updated.availableBalanceIdr, initialBalance - 50000);
      expect(updated.transactions.first.status, 'withdrawn');
    });
  });
}
