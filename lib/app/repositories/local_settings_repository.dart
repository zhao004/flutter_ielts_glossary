import 'package:drift/drift.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import '../database/user/user_database.dart';
import '../models/domain/app_settings_state.dart';
import '../services/clock/app_clock.dart';
import 'settings_repository.dart';

/// 在单个用户库事务中读取、合并并持久化应用设置。
final class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(
    this._database, {
    this.clock = const SystemAppClock(),
  });

  final UserDatabase _database;
  final AppClock clock;

  @override
  Future<AppSettingsState> load() async {
    final setting = await _database.userDataDao.findAppSetting();
    return setting == null ? AppSettingsState.defaults() : _toDomain(setting);
  }

  @override
  Future<AppSettingsState> update({
    int? dailyGoal,
    PronunciationAccent? pronunciationAccent,
    bool? autoPlayPronunciation,
    AppThemePreference? themePreference,
    FlexScheme? accentPreference,
  }) {
    return _database.transaction(() async {
      final existingRecord = await _database.userDataDao.findAppSetting();
      final existing = existingRecord == null
          ? AppSettingsState.defaults()
          : _toDomain(existingRecord);
      final candidate = AppSettingsState(
        dailyGoal: dailyGoal ?? existing.dailyGoal,
        pronunciationAccent:
            pronunciationAccent ?? existing.pronunciationAccent,
        autoPlayPronunciation:
            autoPlayPronunciation ?? existing.autoPlayPronunciation,
        themePreference: themePreference ?? existing.themePreference,
        accentPreference: accentPreference ?? existing.accentPreference,
        updatedAt: _nextUpdatedAt(existing.updatedAtUtc),
      );
      await _database.userDataDao.upsertAppSetting(
        AppSettingsCompanion.insert(
          dailyGoal: candidate.dailyGoal,
          pronunciationAccent: candidate.pronunciationAccent.name,
          autoPlayPronunciation: candidate.autoPlayPronunciation,
          themeMode: candidate.themePreference.name,
          accentColor: Value(candidate.accentPreference.name),
          updatedAt: candidate.updatedAtUtc!,
        ),
      );
      final saved = await _database.userDataDao.findAppSetting();
      if (saved == null) {
        throw StateError('保存应用设置后无法读取记录');
      }
      return _toDomain(saved);
    });
  }

  AppSettingsState _toDomain(AppSetting setting) {
    return AppSettingsState(
      dailyGoal: setting.dailyGoal,
      pronunciationAccent: _decodeAccent(setting.pronunciationAccent),
      autoPlayPronunciation: setting.autoPlayPronunciation,
      themePreference: _decodeTheme(setting.themeMode),
      accentPreference: _decodeAccentColor(setting.accentColor),
      updatedAt: setting.updatedAt,
    );
  }

  PronunciationAccent _decodeAccent(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'uk' => PronunciationAccent.uk,
      'us' => PronunciationAccent.us,
      _ => throw UnsupportedAppSettingValueException(
        field: 'pronunciationAccent',
        value: value,
      ),
    };
  }

  AppThemePreference _decodeTheme(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'system' => AppThemePreference.system,
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => throw UnsupportedAppSettingValueException(
        field: 'themePreference',
        value: value,
      ),
    };
  }

  FlexScheme _decodeAccentColor(String value) {
    final normalized = value.trim().toLowerCase();
    // 旧版本的强调色枚举已并入 flex_color_scheme，映射到最接近的内置配色。
    final migrated = switch (normalized) {
      'violet' => 'deepPurple',
      'rose' => 'rosewood',
      'emerald' => 'green',
      'sky' => 'aquaBlue',
      _ => normalized,
    };
    final target = migrated.toLowerCase();
    final match = FlexScheme.values.where(
      (candidate) => candidate.name.toLowerCase() == target,
    );
    if (match.isEmpty) {
      throw UnsupportedAppSettingValueException(
        field: 'accentPreference',
        value: value,
      );
    }
    return match.first;
  }

  DateTime _nextUpdatedAt(DateTime? existing) {
    final now = clock.nowUtc().toUtc();
    return existing != null && now.isBefore(existing) ? existing : now;
  }
}
