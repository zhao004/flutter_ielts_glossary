import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/backup/backup_exceptions.dart';
import 'package:flutter_ielts_glossary/app/models/backup/backup_snapshot.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/services/backup/backup_data_codec.dart';

void main() {
  const codec = BackupDataCodec();
  final first = DateTime.utc(2026, 8, 15, 1, 2, 3);
  final second = first.add(const Duration(minutes: 5));

  BackupSnapshot createSnapshot({bool includeSettings = true}) {
    return BackupSnapshot(
      userWordStates: [
        BackupUserWordState(
          wordId: 2,
          masteryLevel: 3,
          studiedCount: 4,
          correctCount: 3,
          wrongCount: 1,
          correctStreak: 2,
          consecutiveForgottenCount: 1,
          lastStudiedAt: first,
          lastReviewedAt: null,
          nextReviewAt: second,
          updatedAt: second,
        ),
      ],
      favoriteWords: [
        BackupFavoriteWord(
          id: 'favorite-word-1',
          wordId: 2,
          createdAt: first,
          updatedAt: second,
        ),
      ],
      favoriteSentences: [
        BackupFavoriteSentence(
          id: 'favorite-sentence-1',
          sentenceId: 7,
          wordId: 2,
          createdAt: first,
          updatedAt: second,
        ),
      ],
      practiceSessions: [
        BackupPracticeSession(
          id: 'session-1',
          type: 'choice',
          configJson: '{}',
          startedAt: first,
          finishedAt: second,
          totalQuestionCount: 1,
          correctCount: 1,
          elapsedMilliseconds: 500,
        ),
      ],
      practiceAnswers: [
        BackupPracticeAnswer(
          id: 'answer-1',
          sessionId: 'session-1',
          wordId: 2,
          sentenceId: 7,
          userAnswer: '答案',
          isCorrect: true,
          responseTimeMilliseconds: 500,
          answeredAt: second,
        ),
      ],
      learningEvents: [
        BackupLearningEvent(
          id: 'event-1',
          eventType: 'practice_answered',
          wordId: 2,
          sessionId: 'session-1',
          isCorrect: true,
          reviewRating: ReviewRating.good,
          occurredAt: second,
        ),
      ],
      appSettings: includeSettings
          ? BackupAppSettings(
              id: 1,
              dailyGoal: 20,
              pronunciationAccent: 'uk',
              autoPlayPronunciation: true,
              themeMode: 'dark',
              accentColor: 'rose',
              updatedAt: second,
            )
          : null,
    );
  }

  test('编码排序稳定且可以往返还原全部字段', () {
    final snapshot = createSnapshot();
    final source = codec.encode(snapshot);
    final decoded = codec.decode(source);

    expect(decoded.userWordStates.single.wordId, 2);
    expect(decoded.favoriteSentences.single.sentenceId, 7);
    expect(decoded.practiceAnswers.single.userAnswer, '答案');
    expect(decoded.appSettings?.themeMode, 'dark');
    expect(decoded.appSettings?.accentColor, 'rose');
    expect(decoded.userWordStates.single.consecutiveForgottenCount, 1);
    expect(decoded.learningEvents.single.reviewRating, ReviewRating.good);
    expect(codec.encode(decoded), source);
  });

  test('V1 备份导入时为新增复习字段提供兼容默认值', () {
    final legacy = jsonDecode(codec.encode(createSnapshot())) as Map;
    legacy['formatVersion'] = 1;
    (legacy['userWordStates'] as List).single.remove(
      'consecutiveForgottenCount',
    );
    (legacy['learningEvents'] as List).single.remove('reviewRating');

    final decoded = codec.decode(jsonEncode(legacy));

    expect(decoded.userWordStates.single.consecutiveForgottenCount, 0);
    expect(decoded.learningEvents.single.reviewRating, isNull);
  });

  test('旧备份缺少强调色字段时回退 Indigo', () {
    final legacy = jsonDecode(codec.encode(createSnapshot())) as Map;
    (legacy['appSettings'] as Map).remove('accentColor');

    final decoded = codec.decode(jsonEncode(legacy));

    expect(decoded.appSettings?.accentColor, 'indigo');
  });

  test('拒绝重复稳定 ID、孤儿答案和非 UTC 时间', () {
    final valid = jsonDecode(codec.encode(createSnapshot())) as Map;
    final states = (valid['userWordStates'] as List).cast<Map>();
    states.add(Map<String, Object?>.from(states.single));
    expect(
      () => codec.decode(jsonEncode(valid)),
      throwsA(isA<BackupFormatException>()),
    );

    final orphan = jsonDecode(codec.encode(createSnapshot())) as Map;
    (orphan['practiceAnswers'] as List).single['sessionId'] = 'missing';
    expect(
      () => codec.decode(jsonEncode(orphan)),
      throwsA(isA<BackupFormatException>()),
    );

    final nonUtc = jsonDecode(codec.encode(createSnapshot())) as Map;
    (nonUtc['userWordStates'] as List).single['updatedAt'] =
        '2026-08-15T09:02:03+08:00';
    expect(
      () => codec.decode(jsonEncode(nonUtc)),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('空设置快照使用 null 而不是伪造默认记录', () {
    final decoded = codec.decode(
      codec.encode(createSnapshot(includeSettings: false)),
    );
    expect(decoded.appSettings, isNull);
  });
}
