// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_dao.dart';

// ignore_for_file: type=lint
mixin _$ContentDaoMixin on DatabaseAccessor<ContentDatabase> {
  $FrequencyGroupsTable get frequencyGroups => attachedDatabase.frequencyGroups;
  $WordsTable get words => attachedDatabase.words;
  $SentencesTable get sentences => attachedDatabase.sentences;
  $ContentMetadataTable get contentMetadata => attachedDatabase.contentMetadata;
  ContentDaoManager get managers => ContentDaoManager(this);
}

class ContentDaoManager {
  final _$ContentDaoMixin _db;
  ContentDaoManager(this._db);
  $$FrequencyGroupsTableTableManager get frequencyGroups =>
      $$FrequencyGroupsTableTableManager(
        _db.attachedDatabase,
        _db.frequencyGroups,
      );
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$SentencesTableTableManager get sentences =>
      $$SentencesTableTableManager(_db.attachedDatabase, _db.sentences);
  $$ContentMetadataTableTableManager get contentMetadata =>
      $$ContentMetadataTableTableManager(
        _db.attachedDatabase,
        _db.contentMetadata,
      );
}
