import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Building a theme registers fonts, which needs the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tokens', () {
    test('spacing follows the 4 8 12 16 24 32 scale', () {
      expect(
        <double>[
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ],
        <double>[4, 8, 12, 16, 24, 32],
      );
    });

    test('radii follow the 12 16 24 scale', () {
      expect(
        <double>[AppRadii.sm, AppRadii.md, AppRadii.lg],
        <double>[12, 16, 24],
      );
      expect(AppRadii.card, const BorderRadius.all(Radius.circular(16)));
      expect(AppRadii.sheet, const BorderRadius.all(Radius.circular(24)));
    });

    test('the two apps share the care-record brand colour', () {
      expect(AppBrand.careFlash, AppBrand.careMerchant);
      expect(AppBrand.careFlash, const Color(0xFF174D45));
    });

    test('type scale is 28 bold, 20 semibold, 15 regular, 13 medium', () {
      expect(AppTypography.display28.fontSize, 28);
      expect(AppTypography.display28.fontWeight, FontWeight.w700);
      expect(AppTypography.title20.fontSize, 20);
      expect(AppTypography.title20.fontWeight, FontWeight.w600);
      expect(AppTypography.body15.fontSize, 15);
      expect(AppTypography.body15.fontWeight, FontWeight.w400);
      expect(AppTypography.label13.fontSize, 13);
      expect(AppTypography.label13.fontWeight, FontWeight.w500);
    });
  });

  group('AppThemes', () {
    test('builds light and dark material 3 themes per brand', () {
      final ThemeData flash = AppThemes.careFlash();
      final ThemeData flashDark = AppThemes.careFlash(
        brightness: Brightness.dark,
      );
      final ThemeData merchant = AppThemes.careMerchant();

      expect(flash.brightness, Brightness.light);
      expect(flashDark.brightness, Brightness.dark);
      expect(flash.useMaterial3, isTrue);
      expect(flash.colorScheme.primary, merchant.colorScheme.primary);
      expect(flash.colorScheme.surface, AppBrand.paper);
      expect(flash.colorScheme.onSurface, AppBrand.ink);
      expect(flash.colorScheme.tertiary, AppBrand.stampTerracotta);
      expect(flash.textTheme.titleLarge?.fontSize, 28);
      expect(flash.textTheme.titleMedium?.fontSize, 20);
      expect(flash.textTheme.bodyMedium?.fontSize, 15);
      expect(flash.textTheme.labelMedium?.fontSize, 13);
    });

    test('primary actions are at least 52 tall and fields at least 48', () {
      final ThemeData theme = AppThemes.careFlash();
      final Size? filled = theme.filledButtonTheme.style?.minimumSize?.resolve(
        const <WidgetState>{},
      );
      final Size? outlined = theme.outlinedButtonTheme.style?.minimumSize
          ?.resolve(const <WidgetState>{});
      final Size? text = theme.textButtonTheme.style?.minimumSize?.resolve(
        const <WidgetState>{},
      );

      expect(filled?.height, greaterThanOrEqualTo(52));
      expect(outlined?.height, greaterThanOrEqualTo(52));
      expect(text?.height, greaterThanOrEqualTo(48));
    });

    test(
      'carries the success warning danger extension in both brightnesses',
      () {
        final AppSemanticColors light = AppThemes.careFlash()
            .extension<AppSemanticColors>()!;
        final AppSemanticColors dark = AppThemes.careFlash(
          brightness: Brightness.dark,
        ).extension<AppSemanticColors>()!;

        expect(light.danger, isNot(light.success));
        expect(light.danger.toARGB32(), 0xFFD92D20);
        expect(light.success.toARGB32(), 0xFF12B76A);
        expect(light.warning.toARGB32(), 0xFFF59E0B);
        expect(dark.danger, isNot(dark.dangerContainer));

        final AppSemanticColors mixed = light.lerp(dark, 0.5);
        expect(mixed.danger, isNot(light.danger));
      },
    );

    test('report danger reads as red and success as green', () {
      const AppSemanticColors colors = AppSemanticColors.light;
      expect(colors.danger.r, greaterThan(colors.danger.b));
      expect(colors.success.g, greaterThan(colors.success.r));
    });

    test('an accent replaces the brand seed in both apps (Phase 5)', () {
      final ThemeData flashAccent = AppThemes.careFlash(
        accent: AppAccent.ocean,
      );
      final ThemeData merchantAccent = AppThemes.careMerchant(
        accent: AppAccent.ocean,
      );

      // The same accent derives the same scheme in either app.
      expect(
        flashAccent.colorScheme.primary,
        merchantAccent.colorScheme.primary,
      );
      expect(
        flashAccent.colorScheme.primary,
        isNot(AppThemes.careFlash().colorScheme.primary),
      );
      // Dark mode still works with an accent.
      expect(
        AppThemes.careFlash(
          brightness: Brightness.dark,
          accent: AppAccent.plum,
        ).brightness,
        Brightness.dark,
      );
    });
  });
}
