import 'pronunciation_assessment_config.dart';
import 'tts_config.dart';

/// 统一语音服务配置页面的加载阶段。
enum SpeechServicesConfigPhase { loading, loaded, error }

/// 统一语音服务配置页面的稳定错误码。
abstract final class SpeechServicesConfigErrorCodes {
  static const String loadFailed = 'speech_services_config_load_failed';
  static const String ttsSaveFailed = 'speech_services_config_tts_save_failed';
  static const String assessmentSaveFailed =
      'speech_services_config_assessment_save_failed';
}

/// TTS 与发音评测配置的不可变聚合快照。
final class SpeechServicesConfigRunState {
  const SpeechServicesConfigRunState({
    required this.phase,
    required this.ttsConfig,
    required this.assessmentConfig,
    required this.isSavingTts,
    required this.isSavingAssessment,
    required this.errorCode,
    required this.ttsErrorCode,
    required this.assessmentErrorCode,
  }) : assert(
         phase == SpeechServicesConfigPhase.loaded ||
             (!isSavingTts && !isSavingAssessment),
       );

  factory SpeechServicesConfigRunState.loading() {
    return SpeechServicesConfigRunState(
      phase: SpeechServicesConfigPhase.loading,
      ttsConfig: TtsConfig.defaults(),
      assessmentConfig: PronunciationAssessmentConfig.defaults(),
      isSavingTts: false,
      isSavingAssessment: false,
      errorCode: null,
      ttsErrorCode: null,
      assessmentErrorCode: null,
    );
  }

  final SpeechServicesConfigPhase phase;
  final TtsConfig ttsConfig;
  final PronunciationAssessmentConfig assessmentConfig;
  final bool isSavingTts;
  final bool isSavingAssessment;
  final String? errorCode;
  final String? ttsErrorCode;
  final String? assessmentErrorCode;

  SpeechServicesConfigRunState copyWith({
    SpeechServicesConfigPhase? phase,
    TtsConfig? ttsConfig,
    PronunciationAssessmentConfig? assessmentConfig,
    bool? isSavingTts,
    bool? isSavingAssessment,
    Object? errorCode = _unset,
    Object? ttsErrorCode = _unset,
    Object? assessmentErrorCode = _unset,
  }) {
    return SpeechServicesConfigRunState(
      phase: phase ?? this.phase,
      ttsConfig: ttsConfig ?? this.ttsConfig,
      assessmentConfig: assessmentConfig ?? this.assessmentConfig,
      isSavingTts: isSavingTts ?? this.isSavingTts,
      isSavingAssessment: isSavingAssessment ?? this.isSavingAssessment,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      ttsErrorCode: identical(ttsErrorCode, _unset)
          ? this.ttsErrorCode
          : ttsErrorCode as String?,
      assessmentErrorCode: identical(assessmentErrorCode, _unset)
          ? this.assessmentErrorCode
          : assessmentErrorCode as String?,
    );
  }
}

const _unset = Object();
