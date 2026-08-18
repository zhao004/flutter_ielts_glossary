/// 发音评测使用的第三方平台；off 表示尚未配置服务。
enum PronunciationAssessmentPlatform { off, xfyun, youdao }

extension PronunciationAssessmentPlatformLabels
    on PronunciationAssessmentPlatform {
  /// 配置页展示的短名称。
  String get label => switch (this) {
    PronunciationAssessmentPlatform.off => '未配置',
    PronunciationAssessmentPlatform.xfyun => '科大讯飞',
    PronunciationAssessmentPlatform.youdao => '有道智云',
  };

  /// 配置页展示的补充说明。
  String get description => switch (this) {
    PronunciationAssessmentPlatform.off => '需配置第三方服务后才能进行发音评测',
    PronunciationAssessmentPlatform.xfyun => '讯飞语音评测（ISE），返回音素级评分',
    PronunciationAssessmentPlatform.youdao => '有道语音评测，返回总分与流利度',
  };
}
