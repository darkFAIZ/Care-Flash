import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    // The whole point of bundling Plus Jakarta Sans is that no screen ever
    // reaches the network for a font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpApp(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.careFlash(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('AppButton', () {
    testWidgets('fires its callback and shows a spinner while loading', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        AppButton(
          label: 'Pay now',
          onPressed: () => tapped++,
          icon: Icons.lock_rounded,
        ),
      );
      expect(find.text('Pay now'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      await tester.tap(find.text('Pay now'));
      expect(tapped, 1);

      await pumpApp(tester, const AppButton(label: 'Pay now', loading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await pumpApp(tester, const AppButton(label: 'Pay now'));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('danger variant is painted with the semantic danger colour', (tester) async {
      await pumpApp(
        tester,
        const AppButton(label: 'Report', variant: AppButtonVariant.danger),
      );
      final FilledButton button = tester.widget<FilledButton>(find.byType(FilledButton));
      final Color? background =
          button.style?.backgroundColor?.resolve(const <WidgetState>{});
      expect(background, AppSemanticColors.light.danger);
    });

    testWidgets('keeps a 52 pixel tap target', (tester) async {
      await pumpApp(tester, AppButton(label: 'Continue', onPressed: () {}));
      final Size size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(52));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('AppCard', () {
    testWidgets('shows content and fires onTap', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        AppCard(
          onTap: () => tapped++,
          child: const Text('Caregiver arriving'),
        ),
      );
      expect(find.text('Caregiver arriving'), findsOneWidget);
      await tester.tap(find.text('Caregiver arriving'));
      expect(tapped, 1);
    });
  });

  group('AppTextField', () {
    testWidgets('shows its label and reveals a password', (tester) async {
      await pumpApp(
        tester,
        const AppTextField(label: 'Password', obscureText: true, required: true),
      );
      // The label is rich text ("Password" plus the required asterisk).
      expect(find.textContaining('Password'), findsOneWidget);

      final EditableText editable = tester.widget(find.byType(EditableText));
      expect(editable.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      final EditableText revealed = tester.widget(find.byType(EditableText));
      expect(revealed.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });
  });

  group('StatusChip', () {
    testWidgets('uses the semantic colour for its tint', (tester) async {
      await pumpApp(
        tester,
        const StatusChip(label: 'Paid', tint: AppStatusTint.success, icon: Icons.check_rounded),
      );
      expect(find.text('Paid'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(StatusChip), matching: find.byType(Container)).first,
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppSemanticColors.light.successContainer);
    });
  });

  group('PriceBreakdownCard', () {
    testWidgets('itemises the lines, the total and the note', (tester) async {
      await pumpApp(
        tester,
        const PriceBreakdownCard(
          title: 'Price estimate',
          lines: <AppPriceLine>[
            AppPriceLine(label: 'Caregiver service', amount: 'IDR 50,000'),
            AppPriceLine(label: 'Platform fee (5%)', amount: 'IDR 2,500'),
            AppPriceLine(label: 'Grab fare (paid by you)', amount: 'IDR 9,000'),
          ],
          total: AppPriceLine(label: 'Total', amount: 'IDR 61,500', emphasised: true),
          note: 'Paid up front.',
        ),
      );

      expect(find.text('Price estimate'), findsOneWidget);
      expect(find.text('Caregiver service'), findsOneWidget);
      expect(find.text('IDR 61,500'), findsOneWidget);
      expect(find.text('Paid up front.'), findsOneWidget);
    });
  });

  group('StepIndicator', () {
    testWidgets('labels every step and numbers the current one', (tester) async {
      await pumpApp(
        tester,
        const StepIndicator(steps: <String>['Need', 'Place', 'Filter'], current: 1),
      );
      expect(find.text('Need'), findsOneWidget);
      expect(find.text('Place'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
      // Step 0 is done, step 1 is current, step 2 is upcoming.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('shows a title, a message and its action', (tester) async {
      var tapped = 0;
      await pumpApp(
        tester,
        EmptyState(
          title: 'No requests yet',
          message: 'Accepted requests will show up here.',
          actionLabel: 'Refresh',
          onAction: () => tapped++,
        ),
      );
      expect(find.text('No requests yet'), findsOneWidget);
      expect(find.text('Accepted requests will show up here.'), findsOneWidget);
      await tester.tap(find.text('Refresh'));
      expect(tapped, 1);
    });
  });

  group('SkeletonBox', () {
    testWidgets('renders a static box when animation is off', (tester) async {
      await pumpApp(
        tester,
        const SkeletonBox(width: 120, height: 20, animated: false),
      );
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Animate), findsNothing);
    });
  });

  group('UserAvatar', () {
    test('builds deterministic initials', () {
      expect(UserAvatar.initialsOf('Ayu Lestari'), 'AL');
      expect(UserAvatar.initialsOf('Budi'), 'BU');
      expect(UserAvatar.initialsOf('  '), '?');
      expect(UserAvatar.initialsOf('Ayu Lestari'), UserAvatar.initialsOf('Ayu Lestari'));
    });

    testWidgets('renders the initials and can be a hero', (tester) async {
      await pumpApp(tester, const UserAvatar(name: 'Ayu Lestari', heroTag: 'ayu'));
      expect(find.text('AL'), findsOneWidget);
      expect(find.byType(Hero), findsOneWidget);
    });
  });

  group('BookingTimeline', () {
    testWidgets('shows all six stages and highlights the current one', (tester) async {
      await pumpApp(tester, const BookingTimeline(current: BookingStage.onTheWay));

      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('Code verified'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
    });
  });
}
