import 'package:drift/drift.dart';

import '../converters/utc_date_time_milliseconds_converter.dart';
import 'daos/user_data_dao.dart';
import 'tables/app_settings.dart';
import 'tables/backup_history.dart';
import 'tables/favorite_sentences.dart';
import 'tables/favorite_words.dart';
import 'tables/learning_events.dart';
import 'tables/practice_answers.dart';
import 'tables/practice_sessions.dart';
import 'tables/user_word_states.dart';

part 'user_database.g.dart';

/// 保存用户拥有的学习、练习、收藏、设置和备份记录。
@DriftDatabase(
  tables: [
    UserWordStates,
    FavoriteWords,
    FavoriteSentences,
    PracticeSessions,
    PracticeAnswers,
    LearningEvents,
    AppSettings,
    BackupHistory,
  ],
  daos: [UserDataDao],
)
class UserDatabase extends _$UserDatabase {
  /// 平台连接和测试连接都通过显式执行器注入。
  UserDatabase.forExecutor(super.executor);

  static const String databaseName = 'ielts_user';

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(appSettings, appSettings.accentColor);
      }
      if (from < 3) {
        // 加宽 accentColor 长度约束，容纳 flex_color_scheme 的完整配色名。
        await customStatement(
          'ALTER TABLE app_settings RENAME TO app_settings_old',
        );
        await migrator.createTable(appSettings);
        await customStatement(
          'INSERT INTO app_settings '
          '(id, daily_goal, pronunciation_accent, auto_play_pronunciation, '
          'theme_mode, accent_color, updated_at) '
          'SELECT id, daily_goal, pronunciation_accent, '
          'auto_play_pronunciation, theme_mode, accent_color, updated_at '
          'FROM app_settings_old',
        );
        await customStatement('DROP TABLE app_settings_old');
      }
      if (from < 4) {
        await migrator.addColumn(
          userWordStates,
          userWordStates.consecutiveForgottenCount,
        );
        await migrator.addColumn(learningEvents, learningEvents.reviewRating);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
