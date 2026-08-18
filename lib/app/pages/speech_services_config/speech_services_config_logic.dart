import 'dart:async';

import 'package:get/get.dart';

import '../../models/domain/pronunciation_assessment_config.dart';
import '../../models/domain/speech_services_config_run_state.dart';
import '../../models/domain/tts_config.dart';
import '../../repositories/pronunciation_assessment_config_repository.dart';
import '../../repositories/tts_config_repository.dart';

/// 协调第三方 TTS 与发音评测配置的读取和独立保存。
final class SpeechServicesConfigLogic extends GetxController {
  SpeechServicesConfigLogic({
    required this.ttsConfigRepository,
    required this.assessmentConfigRepository,
  });

  static const String updateId = 'speech_services_config_state';

  final TtsConfigRepository ttsConfigRepository;
  final PronunciationAssessmentConfigRepository assessmentConfigRepository;

  SpeechServicesConfigRunState _state = SpeechServicesConfigRunState.loading();
  SpeechServicesConfigRunState get state => _state;

  bool _closed = false;
  bool _savingTts = false;
  bool _savingAssessment = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// 并行读取两个独立的私有凭据配置。
  Future<void> load() async {
    if (_closed || _savingTts || _savingAssessment) {
      return;
    }
    _replace(SpeechServicesConfigRunState.loading());
    try {
      final values = await Future.wait<Object>([
        ttsConfigRepository.load(),
        assessmentConfigRepository.load(),
      ]);
      if (_closed) {
        return;
      }
      _replace(
        SpeechServicesConfigRunState(
          phase: SpeechServicesConfigPhase.loaded,
          ttsConfig: values[0] as TtsConfig,
          assessmentConfig: values[1] as PronunciationAssessmentConfig,
          isSavingTts: false,
          isSavingAssessment: false,
          errorCode: null,
          ttsErrorCode: null,
          assessmentErrorCode: null,
        ),
      );
    } on Object {
      if (!_closed) {
        _replace(
          SpeechServicesConfigRunState(
            phase: SpeechServicesConfigPhase.error,
            ttsConfig: TtsConfig.defaults(),
            assessmentConfig: PronunciationAssessmentConfig.defaults(),
            isSavingTts: false,
            isSavingAssessment: false,
            errorCode: SpeechServicesConfigErrorCodes.loadFailed,
            ttsErrorCode: null,
            assessmentErrorCode: null,
          ),
        );
      }
    }
  }

  Future<void> retry() => load();

  /// 保存 TTS 配置，不阻塞评测配置的独立操作。
  Future<void> saveTts(TtsConfig config) async {
    if (_closed ||
        _savingTts ||
        _state.phase != SpeechServicesConfigPhase.loaded) {
      return;
    }
    _savingTts = true;
    _replace(_state.copyWith(isSavingTts: true, ttsErrorCode: null));
    try {
      final saved = await ttsConfigRepository.save(config);
      if (!_closed) {
        _replace(
          _state.copyWith(
            ttsConfig: saved,
            isSavingTts: false,
            ttsErrorCode: null,
          ),
        );
      }
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(
            isSavingTts: false,
            ttsErrorCode: SpeechServicesConfigErrorCodes.ttsSaveFailed,
          ),
        );
      }
    } finally {
      _savingTts = false;
    }
  }

  /// 保存发音评测配置，不阻塞 TTS 配置的独立操作。
  Future<void> saveAssessment(PronunciationAssessmentConfig config) async {
    if (_closed ||
        _savingAssessment ||
        _state.phase != SpeechServicesConfigPhase.loaded) {
      return;
    }
    _savingAssessment = true;
    _replace(
      _state.copyWith(isSavingAssessment: true, assessmentErrorCode: null),
    );
    try {
      final saved = await assessmentConfigRepository.save(config);
      if (!_closed) {
        _replace(
          _state.copyWith(
            assessmentConfig: saved,
            isSavingAssessment: false,
            assessmentErrorCode: null,
          ),
        );
      }
    } on Object {
      if (!_closed) {
        _replace(
          _state.copyWith(
            isSavingAssessment: false,
            assessmentErrorCode:
                SpeechServicesConfigErrorCodes.assessmentSaveFailed,
          ),
        );
      }
    } finally {
      _savingAssessment = false;
    }
  }

  void _replace(SpeechServicesConfigRunState next) {
    if (_closed) {
      return;
    }
    _state = next;
    update([updateId]);
  }

  @override
  void onClose() {
    _closed = true;
    super.onClose();
  }
}
