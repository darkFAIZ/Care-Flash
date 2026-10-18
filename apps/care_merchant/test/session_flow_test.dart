import 'package:care_core/care_core.dart';
import 'package:care_merchant/app.dart';
import 'package:care_merchant/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'a caregiver travels, verifies the client code, hands over the button '
      'and completes the session', (tester) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 5),
      requestArrivalDelay: const Duration(milliseconds: 20),
      buttonScanDelay: const Duration(milliseconds: 20),
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ayu@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // A request arrives; accept it.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    await tester.tap(find.text('View and respond'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Accept'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Open the accepted booking from the home tab.
    expect(find.text(BookingStatus.confirmed.label), findsOneWidget);
    await tester.tap(find.text('Start your trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The trip advances to arrived.
    await tester.tap(find.text("I'm on my way"));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.text("I've arrived"));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Verify the client code'), findsOneWidget);

    // Verify the client code. A wrong code would cancel the booking, so this
    // uses the code the mock care seeker presents. (FR-CM-13)
    await tester.tap(find.text('Verify the client code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), platform.debugClientCode!);
    await tester.tap(find.text('Verify code'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // The handover screen waits, the mock confirms the scan, and the listener
    // opens the session. (FR-CM-15, FR-CM-16)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Session in progress'), findsOneWidget);

    // Complete the session. (FR-CM-18)
    await tester.tap(find.text('Mark work complete'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Work marked complete'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Back home'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(await platform.watchActiveBooking().first, isNull);
    expect((await platform.watchBookingHistory().first).first.status,
        BookingStatus.completed);

    platform.dispose();
  });

  testWidgets('a wrong client code cancels the booking', (tester) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 5),
      requestArrivalDelay: const Duration(milliseconds: 20),
      buttonScanDelay: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareMerchantApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ayu@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    await tester.tap(find.text('View and respond'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Accept'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    await tester.tap(find.text('Start your trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text("I'm on my way"));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.text("I've arrived"));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.tap(find.text('Verify the client code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Verify code'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // The wrong code cancels the booking and support is notified. (FR-CM-14)
    expect(find.text('Verification failed'), findsOneWidget);
    expect(await platform.watchActiveBooking().first, isNull);
    expect((await platform.watchBookingHistory().first).first.status,
        BookingStatus.cancelled);

    platform.dispose();
  });
}
