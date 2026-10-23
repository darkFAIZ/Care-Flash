import 'package:flutter/widgets.dart';

/// Brand seeds, one per app, so the two apps read as siblings.
///
/// Care-Flash is teal (calm, care), Care-Merchant is indigo (steady, on duty).
/// (AGENTS.md §5)
abstract final class AppBrand {
  static const Color careFlash = Color(0xFF0F8B8D);
  static const Color careMerchant = Color(0xFF4F46E5);

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
