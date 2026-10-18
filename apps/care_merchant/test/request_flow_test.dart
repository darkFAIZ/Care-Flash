import 'package:care_core/care_core.dart';
import 'package:care_merchant/app.dart';
import 'package:care_merchant/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a caregiver signs in, receives a request and accepts it',
      (tester) async {
    // A tall viewport so the lazy ListView builds every item, including the
    // privacy note at the bottom of the request detail.
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 5),
      requestArrivalDelay: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareMerchantApp(),
      ),
    );

    // Splash, then the login page.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, caregiver'), findsOneWidget);

    // Sign in. A returning caregiver is verified and badged.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ayu@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.text('Sign in'));
    // Bounded pumps: the sign-in button shows a spinner, so no pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // The mock delivers a request shortly after the caregiver is eligible.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.text('New request'), findsOneWidget);

    // Open the request detail.
    await tester.tap(find.text('View and respond'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.textContaining('stay hidden until you accept'), findsOneWidget);
    // The care seeker's location must not be revealed before acceptance.
    // (FR-CM-8, UI-CM-2)
    for (final preset in VisitLocation.mockPresets) {
      expect(find.text(preset.label), findsNothing);
      expect(find.textContaining(preset.address), findsNothing);
    }

    // Accept the request.
    await tester.tap(find.text('Accept'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text(BookingStatus.confirmed.label), findsOneWidget);
    expect(await platform.watchIncomingRequest().first, isNull);

    platform.dispose();
  });
}
