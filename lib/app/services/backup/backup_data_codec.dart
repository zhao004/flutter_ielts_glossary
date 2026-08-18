import 'dart:convert';

import 'package:flex_color_scheme/flex_color_scheme.dart';

import '../../models/backup/backup_exceptions.dart';
import '../../models/backup/backup_snapshot.dart';
import '../../models/domain/review_rating.dart';

/// 负责 data.json 的稳定字段编码与严格解码，不接触文件系统或数据库。
final class BackupDataCodec {
  const BackupDataCodec();

  static const int currentFormatVersion = 2;
  static const int maximumStringLength = 1000000;
  static const int maximumInteger = 9000000000000000;
  static const int maximumDurationMilliseconds = 9000000000000;

  /// 将快照编码为无空白、排序稳定的 UTF-8 JSON 文本。
  String encode(BackupSnapshot snapshot) {
    return jsonEncode(encodeValue(snapshot));
  }

  /// 将快照编码为只含 JSON 基础类型的值，供 Isolate 之间传递。
  Map<String, Object?> encodeValue(BackupSnapshot snapshot) {
    return _encodeRoot(snapshot);
  }

  /// 从 data.json 文本恢复类型化快照，并拒绝未知字段和重复稳定 ID。
  BackupSnapshot decode(String source) {
    if (source.isEmpty || source.length > maximumStringLength) {
      throw const BackupFormatException(
        'invalid_data_length',
        'data.json 长度超出允许范围',
      );
    }
    return decodeValue(_decodeJson(source));
  }

  /// 从已在后台解析的 JSON 值恢复类型化快照，避免主 Isolate 再次解析文本。
  BackupSnapshot decodeValue(Object? decoded) {
    final root = _asMap(decoded, 'data');
    _requireExactKeys(root, {
      'formatVersion',
      'userWordStates',
      'favoriteWords',
      'favoriteSentences',
      'practiceSessions',
      'practiceAnswers',
      'learningEvents',
      'appSettings',
    }, 'data');
    final formatVersion = root['formatVersion'];
    if (formatVersion is! int ||
        (formatVersion != 1 && formatVersion != currentFormatVersion)) {
      throw const BackupFormatException(
        'unsupported_data_version',
        'data.json 版本不受支持',
      );
    }

    final userWordStates = _readList(
      root['userWordStates'],
      'userWordStates',
      (map) => _decodeUserWordState(map, formatVersion),
    );
    final favoriteWords = _readList(
      root['favoriteWords'],
      'favoriteWords',
      _decodeFavoriteWord,
    );
    final favoriteSentences = _readList(
      root['favoriteSentences'],
      'favoriteSentences',
      _decodeFavoriteSentence,
    );
    final practiceSessions = _readList(
      root['practiceSessions'],
      'practiceSessions',
      _decodePracticeSession,
    );
    final practiceAnswers = _readList(
      root['practiceAnswers'],
      'practiceAnswers',
      _decodePracticeAnswer,
    );
    final learningEvents = _readList(
      root['learningEvents'],
      'learningEvents',
      (map) => _decodeLearningEvent(map, formatVersion),
    );
    final appSettingsValue = root['appSettings'];
    final appSettings = appSettingsValue == null
        ? null
        : _decodeAppSettings(_asMap(appSettingsValue, 'appSettings'));

    _validateUnique(
      userWordStates.map((row) => row.wordId),
      'userWordStates.wordId',
    );
    _validateUnique(favoriteWords.map((row) => row.id), 'favoriteWords.id');
    _validateUnique(
      favoriteWords.map((row) => row.wordId),
      'favoriteWords.wordId',
    );
    _validateUnique(
      favoriteSentences.map((row) => row.id),
      'favoriteSentences.id',
    );
    _validateUnique(
      favoriteSentences.map((row) => row.sentenceId),
      'favoriteSentences.sentenceId',
    );
    _validateUnique(
      practiceSessions.map((row) => row.id),
      'practiceSessions.id',
    );
    _validateUnique(practiceAnswers.map((row) => row.id), 'practiceAnswers.id');
    _validateUnique(learningEvents.map((row) => row.id), 'learningEvents.id');

    final sessionIds = practiceSessions.map((row) => row.id).toSet();
    for (final answer in practiceAnswers) {
      if (!sessionIds.contains(answer.sessionId)) {
        throw BackupFormatException(
          'orphan_practice_answer',
          '答案 ${answer.id} 引用了不存在的会话',
        );
      }
    }
    return BackupSnapshot(
      userWordStates: userWordStates,
      favoriteWords: favoriteWords,
      favoriteSentences: favoriteSentences,
      practiceSessions: practiceSessions,
      practiceAnswers: practiceAnswers,
      learningEvents: learningEvents,
      appSettings: appSettings,
    );
  }

  Map<String, Object?> _encodeRoot(BackupSnapshot snapshot) {
    final states = [...snapshot.userWordStates]
      ..sort((a, b) => a.wordId.compareTo(b.wordId));
    final favoriteWords = [...snapshot.favoriteWords]
      ..sort((a, b) => _compareContentAndId(a.wordId, a.id, b.wordId, b.id));
    final favoriteSentences = [...snapshot.favoriteSentences]
      ..sort(
        (a, b) => _compareContentAndId(a.sentenceId, a.id, b.sentenceId, b.id),
      );
    final sessions = [...snapshot.practiceSessions]
      ..sort((a, b) => a.id.compareTo(b.id));
    final answers = [...snapshot.practiceAnswers]
      ..sort((a, b) => a.id.compareTo(b.id));
    final events = [...snapshot.learningEvents]
      ..sort((a, b) => a.id.compareTo(b.id));
    return {
      'formatVersion': currentFormatVersion,
      'userWordStates': states
          .map(_encodeUserWordState)
          .toList(growable: false),
      'favoriteWords': favoriteWords
          .map(_encodeFavoriteWord)
          .toList(growable: false),
      'favoriteSentences': favoriteSentences
          .map(_encodeFavoriteSentence)
          .toList(growable: false),
      'practiceSessions': sessions
          .map(_encodePracticeSession)
          .toList(growable: false),
      'practiceAnswers': answers
          .map(_encodePracticeAnswer)
          .toList(growable: false),
      'learningEvents': events
          .map(_encodeLearningEvent)
          .toList(growable: false),
      'appSettings': snapshot.appSettings == null
          ? null
          : _encodeAppSettings(snapshot.appSettings!),
    };
  }

  Map<String, Object?> _encodeUserWordState(BackupUserWordState row) => {
    'wordId': row.wordId,
    'masteryLevel': row.masteryLevel,
    'studiedCount': row.studiedCount,
    'correctCount': row.correctCount,
    'wrongCount': row.wrongCount,
    'correctStreak': row.correctStreak,
    'consecutiveForgottenCount': row.consecutiveForgottenCount,
    'lastStudiedAt': _encodeDate(row.lastStudiedAt),
    'lastReviewedAt': _encodeDate(row.lastReviewedAt),
    'nextReviewAt': _encodeDate(row.nextReviewAt),
    'updatedAt': _encodeDate(row.updatedAt),
  };

  Map<String, Object?> _encodeFavoriteWord(BackupFavoriteWord row) => {
    'id': row.id,
    'wordId': row.wordId,
    'createdAt': _encodeDate(row.createdAt),
    'updatedAt': _encodeDate(row.updatedAt),
  };

  Map<String, Object?> _encodeFavoriteSentence(BackupFavoriteSentence row) => {
    'id': row.id,
    'sentenceId': row.sentenceId,
    'wordId': row.wordId,
    'createdAt': _encodeDate(row.createdAt),
    'updatedAt': _encodeDate(row.updatedAt),
  };

  Map<String, Object?> _encodePracticeSession(BackupPracticeSession row) => {
    'id': row.id,
    'type': row.type,
    'configJson': row.configJson,
    'startedAt': _encodeDate(row.startedAt),
    'finishedAt': _encodeDate(row.finishedAt),
    'totalQuestionCount': row.totalQuestionCount,
    'correctCount': row.correctCount,
    'elapsedMilliseconds': row.elapsedMilliseconds,
  };

  Map<String, Object?> _encodePracticeAnswer(BackupPracticeAnswer row) => {
    'id': row.id,
    'sessionId': row.sessionId,
    'wordId': row.wordId,
    'sentenceId': row.sentenceId,
    'userAnswer': row.userAnswer,
    'isCorrect': row.isCorrect,
    'responseTimeMilliseconds': row.responseTimeMilliseconds,
    'answeredAt': _encodeDate(row.answeredAt),
  };

  Map<String, Object?> _encodeLearningEvent(BackupLearningEvent row) => {
    'id': row.id,
    'eventType': row.eventType,
    'wordId': row.wordId,
    'sessionId': row.sessionId,
    'isCorrect': row.isCorrect,
    'reviewRating': row.reviewRating?.name,
    'occurredAt': _encodeDate(row.occurredAt),
  };

  Map<String, Object?> _encodeAppSettings(BackupAppSettings row) => {
    'id': row.id,
    'dailyGoal': row.dailyGoal,
    'pronunciationAccent': row.pronunciationAccent,
    'autoPlayPronunciation': row.autoPlayPronunciation,
    'themeMode': row.themeMode,
    'accentColor': row.accentColor,
    'updatedAt': _encodeDate(row.updatedAt),
  };

  BackupUserWordState _decodeUserWordState(
    Map<String, Object?> map,
    int formatVersion,
  ) {
    const legacyKeys = {
      'wordId',
      'masteryLevel',
      'studiedCount',
      'correctCount',
      'wrongCount',
      'correctStreak',
      'lastStudiedAt',
      'lastReviewedAt',
      'nextReviewAt',
      'updatedAt',
    };
    const currentKeys = {...legacyKeys, 'consecutiveForgottenCount'};
    _requireExactKeys(
      map,
      formatVersion == 1 ? legacyKeys : currentKeys,
      'userWordStates item',
    );
    return BackupUserWordState(
      wordId: _readInt(map, 'wordId', min: 1),
      masteryLevel: _readInt(map, 'masteryLevel', min: 0, max: 5),
      studiedCount: _readInt(map, 'studiedCount', min: 0),
      correctCount: _readInt(map, 'correctCount', min: 0),
      wrongCount: _readInt(map, 'wrongCount', min: 0),
      correctStreak: _readInt(map, 'correctStreak', min: 0),
      consecutiveForgottenCount: formatVersion == 1
          ? 0
          : _readInt(map, 'consecutiveForgottenCount', min: 0),
      lastStudiedAt: _readNullableDate(map, 'lastStudiedAt'),
      lastReviewedAt: _readNullableDate(map, 'lastReviewedAt'),
      nextReviewAt: _readNullableDate(map, 'nextReviewAt'),
      updatedAt: _readDate(map, 'updatedAt'),
    );
  }

  BackupFavoriteWord _decodeFavoriteWord(Map<String, Object?> map) {
    _requireExactKeys(map, {
      'id',
      'wordId',
      'createdAt',
      'updatedAt',
    }, 'favoriteWords item');
    return BackupFavoriteWord(
      id: _readRecordId(map, 'id'),
      wordId: _readInt(map, 'wordId', min: 1),
      createdAt: _readDate(map, 'createdAt'),
      updatedAt: _readDate(map, 'updatedAt'),
    );
  }

  BackupFavoriteSentence _decodeFavoriteSentence(Map<String, Object?> map) {
    _requireExactKeys(map, {
      'id',
      'sentenceId',
      'wordId',
      'createdAt',
      'updatedAt',
    }, 'favoriteSentences item');
    return BackupFavoriteSentence(
      id: _readRecordId(map, 'id'),
      sentenceId: _readInt(map, 'sentenceId', min: 1),
      wordId: _readInt(map, 'wordId', min: 1),
      createdAt: _readDate(map, 'createdAt'),
      updatedAt: _readDate(map, 'updatedAt'),
    );
  }

  BackupPracticeSession _decodePracticeSession(Map<String, Object?> map) {
    _requireExactKeys(map, {
      'id',
      'type',
      'configJson',
      'startedAt',
      'finishedAt',
      'totalQuestionCount',
      'correctCount',
      'elapsedMilliseconds',
    }, 'practiceSessions item');
    return BackupPracticeSession(
      id: _readRecordId(map, 'id'),
      type: _readText(map, 'type', max: 64, min: 1),
      configJson: _readText(map, 'configJson', max: 4096, min: 2),
      startedAt: _readDate(map, 'startedAt'),
      finishedAt: _readNullableDate(map, 'finishedAt'),
      totalQuestionCount: _readInt(map, 'totalQuestionCount', min: 0),
      correctCount: _readInt(map, 'correctCount', min: 0),
      elapsedMilliseconds: _readInt(
        map,
        'elapsedMilliseconds',
        min: 0,
        max: maximumDurationMilliseconds,
      ),
    );
  }

  BackupPracticeAnswer _decodePracticeAnswer(Map<String, Object?> map) {
    _requireExactKeys(map, {
      'id',
      'sessionId',
      'wordId',
      'sentenceId',
      'userAnswer',
      'isCorrect',
      'responseTimeMilliseconds',
      'answeredAt',
    }, 'practiceAnswers item');
    return BackupPracticeAnswer(
      id: _readRecordId(map, 'id'),
      sessionId: _readRecordId(map, 'sessionId'),
      wordId: _readInt(map, 'wordId', min: 1),
      sentenceId: _readNullableInt(map, 'sentenceId', min: 1),
      userAnswer: _readText(map, 'userAnswer', max: 1000),
      isCorrect: _readBool(map, 'isCorrect'),
      responseTimeMilliseconds: _readInt(
        map,
        'responseTimeMilliseconds',
        min: 0,
        max: maximumDurationMilliseconds,
      ),
      answeredAt: _readDate(map, 'answeredAt'),
    );
  }

  BackupLearningEvent _decodeLearningEvent(
    Map<String, Object?> map,
    int formatVersion,
  ) {
    const legacyKeys = {
      'id',
      'eventType',
      'wordId',
      'sessionId',
      'isCorrect',
      'occurredAt',
    };
    const currentKeys = {...legacyKeys, 'reviewRating'};
    _requireExactKeys(
      map,
      formatVersion == 1 ? legacyKeys : currentKeys,
      'learningEvents item',
    );
    return BackupLearningEvent(
      id: _readRecordId(map, 'id'),
      eventType: _readText(map, 'eventType', max: 64, min: 1),
      wordId: _readInt(map, 'wordId', min: 1),
      sessionId: _readNullableRecordId(map, 'sessionId'),
      isCorrect: _readNullableBool(map, 'isCorrect'),
      reviewRating: formatVersion == 1
          ? null
          : _readNullableReviewRating(map['reviewRating']),
      occurredAt: _readDate(map, 'occurredAt'),
    );
  }

  ReviewRating? _readNullableReviewRating(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw const BackupFormatException(
        'invalid_review_rating',
        '复习评分必须是字符串或空值',
      );
    }
    try {
      return ReviewRating.values.byName(value);
    } on ArgumentError {
      throw const BackupFormatException('invalid_review_rating', '复习评分不受支持');
    }
  }

  BackupAppSettings _decodeAppSettings(Map<String, Object?> map) {
    const legacyKeys = {
      'id',
      'dailyGoal',
      'pronunciationAccent',
      'autoPlayPronunciation',
      'themeMode',
      'updatedAt',
    };
    const currentKeys = {...legacyKeys, 'accentColor'};
    final keys = map.keys.toSet();
    final isLegacy =
        keys.length == legacyKeys.length && keys.containsAll(legacyKeys);
    final isCurrent =
        keys.length == currentKeys.length && keys.containsAll(currentKeys);
    if (!isLegacy && !isCurrent) {
      throw const BackupFormatException(
        'invalid_fields',
        'appSettings 字段集合不匹配协议',
      );
    }
    final id = _readInt(map, 'id', min: 1, max: 1);
    final dailyGoal = _readInt(map, 'dailyGoal', min: 1, max: 500);
    final accent = _readText(map, 'pronunciationAccent', min: 2, max: 2);
    final theme = _readText(map, 'themeMode', min: 4, max: 6);
    final accentColor = map.containsKey('accentColor')
        ? _readText(map, 'accentColor', min: 3, max: 32)
        : 'indigo';
    if (accent != 'uk' && accent != 'us') {
      throw const BackupFormatException(
        'invalid_settings',
        'pronunciationAccent 不是 uk/us',
      );
    }
    if (theme != 'system' && theme != 'light' && theme != 'dark') {
      throw const BackupFormatException(
        'invalid_settings',
        'themeMode 不是受支持的值',
      );
    }
    if (!_isSupportedAccentColor(accentColor)) {
      throw const BackupFormatException(
        'invalid_settings',
        'accentColor 不是受支持的值',
      );
    }
    return BackupAppSettings(
      id: id,
      dailyGoal: dailyGoal,
      pronunciationAccent: accent,
      autoPlayPronunciation: _readBool(map, 'autoPlayPronunciation'),
      themeMode: theme,
      accentColor: accentColor,
      updatedAt: _readDate(map, 'updatedAt'),
    );
  }

  Object? _decodeJson(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException(
        'invalid_data_json',
        'data.json 不是合法 JSON',
      );
    }
  }

  List<T> _readList<T>(
    Object? value,
    String field,
    T Function(Map<String, Object?>) decoder,
  ) {
    if (value is! List || value.length > 1000000) {
      throw BackupFormatException('invalid_records', '$field 必须是有限数组');
    }
    return value
        .map((item) => decoder(_asMap(item, '$field item')))
        .toList(growable: false);
  }

  void _validateUnique(Iterable<Object> values, String field) {
    final seen = <Object>{};
    for (final value in values) {
      if (!seen.add(value)) {
        throw BackupFormatException('duplicate_record', '$field 存在重复值');
      }
    }
  }

  int _compareContentAndId(
    int leftContent,
    String leftId,
    int rightContent,
    String rightId,
  ) {
    final contentResult = leftContent.compareTo(rightContent);
    return contentResult == 0 ? leftId.compareTo(rightId) : contentResult;
  }

  String? _encodeDate(DateTime? value) => value?.toUtc().toIso8601String();

  Map<String, Object?> _asMap(Object? value, String field) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw BackupFormatException('invalid_field_type', '$field 必须是对象');
  }

  void _requireExactKeys(
    Map<String, Object?> map,
    Set<String> expected,
    String field,
  ) {
    if (!map.keys.toSet().containsAll(expected) ||
        !expected.containsAll(map.keys)) {
      throw BackupFormatException('invalid_fields', '$field 字段集合不匹配协议');
    }
  }

  int _readInt(
    Map<String, Object?> map,
    String key, {
    int min = -maximumInteger,
    int max = maximumInteger,
  }) {
    final value = map[key];
    if (value is! int || value < min || value > max) {
      throw BackupFormatException('invalid_integer', '$key 不是合法整数');
    }
    return value;
  }

  int? _readNullableInt(
    Map<String, Object?> map,
    String key, {
    int min = -maximumInteger,
    int max = maximumInteger,
  }) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! int || value < min || value > max) {
      throw BackupFormatException('invalid_integer', '$key 不是合法整数');
    }
    return value;
  }

  bool _readBool(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! bool) {
      throw BackupFormatException('invalid_boolean', '$key 必须是布尔值');
    }
    return value;
  }

  bool? _readNullableBool(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! bool) {
      throw BackupFormatException('invalid_boolean', '$key 必须是布尔值');
    }
    return value;
  }

  String _readRecordId(Map<String, Object?> map, String key) {
    return _readText(
      map,
      key,
      min: 1,
      max: 64,
      rejectSurroundingWhitespace: true,
    );
  }

  String? _readNullableRecordId(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! String ||
        value.isEmpty ||
        value.length > 64 ||
        value.trim() != value) {
      throw BackupFormatException('invalid_record_id', '$key 不是合法记录 ID');
    }
    return value;
  }

  bool _isSupportedAccentColor(String value) {
    final normalized = value.trim().toLowerCase();
    const legacy = {'violet', 'rose', 'emerald', 'sky'};
    return legacy.contains(normalized) ||
        FlexScheme.values.any(
          (scheme) => scheme.name.toLowerCase() == normalized,
        );
  }

  String _readText(
    Map<String, Object?> map,
    String key, {
    int min = 0,
    required int max,
    bool rejectSurroundingWhitespace = false,
  }) {
    final value = map[key];
    if (value is! String ||
        value.length < min ||
        value.length > max ||
        (rejectSurroundingWhitespace && value.trim() != value)) {
      throw BackupFormatException('invalid_text', '$key 字符串长度或格式无效');
    }
    return value;
  }

  DateTime _readDate(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String) {
      throw BackupFormatException('invalid_date', '$key 必须是 UTC 时间字符串');
    }
    final date = DateTime.tryParse(value);
    if (date == null || !date.isUtc || !value.endsWith('Z')) {
      throw BackupFormatException('invalid_date', '$key 必须是带 Z 的 UTC 时间');
    }
    return date;
  }

  DateTime? _readNullableDate(Map<String, Object?> map, String key) {
    if (map[key] == null) {
      return null;
    }
    return _readDate(map, key);
  }
}
