import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/domain/app_settings_state.dart';
import 'app_theme.dart';

/// 持有运行时主题选择，让设置页修改后同步更新浅色、深色两套主题。
final class AppThemeController extends GetxController {
  AppThemeController({
    required AppThemePreference themePreference,
    required FlexScheme accentPreference,
  }) : _themePreference = themePreference,
       _accentPreference = accentPreference;

  AppThemePreference _themePreference;
  FlexScheme _accentPreference;

  AppThemePreference get themePreference => _themePreference;
  FlexScheme get accentPreference => _accentPreference;

  ThemeMode get themeMode => AppTheme.modeFor(_themePreference);

  ThemeData get lightTheme => AppTheme.light(accent: _accentPreference);

  ThemeData get darkTheme => AppTheme.dark(accent: _accentPreference);

  /// 应用设置页保存后的运行时值；无变化时不触发根 MaterialApp 重建。
  void apply({
    AppThemePreference? themePreference,
    FlexScheme? accentPreference,
  }) {
    final nextTheme = themePreference ?? _themePreference;
    final nextAccent = accentPreference ?? _accentPreference;
    if (nextTheme == _themePreference && nextAccent == _accentPreference) {
      return;
    }
    _themePreference = nextTheme;
    _accentPreference = nextAccent;
    update();
  }
}
