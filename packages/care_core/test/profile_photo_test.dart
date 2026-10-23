import 'package:care_core/care_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tiny stand-in for a picked photo; the avatar widget decodes real bytes,
/// but these tests only check the value is stored and restored.
const String _photo = 'data:image/png;base64,AAAA';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a care seeker photo is saved, restored and can be removed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCarePlatform.create();
    await platform.signIn(email: 'ayu@example.com', password: 'secret1');

    await platform.updateAvatar(avatarDataUrl: _photo);
    expect(platform.currentUser?.avatarDataUrl, _photo);
    platform.dispose();

    final restored = await MockCarePlatform.create();
    expect(restored.currentUser?.avatarDataUrl, _photo);

    await restored.updateAvatar(avatarDataUrl: null);
    expect(restored.currentUser?.avatarDataUrl, isNull);
    restored.dispose();
  });

  test('a caregiver photo is saved, restored and can be removed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create();
    await platform.signIn(email: 'budi@example.com', password: 'secret1');

    await platform.updateAvatar(avatarDataUrl: _photo);
    expect(platform.currentCaregiver?.avatarDataUrl, _photo);
    platform.dispose();

    final restored = await MockCaregiverPlatform.create();
    expect(restored.currentCaregiver?.avatarDataUrl, _photo);

    await restored.updateAvatar(avatarDataUrl: null);
    expect(restored.currentCaregiver?.avatarDataUrl, isNull);
    restored.dispose();
  });
}
