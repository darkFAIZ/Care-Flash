import 'package:flutter/widgets.dart';

/// Shared care-record palette used across both apps.
abstract final class AppBrand {
  static const Color careFlash = Color(0xFF174D45);
  static const Color careMerchant = Color(0xFF174D45);
  static const Color ink = Color(0xFF20332E);
  static const Color paper = Color(0xFFF6F2E8);
  static const Color paperRaised = Color(0xFFFFFDF7);
  static const Color paperSoft = Color(0xFFFBF8F1);
  static const Color recordRule = Color(0xFFD8D2C5);
  static const Color stampGold = Color(0xFFE7B24C);
  static const Color stampTerracotta = Color(0xFFD7735B);

  /// Neutral colours used for skeletons and pressed states.
  static const Color skeletonLight = Color(0xFFECEFF3);
  static const Color skeletonDark = Color(0xFF262B33);
}

/// Optional accent colours for the appearance settings. (Phase 5)
///
/// Each accent replaces the app's brand seed, so the whole Material 3 scheme
/// is derived from the chosen colour. Screens pick the default (null) to keep
/// the brand colour of their own app.
enum AppAccent {
  ocean(Color(0xFF2563EB), 'Ocean'),
  sunset(Color(0xFFEA580C), 'Sunset'),
  forest(Color(0xFF059669), 'Forest'),
  plum(Color(0xFF9333EA), 'Plum');

  const AppAccent(this.seed, this.label);

  /// The seed colour the colour scheme is derived from.
  final Color seed;

  /// The user-facing name shown in the appearance sheet.
  final String label;
}
