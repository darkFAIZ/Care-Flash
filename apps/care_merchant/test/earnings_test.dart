import 'package:care_core/care_core.dart';
import 'package:care_merchant/app.dart';
import 'package:care_merchant/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the earnings tab shows the balance and a completed session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final platform = await MockCaregiverPlatform.create(
      verificationReviewDelay: const Duration(milliseconds: 5),
      requestArrivalDelay: const Duration(milliseconds: 20),
      buttonScanDelay: const Duration(milliseconds: 20),
    );

    // Drive a full session to completion so earnings exist. (FR-P-21)
    // runAsync lets the mock's real timers fire; testWidgets otherwise runs in
    // a fake clock where Future.delayed never completes.
    await tester.runAsync(() async {
      await platform.signIn(email: 'ayu@example.com', password: 'secret1');
      // Wait for the simulated request to arrive before accepting it.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await platform.acceptRequest();
      await platform.startTrip();
      await platform.markArrived();
      await platform.verifyClientCode(platform.debugClientCode!);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await platform.completeSession();
    });

    final finished = (await platform.watchBookingHistory().first).first;
    final expected = finished.caregiverPayout!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformProvider.overrideWithValue(platform)],
        child: const CareMerchantApp(),
      ),
    );

    // Splash -> home. Bounded pumps keep clear of the loading spinner's
    // endless animation. (Screens with a CircularProgressIndicator never
    // settle, so pumpAndSettle cannot be used here.)
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Switch to the Earnings tab. (FR-CM-21)
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text(formatIdr(expected)), findsWidgets);
    expect(find.text(EarningKind.session.label), findsOneWidget);
    expect(find.text('Request withdrawal'), findsOneWidget);

    platform.dispose();
  });
}
