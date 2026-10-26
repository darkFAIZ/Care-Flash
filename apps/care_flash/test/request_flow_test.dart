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

void main() {
  testWidgets('care seeker can request help end to end', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCarePlatform.create();
    addTearDown(platform.dispose);
    // Keep the mock from scheduling follow-up timers so the test can end clean.
    platform.setAutoAdvance(false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareFlashApp(),
      ),
    );

    // Splash sends a signed-out user to login.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Sign in.
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Sign in'));
    await _settle(tester);
    expect(find.textContaining('How can we help'), findsOneWidget);

    // Step 1: help type.
    await tester.tap(find.text('Start a request'));
    await tester.pumpAndSettle();
    expect(find.text('What do you need?'), findsOneWidget);
    await tester.tap(find.text('Take care'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: boundaries'));
    await tester.pumpAndSettle();

    // Step 2: boundaries (standard tasks are pre-selected).
    expect(find.text('Set your boundaries'), findsOneWidget);
    await tester.tap(find.text('Next: schedule'));
    await tester.pumpAndSettle();

    // Step 3: location, date, time, duration.
    await tester.tap(find.text('Community library'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next: preference'));
    await tester.pumpAndSettle();

    // Step 4: preference and preliminary estimate (1 hour = IDR 61,500).
    expect(find.text('Preliminary estimate'), findsOneWidget);
    expect(find.text('IDR 61,500'), findsWidgets);
    await tester.tap(find.text('Find a caregiver'));
    await _settle(tester);

    // Matching.
    expect(find.text('Looking for a nearby caregiver…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    // Matched caregiver with the itemized price.
    expect(find.text('Your caregiver'), findsWidgets);
    await tester.tap(find.textContaining('Continue to payment'));
    await tester.pumpAndSettle();
    expect(find.text('Amount due'), findsOneWidget);

    // Pay.
    await tester.tap(find.textContaining('Pay IDR'));
    await _settle(tester);
    expect(find.text('Your client code'), findsNothing);
    expect(find.text('Confirm caregiver identity'), findsNothing);
    expect(find.textContaining('Reference'), findsOneWidget);
  });
}
