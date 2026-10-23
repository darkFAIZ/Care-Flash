import 'package:flutter/material.dart';

/// Semantic colours that exist in both apps but are not part of the Material
/// seed palette: success, warning and danger.
///
/// Read them with `AppSemanticColors.of(context)`. They drive status chips,
/// the red Report action and the green success confirmations, so Report always
/// looks clearly different from End Early. (AGENTS.md §5)
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xFF12B76A),
    successContainer: Color(0xFFD1FADF),
    onSuccessContainer: Color(0xFF05603A),
    warning: Color(0xFFF59E0B),
    warningContainer: Color(0xFFFEF0C7),
    onWarningContainer: Color(0xFF93370D),
    danger: Color(0xFFD92D20),
    dangerContainer: Color(0xFFFEE4E2),
    onDangerContainer: Color(0xFF912018),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF32D583),
    successContainer: Color(0xFF083D24),
    onSuccessContainer: Color(0xFFA9F0C7),
    warning: Color(0xFFFEC84B),
    warningContainer: Color(0xFF462C05),
    onWarningContainer: Color(0xFFFEDF89),
    danger: Color(0xFFF97066),
    dangerContainer: Color(0xFF4A1512),
    onDangerContainer: Color(0xFFFECACA),
  );

  /// Foreground for a solid button painted in [danger] or [success].
  static const Color onSolid = Color(0xFFFFFFFF);

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  static AppSemanticColors of(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>();
    return colors ?? light;
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? onDangerContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ??
          onSuccessContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t) ??
          onWarningContainer,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      dangerContainer:
          Color.lerp(dangerContainer, other.dangerContainer, t) ??
          dangerContainer,
      onDangerContainer:
          Color.lerp(onDangerContainer, other.onDangerContainer, t) ??
          onDangerContainer,
    );
  }
}
