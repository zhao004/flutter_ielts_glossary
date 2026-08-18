import 'backup_exceptions.dart';

/// 备份数据中各业务实体的记录数。
final class BackupRecordCounts {
  const BackupRecordCounts({
    required this.userWordStates,
    required this.favoriteWords,
    required this.favoriteSentences,
    required this.practiceSessions,
    required this.practiceAnswers,
    required this.learningEvents,
    required this.appSettings,
  });

  static const int maximumRecordCount = 1000000;

  final int userWordStates;
  final int favoriteWords;
  final int favoriteSentences;
  final int practiceSessions;
  final int practiceAnswers;
  final int learningEvents;
  final int appSettings;

  Map<String, int> toJson() => {
    'userWordStates': userWordStates,
    'favoriteWords': favoriteWords,
    'favoriteSentences': favoriteSentences,
    'practiceSessions': practiceSessions,
    'practiceAnswers': practiceAnswers,
    'learningEvents': learningEvents,
    'appSettings': appSettings,
  };

  factory BackupRecordCounts.fromJson(Object? value) {
    final map = _asMap(value, 'recordCounts');
    const keys = {
      'userWordStates',
      'favoriteWords',
      'favoriteSentences',
      'practiceSessions',
      'practiceAnswers',
      'learningEvents',
      'appSettings',
    };
    _requireExactKeys(map, keys, 'recordCounts');
    return BackupRecordCounts(
      userWordStates: _readCount(map, 'userWordStates'),
      favoriteWords: _readCount(map, 'favoriteWords'),
      favoriteSentences: _readCount(map, 'favoriteSentences'),
      practiceSessions: _readCount(map, 'practiceSessions'),
      practiceAnswers: _readCount(map, 'practiceAnswers'),
      learningEvents: _readCount(map, 'learningEvents'),
      appSettings: _readCount(map, 'appSettings'),
    );
  }

  void validate() {
    for (final entry in toJson().entries) {
      if (entry.value < 0 || entry.value > maximumRecordCount) {
        throw BackupFormatException(
          'invalid_record_count',
          '记录数 ${entry.key} 超出允许范围',
        );
      }
    }
    if (appSettings > 1) {
      throw const BackupFormatException(
        'invalid_record_count',
        'AppSettings 最多只能有一条记录',
      );
    }
  }
}

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

int _readCount(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int ||
      value < 0 ||
      value > BackupRecordCounts.maximumRecordCount) {
    throw BackupFormatException('invalid_record_count', '$key 必须是合法记录数');
  }
  return value;
}
