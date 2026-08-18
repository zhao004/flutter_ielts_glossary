import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/theme/app_theme.dart';

const _lightPrimaryDarkBlend = 0.3;
const _darkPrimaryDarkBlend = 0.08;
const _darkHeroSurfaceBlend = 0.28;

void main() {
  test('flex_color_scheme 全部配色都能生成主色与深浅 Token', () {
    for (final accent in FlexColor.schemes.keys) {
      final light = AppTheme.light(accent: accent);
      final dark = AppTheme.dark(accent: accent);
      final lightHero = AppTheme.heroColorsOf(light);
      final darkHero = AppTheme.heroColorsOf(dark);

      // 设置页与配色选择页使用的样本色必须与主题主色一致。
      expect(light.colorScheme.primary, AppTheme.swatchFor(accent));
      expect(
        AppTheme.tokensOf(light).primarySoft,
        light.colorScheme.primaryContainer,
      );
      expect(
        AppTheme.tokensOf(light).primaryDark,
        Color.lerp(
          light.colorScheme.primary,
          Colors.black,
          _lightPrimaryDarkBlend,
        ),
      );
      expect(
        AppTheme.tokensOf(dark).primaryDark,
        Color.lerp(
          dark.colorScheme.primary,
          Colors.black,
          _darkPrimaryDarkBlend,
        ),
      );
      expect(lightHero.start, light.colorScheme.primary);
      expect(lightHero.end, AppTheme.tokensOf(light).primaryDark);
      expect(lightHero.foreground, light.colorScheme.onPrimary);
      expect(darkHero.start, dark.colorScheme.primaryContainer);
      expect(
        darkHero.end,
        Color.lerp(
          dark.colorScheme.primaryContainer,
          dark.colorScheme.surface,
          _darkHeroSurfaceBlend,
        ),
      );
      expect(darkHero.foreground, dark.colorScheme.onPrimaryContainer);
    }
  });

  test('未使用应用主题工厂的上下文仍有 Indigo Token 回退', () {
    final theme = ThemeData.light();

    final tokens = AppTheme.tokensOf(theme);

    expect(tokens.primaryDark, AppColors.primaryDark);
    expect(tokens.primarySoft, AppColors.primarySoft);
  });

  test('页面语义色随浅深主题切换并保留状态色对比度', () {
    for (final accent in FlexColor.schemes.keys) {
      for (final theme in [
        AppTheme.light(accent: accent),
        AppTheme.dark(accent: accent),
      ]) {
        expect(theme.appPageBackground, theme.scaffoldBackgroundColor);
        expect(
          theme.appCardSurface,
          theme.cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        );
        expect(theme.appBorder, theme.colorScheme.outlineVariant);
        expect(
          theme.appWarningSurface,
          AppColors.warningSurfaceFor(theme.brightness),
        );
        expect(theme.appWarning, AppColors.warningFor(theme.brightness));
        expect(theme.appSuccess, AppColors.successFor(theme.brightness));
        expect(theme.appFavorite, AppColors.favoriteFor(theme.brightness));
        expect(theme.appError, AppColors.errorFor(theme.brightness));
      }
    }
  });

  test('应用主题沿用系统默认字体', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final textStyles = [
        theme.textTheme.headlineMedium,
        theme.textTheme.titleLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.labelSmall,
        theme.appBarTheme.titleTextStyle,
      ];

      for (final style in textStyles) {
        expect(style?.fontFamily, isNull);
        expect(style?.fontFamilyFallback, isNull);
      }
    }
  });
}
