import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';

/// Design tokens from the Warm Empathy Healthcare Stitch design system.
abstract final class WarmEmpathyColors {
  // Brand & Accents
  static const Color primary = Color(0xFF00685F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);

  static const Color secondary = Color(0xFF006A63);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF99EFE5);
  static const Color onSecondaryContainer = Color(0xFF006F67);
  static const Color secondaryFixed = Color(0xFF9CF2E8);
  static const Color secondaryFixedDim = Color(0xFF80D5CB);
  static const Color onSecondaryFixed = Color(0xFF00201D);
  static const Color onSecondaryFixedVariant = Color(0xFF00504A);

  static const Color tertiary = Color(0xFF825100);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFA36700);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color amber = Color(0xFFF59E0B);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // Text & Outline
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Errors & Alerts
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

/// Care-Flash visual theme matching the Warm Empathy Healthcare design system.
abstract final class CareFlashTheme {
  /// The primary teal seed colour.
  static Color get seed => WarmEmpathyColors.primary;

  static ThemeData light({AppAccent? accent}) {
    final seedColor = accent?.seed ?? WarmEmpathyColors.primary;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: seedColor,
      onPrimary: WarmEmpathyColors.onPrimary,
      primaryContainer: WarmEmpathyColors.primaryContainer,
      onPrimaryContainer: WarmEmpathyColors.onPrimaryContainer,
      secondary: WarmEmpathyColors.secondary,
      onSecondary: WarmEmpathyColors.onSecondary,
      secondaryContainer: WarmEmpathyColors.secondaryContainer,
      onSecondaryContainer: WarmEmpathyColors.onSecondaryContainer,
      tertiary: WarmEmpathyColors.tertiary,
      onTertiary: WarmEmpathyColors.onTertiary,
      tertiaryContainer: WarmEmpathyColors.tertiaryContainer,
      onTertiaryContainer: WarmEmpathyColors.onTertiaryContainer,
      error: WarmEmpathyColors.error,
      onError: WarmEmpathyColors.onError,
      errorContainer: WarmEmpathyColors.errorContainer,
      onErrorContainer: WarmEmpathyColors.onErrorContainer,
      surface: WarmEmpathyColors.surface,
      onSurface: WarmEmpathyColors.onSurface,
      onSurfaceVariant: WarmEmpathyColors.onSurfaceVariant,
      outline: WarmEmpathyColors.outline,
      outlineVariant: WarmEmpathyColors.outlineVariant,
      surfaceContainerLowest: WarmEmpathyColors.surfaceContainerLowest,
      surfaceContainerLow: WarmEmpathyColors.surfaceContainerLow,
      surfaceContainer: WarmEmpathyColors.surfaceContainer,
      surfaceContainerHigh: WarmEmpathyColors.surfaceContainerHigh,
      surfaceContainerHighest: WarmEmpathyColors.surfaceContainerHighest,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
    final textTheme = AppTypography.textTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: WarmEmpathyColors.surface,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.light],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: WarmEmpathyColors.surface,
        foregroundColor: WarmEmpathyColors.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: WarmEmpathyColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: WarmEmpathyColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: WarmEmpathyColors.cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: seedColor,
          foregroundColor: WarmEmpathyColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.titleSmall,
          elevation: 1,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: seedColor,
          side: const BorderSide(color: WarmEmpathyColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: seedColor,
          textStyle: textTheme.titleSmall,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WarmEmpathyColors.surfaceContainerLowest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: WarmEmpathyColors.outline,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: WarmEmpathyColors.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: seedColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WarmEmpathyColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WarmEmpathyColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WarmEmpathyColors.surface,
        indicatorColor: WarmEmpathyColors.secondaryContainer.withValues(alpha: 0.6),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: seedColor,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: WarmEmpathyColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: seedColor, size: 24);
          }
          return const IconThemeData(
            color: WarmEmpathyColors.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
    );
  }

  static ThemeData dark({AppAccent? accent}) =>
      AppThemes.careFlash(brightness: Brightness.dark, accent: accent);
}
