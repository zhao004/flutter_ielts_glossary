import '../models/domain/pronunciation_assessment_config.dart';

/// 第三方发音评测配置无法解码或值不合法。
final class UnsupportedAssessmentConfigException implements Exception {
  const UnsupportedAssessmentConfigException(this.message);

  final String message;

  @override
  String toString() => 'unsupported_assessment_config: $message';
}

/// 第三方发音评测配置的领域接口；凭据只保存在本机，不进入备份。
abstract interface class PronunciationAssessmentConfigRepository {
  Future<PronunciationAssessmentConfig> load();

  Future<PronunciationAssessmentConfig> save(
    PronunciationAssessmentConfig config,
  );
}
