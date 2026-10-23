import 'package:care_core/care_core.dart';
import 'package:care_merchant/app.dart';
import 'package:care_merchant/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'a new caregiver signs up, verifies their ID, completes the safety '
      'module and reaches the request screen', (tester) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 200),
      requestArrivalDelay: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareMerchantApp(),
      ),
    );

    // Splash, then login, then create account.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Citra Dewi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'citra@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // A new account has not been verified, so onboarding comes next.
    expect(find.text('Verify your account'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'KTP number'),
      '3174012501990001',
    );
    await tester.tap(find.text('Attach KTP photo'));
    await tester.pump();
    await tester.tap(find.text('Submit for review'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    // The review is pending, then approves on its own.
    expect(find.text(VerificationStatus.pending.label), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text(VerificationStatus.approved.label), findsOneWidget);

    // Verified, but still needs the safety badge.
    await tester.tap(find.text('Continue to the safety module'));
    await tester.pumpAndSettle();
    expect(find.text('Four things every caregiver should know.'),
        findsOneWidget);

    await tester.tap(find.text('Complete the module'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Now eligible: the request screen shows the caregiver as available.
    expect(find.text('Available for requests'), findsOneWidget);
    expect(platform.currentCaregiver!.safetyModuleCompleted, isTrue);
    expect(platform.currentCaregiver!.canReceiveRequests, isTrue);

    platform.dispose();
  });
}
