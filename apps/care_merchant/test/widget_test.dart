import 'package:care_core/care_core.dart';
import 'package:care_merchant/app.dart';
import 'package:care_merchant/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the splash page then the login page when signed out',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareMerchantApp(),
      ),
    );

    expect(find.text('Care-Merchant'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, caregiver'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    platform.dispose();
  });
}
