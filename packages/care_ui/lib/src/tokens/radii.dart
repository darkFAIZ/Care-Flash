import 'package:flutter/widgets.dart';

/// Corner radius scale shared by both apps.
abstract final class AppRadii {
  /// Fields, chips and small tiles.
  static const double sm = 12;

  /// Cards and buttons.
  static const double md = 16;

  /// Bottom sheets and dialogs.
  static const double lg = 24;

  static const BorderRadius field = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(lg));
}
