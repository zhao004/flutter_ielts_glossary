// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_dao.dart';

// ignore_for_file: type=lint
mixin _$UserDataDaoMixin on DatabaseAccessor<UserDatabase> {
  $UserWordStatesTable get userWordStates => attachedDatabase.userWordStates;
  $FavoriteWordsTable get favoriteWords => attachedDatabase.favoriteWords;
  $FavoriteSentencesTable get favoriteSentences =>
      attachedDatabase.favoriteSentences;
  $PracticeSessionsTable get practiceSessions =>
      attachedDatabase.practiceSessions;
  $PracticeAnswersTable get practiceAnswers => attachedDatabase.practiceAnswers;
  $LearningEventsTable get learningEvents => attachedDatabase.learningEvents;
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  $BackupHistoryTable get backupHistory => attachedDatabase.backupHistory;
  UserDataDaoManager get managers => UserDataDaoManager(this);
}

class UserDataDaoManager {
  final _$UserDataDaoMixin _db;
  UserDataDaoManager(this._db);
  $$UserWordStatesTableTableManager get userWordStates =>
      $$UserWordStatesTableTableManager(
        _db.attachedDatabase,
        _db.userWordStates,
      );
  $$FavoriteWordsTableTableManager get favoriteWords =>
      $$FavoriteWordsTableTableManager(_db.attachedDatabase, _db.favoriteWords);
  $$FavoriteSentencesTableTableManager get favoriteSentences =>
      $$FavoriteSentencesTableTableManager(
        _db.attachedDatabase,
        _db.favoriteSentences,
      );
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(
        _db.attachedDatabase,
        _db.practiceSessions,
      );
  $$PracticeAnswersTableTableManager get practiceAnswers =>
      $$PracticeAnswersTableTableManager(
        _db.attachedDatabase,
        _db.practiceAnswers,
      );
  $$LearningEventsTableTableManager get learningEvents =>
      $$LearningEventsTableTableManager(
        _db.attachedDatabase,
        _db.learningEvents,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
  $$BackupHistoryTableTableManager get backupHistory =>
      $$BackupHistoryTableTableManager(_db.attachedDatabase, _db.backupHistory);
}
