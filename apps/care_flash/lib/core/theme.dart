import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

/// Care-Flash visual theme.
///
/// The real theme lives in the shared `care_ui` package so both apps stay in
/// step; this class keeps the app-facing name. (AGENTS.md §5)
abstract final class CareFlashTheme {
  /// The teal seed colour, re-exported for screens that need a raw colour.
  static Color get seed => AppBrand.careFlash;

  static ThemeData light({AppAccent? accent}) =>
      AppThemes.careFlash(accent: accent);

  static ThemeData dark({AppAccent? accent}) => AppThemes.careFlash(
        brightness: Brightness.dark,
        accent: accent,
      );
}
