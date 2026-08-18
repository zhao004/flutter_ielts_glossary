import 'app_settings_state.dart';

/// 随机学习会话配置。
final class StudyConfig {
  StudyConfig({
    Set<int> frequencyGroupIds = const {},
    this.wordCount = defaultWordCount,
    this.pronunciationAccent = PronunciationAccent.uk,
    this.autoPlayPronunciation = false,
  }) : frequencyGroupIds = Set<int>.unmodifiable(frequencyGroupIds) {
    final invalid = this.frequencyGroupIds.difference(activeFrequencyGroupIds);
    if (invalid.isNotEmpty) {
      throw ArgumentError.value(
        frequencyGroupIds,
        'frequencyGroupIds',
        '学习词频组只能使用首期启用的 1-6 组',
      );
    }
    if (wordCount < minimumWordCount || wordCount > maximumWordCount) {
      throw ArgumentError.value(
        wordCount,
        'wordCount',
        '学习数量必须在 $minimumWordCount-$maximumWordCount 之间',
      );
    }
  }

  /// 使用用户级发音偏好创建一次随机学习的默认配置。
  factory StudyConfig.fromSettings(AppSettingsState settings) {
    return StudyConfig(
      pronunciationAccent: settings.pronunciationAccent,
      autoPlayPronunciation: settings.autoPlayPronunciation,
    );
  }

  static const Set<int> activeFrequencyGroupIds = {1, 2, 3, 4, 5, 6};
  static const int defaultWordCount = 20;
  static const int minimumWordCount = 1;
  static const int maximumWordCount = 100;

  final Set<int> frequencyGroupIds;
  final int wordCount;
  final PronunciationAccent pronunciationAccent;
  final bool autoPlayPronunciation;

  Set<int> get effectiveFrequencyGroupIds =>
      frequencyGroupIds.isEmpty ? activeFrequencyGroupIds : frequencyGroupIds;

  /// 复制本次学习配置并重新执行词频组和数量边界校验。
  StudyConfig copyWith({
    Set<int>? frequencyGroupIds,
    int? wordCount,
    PronunciationAccent? pronunciationAccent,
    bool? autoPlayPronunciation,
  }) {
    return StudyConfig(
      frequencyGroupIds: frequencyGroupIds ?? this.frequencyGroupIds,
      wordCount: wordCount ?? this.wordCount,
      pronunciationAccent: pronunciationAccent ?? this.pronunciationAccent,
      autoPlayPronunciation:
          autoPlayPronunciation ?? this.autoPlayPronunciation,
    );
  }
}
