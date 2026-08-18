import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_settings_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/settings_repository.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';

void main() {
  late UserDatabase database;
  late _MutableClock clock;
  late LocalSettingsRepository repository;

  setUp(() {
    database = UserDatabase.forExecutor(NativeDatabase.memory());
    clock = _MutableClock(DateTime.utc(2026, 8, 15, 12));
    repository = LocalSettingsRepository(database, clock: clock);
  });

  tearDown(() => database.close());

  test('未初始化时返回领域默认值且不隐式写数据库', () async {
    final settings = await repository.load();

    expect(settings.dailyGoal, AppSettingsState.defaultDailyGoal);
    expect(settings.pronunciationAccent, PronunciationAccent.uk);
    expect(settings.autoPlayPronunciation, isFalse);
    expect(settings.themePreference, AppThemePreference.system);
    expect(settings.accentPreference, FlexScheme.indigo);
    expect(settings.updatedAtUtc, null);
    expect(await database.select(database.appSettings).get(), isEmpty);
  });

  test('部分更新在事务中合并现有设置并使用稳定协议值', () async {
    final first = await repository.update(
      dailyGoal: 25,
      pronunciationAccent: PronunciationAccent.us,
    );
    clock.now = clock.now.add(const Duration(minutes: 1));
    final second = await repository.update(
      autoPlayPronunciation: true,
      themePreference: AppThemePreference.dark,
      accentPreference: FlexScheme.rosewood,
    );
    final raw = await database.userDataDao.findAppSetting();

    expect(first.dailyGoal, 25);
    expect(second.dailyGoal, 25);
    expect(second.pronunciationAccent, PronunciationAccent.us);
    expect(second.autoPlayPronunciation, isTrue);
    expect(second.themePreference, AppThemePreference.dark);
    expect(second.accentPreference, FlexScheme.rosewood);
    expect(raw?.pronunciationAccent, 'us');
    expect(raw?.themeMode, 'dark');
    expect(raw?.accentColor, 'rosewood');
    expect(second.updatedAtUtc, clock.now);
  });

  test('数据库默认强调色兼容未升级的旧设置记录', () async {
    await database.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 10,
        pronunciationAccent: 'uk',
        autoPlayPronunciation: false,
        themeMode: 'system',
        updatedAt: clock.now,
      ),
    );

    final settings = await repository.load();

    expect(settings.accentPreference, FlexScheme.indigo);
    expect(
      (await database.userDataDao.findAppSetting())?.accentColor,
      'indigo',
    );
  });

  test('设备时间回拨不会让设置更新时间倒退', () async {
    final first = await repository.update(dailyGoal: 20);
    clock.now = clock.now.subtract(const Duration(days: 1));

    final second = await repository.update(dailyGoal: 30);

    expect(second.dailyGoal, 30);
    expect(second.updatedAtUtc, first.updatedAtUtc);
  });

  test('兼容读取既有大小写协议值和历史配色别名并拒绝未知枚举', () async {
    await database.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 10,
        pronunciationAccent: 'UK',
        autoPlayPronunciation: false,
        themeMode: 'LIGHT',
        accentColor: Value('ROSE'),
        updatedAt: clock.now,
      ),
    );

    final compatible = await repository.load();
    expect(compatible.pronunciationAccent, PronunciationAccent.uk);
    expect(compatible.themePreference, AppThemePreference.light);
    expect(compatible.accentPreference, FlexScheme.rosewood);

    await database.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 10,
        pronunciationAccent: 'uk',
        autoPlayPronunciation: false,
        themeMode: 'dark',
        accentColor: Value('SKY'),
        updatedAt: clock.now,
      ),
    );
    expect((await repository.load()).accentPreference, FlexScheme.aquaBlue);

    await database.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 10,
        pronunciationAccent: 'uk',
        autoPlayPronunciation: false,
        themeMode: 'dark',
        accentColor: Value('VIOLET'),
        updatedAt: clock.now,
      ),
    );
    expect((await repository.load()).accentPreference, FlexScheme.deepPurple);

    await database.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 10,
        pronunciationAccent: 'ZZ',
        autoPlayPronunciation: false,
        themeMode: 'weird',
        accentColor: Value('indigo'),
        updatedAt: clock.now,
      ),
    );
    await expectLater(
      repository.load(),
      throwsA(isA<UnsupportedAppSettingValueException>()),
    );
  });

  test('越界每日目标不会写入设置表', () async {
    await expectLater(
      repository.update(dailyGoal: 0),
      throwsA(isA<ArgumentError>()),
    );
    expect(await database.select(database.appSettings).get(), isEmpty);
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}
