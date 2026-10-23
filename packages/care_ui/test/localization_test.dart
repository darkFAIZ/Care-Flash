import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English keeps the source copy', () async {
    final strings = await AppLocalizations.load(const Locale('en'));
    expect(strings.languageCode, 'en');
    expect(strings.t('Sign in'), 'Sign in');
  });

  test('Bahasa Indonesia translates normal copy and templates', () async {
    final strings = await AppLocalizations.load(const Locale('id'));
    expect(strings.languageCode, 'id');
    expect(strings.t('Sign in'), 'Masuk');
    expect(strings.t('Your choice is saved on this device.'), isNotEmpty);
    expect(strings.t('Time remaining: 04:30'), 'Sisa waktu: 04:30');
    expect(strings.t('Photo 2'), 'Foto 2');
    expect(strings.t('Completed · 12 Oct 2026'), contains('Selesai'));
    expect(strings.t('Completed · 12 Oct 2026'), contains('Okt'));
    expect(strings.t('Completed · 12 May 2026'), contains('Mei'));
    expect(strings.t('May I help you?'), 'May I help you?');
    expect(strings.t('Hi, May'), 'Hai, May');
    expect(strings.t('Ongoing: Completed'), 'Berlangsung: Selesai');
    expect(
      strings.t('How was Maya?'),
      'Bagaimana pengalaman Anda dengan Maya?',
    );
    expect(
      strings.t(
        'Withdrawal of IDR 50,000 requested via GoPay. '
        'It arrives in about 2 days.',
      ),
      'Penarikan IDR 50,000 diminta melalui GoPay. '
      'Dana tiba dalam sekitar 2 hari.',
    );
  });

  testWidgets('AppText renders Indonesian when the locale is id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: AppText('Sign in')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });
}
