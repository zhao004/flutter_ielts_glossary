import '../database/content/daos/content_dao.dart';
import '../database/user/daos/user_data_dao.dart';
import '../database/user/user_database.dart';
import '../models/domain/favorite_record.dart';
import '../services/clock/app_clock.dart';
import '../services/id/id_generator.dart';
import 'favorite_repository.dart';

/// 组合只读内容库校验与用户库收藏关系，避免写入悬空内容 ID。
final class LocalFavoriteRepository
    implements FavoriteRepository, FavoriteBatchRepository {
  LocalFavoriteRepository(
    this._contentDao,
    this._userDataDao, {
    this.clock = const SystemAppClock(),
    this.idGenerator = const UuidIdGenerator(),
  });

  final ContentDao _contentDao;
  final UserDataDao _userDataDao;
  final AppClock clock;
  final IdGenerator idGenerator;

  @override
  Future<FavoriteWordRecord?> setWordFavorite({
    required int wordId,
    required bool isFavorite,
  }) async {
    _validateContentId(wordId, 'wordId');
    if (!isFavorite) {
      await _userDataDao.deleteFavoriteWord(wordId);
      return null;
    }
    final word = await _contentDao.findWordById(wordId);
    if (word == null) {
      throw FavoriteContentNotFoundException(
        contentType: 'word',
        contentId: wordId,
      );
    }
    final existing = await _userDataDao.findFavoriteWord(wordId);
    if (existing != null) {
      return _toWordRecord(existing);
    }
    final now = clock.nowUtc().toUtc();
    await _userDataDao.insertFavoriteWordIfAbsent(
      FavoriteWordsCompanion.insert(
        id: _nextId(),
        wordId: wordId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final inserted = await _userDataDao.findFavoriteWord(wordId);
    if (inserted == null) {
      throw StateError('新增单词收藏后无法读取记录');
    }
    return _toWordRecord(inserted);
  }

  @override
  Future<FavoriteSentenceRecord?> setSentenceFavorite({
    required int sentenceId,
    required bool isFavorite,
  }) async {
    _validateContentId(sentenceId, 'sentenceId');
    if (!isFavorite) {
      await _userDataDao.deleteFavoriteSentence(sentenceId);
      return null;
    }
    final sentence = await _contentDao.findSentenceById(sentenceId);
    if (sentence == null) {
      throw FavoriteContentNotFoundException(
        contentType: 'sentence',
        contentId: sentenceId,
      );
    }
    final existing = await _userDataDao.findFavoriteSentence(sentenceId);
    if (existing != null) {
      if (existing.wordId != sentence.wordId) {
        throw StateError('例句收藏记录的关联单词与词库不一致');
      }
      return _toSentenceRecord(existing);
    }
    final now = clock.nowUtc().toUtc();
    await _userDataDao.insertFavoriteSentenceIfAbsent(
      FavoriteSentencesCompanion.insert(
        id: _nextId(),
        sentenceId: sentence.id,
        wordId: sentence.wordId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final inserted = await _userDataDao.findFavoriteSentence(sentenceId);
    if (inserted == null) {
      throw StateError('新增例句收藏后无法读取记录');
    }
    return _toSentenceRecord(inserted);
  }

  @override
  Future<bool> isWordFavorite(int wordId) async {
    _validateContentId(wordId, 'wordId');
    return await _userDataDao.findFavoriteWord(wordId) != null;
  }

  @override
  Future<bool> isSentenceFavorite(int sentenceId) async {
    _validateContentId(sentenceId, 'sentenceId');
    return await _userDataDao.findFavoriteSentence(sentenceId) != null;
  }

  @override
  Future<Set<int>> findFavoriteWordIds(Set<int> wordIds) {
    return _userDataDao.findFavoriteWordIds(wordIds);
  }

  @override
  Future<Set<int>> findFavoriteSentenceIds(Set<int> sentenceIds) {
    return _userDataDao.findFavoriteSentenceIds(sentenceIds);
  }

  @override
  Future<List<FavoriteWordRecord>> findFavoriteWords({
    int limit = 100,
    int offset = 0,
  }) async {
    final records = await _userDataDao.findFavoriteWords(
      limit: limit,
      offset: offset,
    );
    return records.map(_toWordRecord).toList(growable: false);
  }

  @override
  Future<List<FavoriteSentenceRecord>> findFavoriteSentences({
    int limit = 100,
    int offset = 0,
  }) async {
    final records = await _userDataDao.findFavoriteSentences(
      limit: limit,
      offset: offset,
    );
    return records.map(_toSentenceRecord).toList(growable: false);
  }

  @override
  Future<int> removeWordFavorites(Set<int> wordIds) {
    return _userDataDao.deleteFavoriteWords(wordIds);
  }

  @override
  Future<int> removeSentenceFavorites(Set<int> sentenceIds) {
    return _userDataDao.deleteFavoriteSentences(sentenceIds);
  }

  FavoriteWordRecord _toWordRecord(FavoriteWord record) {
    return FavoriteWordRecord(
      id: record.id,
      wordId: record.wordId,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  FavoriteSentenceRecord _toSentenceRecord(FavoriteSentence record) {
    return FavoriteSentenceRecord(
      id: record.id,
      sentenceId: record.sentenceId,
      wordId: record.wordId,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  String _nextId() {
    final id = idGenerator.nextId().trim();
    if (id.isEmpty || id.length > 64) {
      throw StateError('ID 生成器返回了无效收藏记录 ID');
    }
    return id;
  }

  void _validateContentId(int id, String name) {
    if (id <= 0) {
      throw ArgumentError.value(id, name, '内容 ID 必须为正整数');
    }
  }
}
