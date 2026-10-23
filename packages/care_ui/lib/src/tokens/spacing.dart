import 'package:flutter/widgets.dart';

/// Spacing scale shared by both apps.
///
/// Everything on screen lines up to these values so the two apps feel like one
/// product. (AGENTS.md §5)
abstract final class AppSpacing {
  /// Hairline gap inside a component.
  static const double xs = 4;

  /// Gap between an icon and its label.
  static const double sm = 8;

  /// Gap between two related rows.
  static const double md = 12;

  /// Gap between stacked blocks.
  static const double lg = 16;

  /// Gap between sections.
  static const double xl = 24;

  /// Big break before a header or a footer action.
  static const double xxl = 32;

  /// Horizontal gutter of a page.
  static const double pageGutter = 20;

  /// Padding used around the body of a standard page.
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: pageGutter,
    vertical: lg,
  );
}
