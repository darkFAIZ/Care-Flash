import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale shared by both apps: 28b / 20sb / 15r / 13m.
///
/// Every style goes through `google_fonts` so the Plus Jakarta Sans files
/// bundled in `assets/google_fonts/` are registered at startup and the demo
/// needs no network. (AGENTS.md §5)
abstract final class AppTypography {
  /// Family name used by the bundled files.
  static const String family = 'PlusJakartaSans';

  /// Large screen or feature title, 28 bold.
  static TextStyle get display28 => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.4,
  );

  /// Section title, 20 semibold.
  static TextStyle get title20 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// Default reading size, 15 regular.
  static TextStyle get body15 => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Small supporting text and field labels, 13 medium.
  static TextStyle get label13 => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  /// Applies the family and the scale above to a Material text theme.
  static TextTheme textTheme(TextTheme base) {
    return TextTheme(
      displayLarge: _style(base.displayLarge, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -0.6),
      displayMedium: _style(base.displayMedium, fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      displaySmall: _style(base.displaySmall, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineLarge: _style(base.headlineLarge, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineMedium: _style(base.headlineMedium, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: _style(base.headlineSmall, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleLarge: _style(base.titleLarge, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleMedium: _style(base.titleMedium, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleSmall: _style(base.titleSmall, fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: _style(base.bodyLarge, fontSize: 15),
      bodyMedium: _style(base.bodyMedium, fontSize: 15),
      bodySmall: _style(base.bodySmall, fontSize: 13),
      labelLarge: _style(base.labelLarge, fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: _style(base.labelMedium, fontSize: 13, fontWeight: FontWeight.w500),
      labelSmall: _style(base.labelSmall, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static TextStyle _style(
    TextStyle? base, {
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      textStyle: base,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}
