import 'dart:io';

import 'package:care_ui/care_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The demo must run with no network, so the Plus Jakarta Sans files have to
/// be really present, really be fonts, and really be picked up by
/// `google_fonts`. (AGENTS.md §5)
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final Directory fontsDir = Directory('assets/google_fonts');
  const Map<String, String> expected = <String, String>{
    'PlusJakartaSans-Regular.ttf': '400',
    'PlusJakartaSans-Medium.ttf': '500',
    'PlusJakartaSans-SemiBold.ttf': '600',
    'PlusJakartaSans-Bold.ttf': '700',
  };

  test('bundles one TrueType file per weight plus the licence', () {
    expect(fontsDir.existsSync(), isTrue, reason: 'assets/google_fonts is missing');

    for (final MapEntry<String, String> entry in expected.entries) {
      final File file = File('${fontsDir.path}/${entry.key}');
      expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
      final List<int> bytes = file.readAsBytesSync();
      expect(
        bytes.sublist(0, 4),
        <int>[0x00, 0x01, 0x00, 0x00],
        reason: '${entry.key} is not a TrueType font',
      );
      expect(bytes.length, greaterThan(10000), reason: '${entry.key} looks truncated');
    }

    expect(
      File('${fontsDir.path}/OFL.txt').readAsStringSync(),
      contains('SIL OPEN FONT LICENSE'),
    );
  });

  testWidgets('every weight loads from the bundled assets', (tester) async {
    AppThemes.careFlash();
    AppThemes.careMerchant();
    AppTypography.body15;

    // Throws if a weight cannot be found in the assets and would have been
    // fetched from the network instead.
    await GoogleFonts.pendingFonts();
    await tester.pump();
  });

  testWidgets('weight is picked up from the file name prefix', (tester) async {
    AppTypography.title20;
    AppTypography.label13;
    await GoogleFonts.pendingFonts();
    expect(AppTypography.family, 'PlusJakartaSans');
  });
}
