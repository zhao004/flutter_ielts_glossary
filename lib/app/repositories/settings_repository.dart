import 'package:flex_color_scheme/flex_color_scheme.dart';

import '../models/domain/app_settings_state.dart';

/// 用户库包含无法识别的持久化设置值。
final class UnsupportedAppSettingValueException implements Exception {
  const UnsupportedAppSettingValueException({
    required this.field,
    required this.value,
  });

  final String field;
  final String value;

  @override
  String toString() => 'unsupported_app_setting: $field/$value';
}

/// 主题、配色、口音、自动播放和每日目标的领域接口。
abstract interface class SettingsRepository {
  Future<AppSettingsState> load();

  Future<AppSettingsState> update({
    int? dailyGoal,
    PronunciationAccent? pronunciationAccent,
    bool? autoPlayPronunciation,
    AppThemePreference? themePreference,
    FlexScheme? accentPreference,
  });
}
