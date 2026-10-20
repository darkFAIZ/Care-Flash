import 'package:care_core/care_core.dart';
import 'package:care_flash/app.dart';
import 'package:care_flash/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps a number of short frames so stream events and navigation settle
/// without waiting on an endless animation such as a progress indicator.
Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _signUpOrSignIn(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
  await tester.tap(find.text('Sign in'));
  await _settle(tester);
}

/// Drives the request wizard up to and including a successful payment, leaving
/// the mock platform to auto-advance through accept, travel, arrival and client
/// code verification.
Future<void> _payForARequest(WidgetTester tester) async {
  await tester.tap(find.text('Start a request'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Take care'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next: boundaries'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Next: schedule'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Campus library'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('1 hour'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('1 hour'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next: preference'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Find a caregiver'));
  await _settle(tester);
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);

  await tester.tap(find.textContaining('Continue to payment'));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Pay IDR'));
  await _settle(tester);
}

void main() {
  testWidgets('care seeker can run a session, report and rate', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCarePlatform.create();
    addTearDown(platform.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareFlashApp(),
      ),
    );

    await _signUpOrSignIn(tester);
    await _payForARequest(tester);

    // Let the mock auto-advance through accept, travel, arrival and client-code
    // verification. Nothing else auto-advances after that.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 12));
    await _settle(tester);

    // The confirmed screen now offers safety-button verification.
    expect(find.text('Verify safety button'), findsOneWidget);

    await tester.tap(find.text('Verify safety button'));
    await tester.pumpAndSettle();
    expect(find.text('Simulate a correct scan'), findsOneWidget);

    await tester.tap(find.text('Simulate a correct scan'));
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.text('Session in progress'), findsOneWidget);

    // Report a problem. The session screen keeps a periodic timer alive in the
    // stack, so avoid pumpAndSettle from here on.
    await tester.tap(find.text('Report a problem'));
    await _settle(tester);
    expect(find.text('Send report'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'The caregiver arrived late.',
    );
    await tester.tap(find.text('Send report'));
    await _settle(tester);

    // Rate the caregiver and the app. Both start at 0, so the outlined stars are
    // the app's five; the caregiver's fifth star is the first group's last.
    expect(find.text('Rate your visit'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await _settle(tester);

    expect(find.textContaining('How can we help'), findsOneWidget);
  });
}
