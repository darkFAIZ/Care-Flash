import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

/// Care-Merchant visual theme.
///
/// The real theme lives in the shared `care_ui` package so both apps stay in
/// step; this class keeps the app-facing name. The indigo seed makes the
/// caregiver app read as a sibling of Care-Flash (teal) without looking
/// identical. (AGENTS.md §5)
abstract final class CareMerchantTheme {
  /// The indigo seed colour, re-exported for screens that need a raw colour.
  static Color get seed => AppBrand.careMerchant;

  static ThemeData light({AppAccent? accent}) =>
      AppThemes.careMerchant(accent: accent);

  static ThemeData dark({AppAccent? accent}) => AppThemes.careMerchant(
        brightness: Brightness.dark,
        accent: accent,
      );
}
