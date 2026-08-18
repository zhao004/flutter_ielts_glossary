import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../models/domain/app_settings_state.dart';

/// 应用视觉 Token，来源于本地 Figma Make 设计稿的 Indigo 主题。
abstract final class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color lightTextPrimary = Color(0xFF1D293D);
  static const Color lightTextSecondary = Color(0xFF62748E);
  static const Color lightTextTertiary = Color(0xFF90A1B9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightCardBorder = Color(0xFFF8FAFC);
  static const Color lightSubtleBorder = Color(0xFFF1F5F9);
  static const Color lightSubtleSurface = Color(0xFFF8FAFC);
  static const Color onBrand = Colors.white;
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color lightOuterBackgroundStart = Color(0xFFE8EAFF);
  static const Color lightOuterBackgroundEnd = Color(0xFFDDE2FF);
  static const Color darkOuterBackground = Color(0xFF06060F);
  static const Color darkBackground = Color(0xFF0C0C1D);
  static const Color darkCard = Color(0xFF16162C);
  static const Color darkSurface = Color(0xFF1E1E38);
  static const Color darkTextPrimary = Color(0xFFE4E8FF);
  static const Color darkTextSecondary = Color(0xFFB0BCDA);
  static const Color darkTextTertiary = Color(0xFF687190);
  static const Color darkPrimary = Color(0xFF9AA2FF);
  static const Color darkPrimaryContainer = Color(0xFF27245F);
  static const Color darkBorder = Color(0x12FFFFFF);
  static const Color reviewCardBackStart = Color(0xFF314158);
  static const Color reviewCardBackEnd = Color(0xFF1D293D);
  static const Color darkReviewCardBackStart = Color(0xFF2A2A4A);
  static const Color darkReviewCardBackEnd = Color(0xFF111120);
  static const Color reviewCardBackTextSecondary = Color(0xFFCAD5E2);
  static const Color reviewCardBackDivider = Color(0xFF45556C);

  /// 页面状态色，统一用于警告、成功、错误和收藏反馈。
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color warning = Color(0xFFB45309);
  static const Color warningStrong = Color(0xFF92400E);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color success = Color(0xFF009966);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color navInactive = Color(0xFF94A3B8);
  static const Color favorite = Color(0xFFB45309);
  static const Color darkWarningSurface = Color(0xFF3A2A17);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkWarningStrong = Color(0xFFFCD34D);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkFavorite = Color(0xFFFBBF24);

  /// 根据当前主题返回可读的警告背景和状态色。
  static Color warningSurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkWarningSurface : warningSurface;

  /// 返回当前主题下可读的警告前景色。
  static Color warningFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkWarning : warning;

  /// 返回当前主题下可读的警告正文色。
  static Color warningStrongFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkWarningStrong : warningStrong;

  /// 返回当前主题下的成功状态色。
  static Color successFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSuccess : success;

  /// 返回当前主题下的错误状态色。
  static Color errorFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkError : error;

  /// 返回当前主题下的收藏强调色。
  static Color favoriteFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkFavorite : favorite;

  /// 返回当前主题下用于辅助信息的文字色。
  static Color tertiaryTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextTertiary : lightTextTertiary;

  /// 复习卡背面沿用设计稿的深色层级，并为深色主题保留可辨对比度。
  static LinearGradient reviewCardBackGradientFor(Brightness brightness) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: brightness == Brightness.dark
            ? const [darkReviewCardBackStart, darkReviewCardBackEnd]
            : const [reviewCardBackStart, reviewCardBackEnd],
      );
}

/// 设计稿对应的根布局尺寸，页面内容在宽屏上保持移动端信息密度。
abstract final class AppLayout {
  static const double designWidth = 402;
  static const double maxContentWidth = 430;
  static const double bottomNavigationHeight = 64;
}

/// 页面和组件共享的圆角规格，避免主题组件各自漂移。
abstract final class AppRadii {
  static const double small = 3;
  static const double medium = 8;
  static const double card = 16;
  static const double control = 12;
  static const double sheet = 24;
}

/// 页面渐变和软背景使用的品牌扩展 Token。
final class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({required this.primaryDark, required this.primarySoft});

  final Color primaryDark;
  final Color primarySoft;

  @override
  AppThemeTokens copyWith({Color? primaryDark, Color? primarySoft}) {
    return AppThemeTokens(
      primaryDark: primaryDark ?? this.primaryDark,
      primarySoft: primarySoft ?? this.primarySoft,
    );
  }

  @override
  AppThemeTokens lerp(covariant AppThemeTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppThemeTokens(
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
    );
  }
}

/// 顶部品牌区域在当前亮度下使用的渐变和前景颜色。
final class AppThemeHeroColors {
  const AppThemeHeroColors({
    required this.start,
    required this.end,
    required this.foreground,
  });

  final Color start;
  final Color end;
  final Color foreground;
}

/// 页面共享的主题表面、边框和文字语义，避免视图直接依赖亮度分支。
extension AppThemeSemantics on ThemeData {
  /// 页面根背景色。
  Color get appPageBackground => scaffoldBackgroundColor;

  /// 卡片使用的表面色。
  Color get appCardSurface =>
      cardTheme.color ?? colorScheme.surfaceContainerLow;

  /// 输入框和次级容器使用的表面色。
  Color get appSubtleSurface => colorScheme.surfaceContainer;

  /// 页面边框和分隔线使用的颜色。
  Color get appBorder => colorScheme.outlineVariant;

  /// 普通辅助文字颜色。
  Color get appTextSecondary => colorScheme.onSurfaceVariant;

  /// 弱化辅助文字颜色。
  Color get appTextTertiary => colorScheme.onSurfaceVariant.withValues(
    alpha: brightness == Brightness.dark ? 0.78 : 0.72,
  );

  /// 当前主题下的警告提示背景色。
  Color get appWarningSurface => AppColors.warningSurfaceFor(brightness);

  /// 当前主题下可读的警告文字色。
  Color get appWarning => AppColors.warningFor(brightness);

  /// 当前主题下的成功状态色。
  Color get appSuccess => AppColors.successFor(brightness);

  /// 当前主题下的收藏强调色。
  Color get appFavorite => AppColors.favoriteFor(brightness);

  /// 当前主题下的错误状态色。
  Color get appError => AppColors.errorFor(brightness);

  /// 当前主题下可读的警告正文色。
  Color get appWarningStrong => AppColors.warningStrongFor(brightness);
}

/// 集中生成应用主题，页面只使用 ThemeData 的语义颜色和文字样式。
abstract final class AppTheme {
  static const double _darkHeroSurfaceBlend = 0.28;

  /// 将持久化主题偏好映射为 Flutter 的运行时主题模式。
  static ThemeMode modeFor(AppThemePreference preference) =>
      switch (preference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  /// 浅色主题，使用 flex_color_scheme 的内置配色，并保留设计稿的卡片与背景层级。
  static ThemeData light({FlexScheme accent = FlexScheme.indigo}) {
    final base = FlexColorScheme.light(scheme: accent).toTheme;
    final scheme = base.colorScheme.copyWith(
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightTextPrimary,
    );
    return _build(base, scheme, Brightness.light);
  }

  /// 深色主题，映射设计稿中的深色背景、卡片和表面 Token。
  static ThemeData dark({FlexScheme accent = FlexScheme.indigo}) {
    final base = FlexColorScheme.dark(scheme: accent).toTheme;
    final scheme = base.colorScheme.copyWith(
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurface,
    );
    return _build(base, scheme, Brightness.dark);
  }

  /// 返回设置页使用的强调色样本。
  static Color swatchFor(FlexScheme accent) =>
      FlexColor.schemes[accent]?.light.primary ?? AppColors.primary;

  /// 返回顶部品牌区域在浅色和深色主题下对应的语义颜色层级。
  static AppThemeHeroColors heroColorsOf(ThemeData theme) {
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.dark) {
      final start = scheme.primaryContainer;
      return AppThemeHeroColors(
        start: start,
        end: Color.lerp(start, scheme.surface, _darkHeroSurfaceBlend)!,
        foreground: scheme.onPrimaryContainer,
      );
    }
    return AppThemeHeroColors(
      start: scheme.primary,
      end: tokensOf(theme).primaryDark,
      foreground: scheme.onPrimary,
    );
  }

  /// 兼容未使用本应用主题工厂的独立 Widget 测试和嵌入场景。
  static AppThemeTokens tokensOf(ThemeData theme) {
    return theme.extension<AppThemeTokens>() ??
        const AppThemeTokens(
          primaryDark: AppColors.primaryDark,
          primarySoft: AppColors.primarySoft,
        );
  }

  static ThemeData _build(
    ThemeData base,
    ColorScheme scheme,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final primaryDark = Color.lerp(
      scheme.primary,
      Colors.black,
      isDark ? 0.08 : 0.3,
    )!;
    final primarySoft = scheme.primaryContainer;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      extensions: [
        AppThemeTokens(primaryDark: primaryDark, primarySoft: primarySoft),
      ],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : scheme.primary.withValues(alpha: 0.12),
        elevation: isDark ? 1 : 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightCardBorder,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 36 / 28,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 32 / 24,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 28 / 20,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 24 / 16,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
          height: 20 / 14,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          height: 18 / 12,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          letterSpacing: 0,
        ),
        labelSmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 15 / 10,
          letterSpacing: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSubtleSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
