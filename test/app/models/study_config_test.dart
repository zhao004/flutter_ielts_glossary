import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/services/review/study_rating_policy.dart';

void main() {
  test('从用户设置创建默认配置并可安全复制本次会话选项', () {
    final settings = AppSettingsState(
      dailyGoal: 20,
      pronunciationAccent: PronunciationAccent.us,
      autoPlayPronunciation: true,
      themePreference: AppThemePreference.dark,
      updatedAt: DateTime.utc(2026, 8, 15),
    );

    final config = StudyConfig.fromSettings(settings);
    final changed = config.copyWith(
      frequencyGroupIds: const {2, 4},
      wordCount: 25,
      autoPlayPronunciation: false,
    );

    expect(config.wordCount, StudyConfig.defaultWordCount);
    expect(config.pronunciationAccent, PronunciationAccent.us);
    expect(config.autoPlayPronunciation, isTrue);
    expect(changed.frequencyGroupIds, {2, 4});
    expect(changed.wordCount, 25);
    expect(changed.pronunciationAccent, PronunciationAccent.us);
    expect(changed.autoPlayPronunciation, isFalse);
  });

  test('随机学习默认覆盖六个有效词频组并保留发音设置', () {
    final config = StudyConfig(
      pronunciationAccent: PronunciationAccent.us,
      autoPlayPronunciation: true,
    );

    expect(config.wordCount, StudyConfig.defaultWordCount);
    expect(config.effectiveFrequencyGroupIds, {1, 2, 3, 4, 5, 6});
    expect(config.pronunciationAccent, PronunciationAccent.us);
    expect(config.autoPlayPronunciation, isTrue);
  });

  test('随机学习拒绝预留词频组和越界数量', () {
    expect(
      () => StudyConfig(frequencyGroupIds: const {7}),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => StudyConfig(wordCount: StudyConfig.maximumWordCount + 1),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('参考学习评级策略稳定映射到 1/3/5 掌握等级', () {
    const policy = ReferenceStudyRatingPolicy();

    expect(policy.masteryLevelFor(StudyRating.unknown), 1);
    expect(policy.masteryLevelFor(StudyRating.familiar), 3);
    expect(policy.masteryLevelFor(StudyRating.known), 5);
  });
}
