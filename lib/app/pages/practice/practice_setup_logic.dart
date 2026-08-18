import 'package:get/get.dart';

import '../../models/domain/practice_run_state.dart';
import '../../models/domain/practice_setup_state.dart';
import '../../models/domain/question_config.dart';
import 'practice_session_starter.dart';

/// 管理练习开始前的合法配置，并将启动委托给统一会话状态机。
class PracticeSetupLogic extends GetxController {
  PracticeSetupLogic({
    required this.practiceSessionStarter,
    QuestionConfig? initialConfig,
  }) : _state = PracticeSetupState.editing(
         initialConfig ??
             QuestionConfig.defaultsFor(QuestionType.choiceEnglishToChinese),
       );

  static const String contentUpdateId = 'practice_setup_content';

  final PracticeSessionStarter practiceSessionStarter;

  PracticeSetupState _state;
  PracticeSetupState get state => _state;

  bool _closed = false;

  /// 切换题型时保留通用筛选项，并将题量收敛到新题型范围。
  void selectQuestionType(QuestionType type) {
    final current = _requireEditableConfig('select_question_type');
    if (current.type == type) {
      return;
    }
    final isSpelling = type == QuestionType.spelling;
    _edit(
      current.copyWith(
        type: type,
        questionCount: QuestionCountLimits.constrainFor(
          type,
          current.questionCount,
        ),
        spellingPromptType: isSpelling ? SpellingPromptType.translation : null,
        allowSpellingPhrases: false,
      ),
    );
  }

  /// 使用显式词频组，并关闭与其互斥的难度筛选。
  void selectFrequencyGroups(Set<int> frequencyGroupIds) {
    final current = _requireEditableConfig('select_frequency_groups');
    final normalized = Set<int>.unmodifiable(frequencyGroupIds);
    if (_sameSet(current.frequencyGroupIds, normalized) &&
        current.difficulty == null) {
      return;
    }
    _edit(current.copyWith(frequencyGroupIds: normalized, difficulty: null));
  }

  /// 使用难度映射范围；传入 `null` 表示恢复全部有效词频组。
  void selectDifficulty(QuestionDifficulty? difficulty) {
    final current = _requireEditableConfig('select_difficulty');
    if (current.frequencyGroupIds.isEmpty && current.difficulty == difficulty) {
      return;
    }
    _edit(
      current.copyWith(frequencyGroupIds: const {}, difficulty: difficulty),
    );
  }

  /// 设置是否优先抽取历史错题。
  void setWrongFirst(bool value) {
    final current = _requireEditableConfig('set_wrong_first');
    if (current.wrongFirst == value) {
      return;
    }
    _edit(current.copyWith(wrongFirst: value));
  }

  /// 设置题量；越界输入由 `QuestionConfig` 统一拒绝且不会改变现有状态。
  void setQuestionCount(int value) {
    final current = _requireEditableConfig('set_question_count');
    if (current.questionCount == value) {
      return;
    }
    _edit(current.copyWith(questionCount: value));
  }

  /// 设置是否展示会话和单题计时。
  void setTimed(bool value) {
    final current = _requireEditableConfig('set_timed');
    if (current.timed == value) {
      return;
    }
    _edit(current.copyWith(timed: value));
  }

  /// 设置拼写提示来源，非拼写题调用属于页面接线错误。
  void setSpellingPromptType(SpellingPromptType value) {
    final current = _requireEditableConfig('set_spelling_prompt_type');
    if (current.type != QuestionType.spelling) {
      throw StateError('只有拼写题可以设置提示来源');
    }
    if (current.spellingPromptType == value) {
      return;
    }
    _edit(current.copyWith(spellingPromptType: value));
  }

  /// 设置拼写题是否允许多词短语，非拼写题调用属于页面接线错误。
  void setAllowSpellingPhrases(bool value) {
    final current = _requireEditableConfig('set_allow_spelling_phrases');
    if (current.type != QuestionType.spelling) {
      throw StateError('只有拼写题可以设置多词短语');
    }
    if (current.allowSpellingPhrases == value) {
      return;
    }
    _edit(current.copyWith(allowSpellingPhrases: value));
  }

  /// 候选不足且实际数量仍满足题型下限时，将题量调整为实际可用数量。
  void useAvailableQuestionCount() {
    _requirePhase(const {
      PracticeSetupPhase.insufficientCandidates,
    }, 'use_available_question_count');
    if (!_state.canUseAvailableQuestionCount) {
      throw StateError('实际候选数量未达到当前题型最小题量');
    }
    final availableCount = _state.availability!.availableCandidateCount;
    _edit(_state.config.copyWith(questionCount: availableCount));
  }

  /// 使用当前配置启动统一练习会话，并映射候选不足或稳定错误状态。
  Future<void> start() async {
    _requirePhase(const {
      PracticeSetupPhase.editing,
      PracticeSetupPhase.insufficientCandidates,
      PracticeSetupPhase.error,
    }, 'start');
    final previousState = _state;
    final config = _state.config;
    _replaceState(PracticeSetupState.starting(config));
    try {
      await practiceSessionStarter.start(config);
    } on PracticeSessionTransitionException {
      if (!_closed) {
        _replaceState(previousState);
      }
      rethrow;
    } on Exception {
      if (!_closed) {
        _replaceState(
          PracticeSetupState.error(
            config: config,
            errorCode: PracticeRunErrorCodes.preparationFailed,
          ),
        );
      }
      return;
    }
    if (_closed) {
      return;
    }

    final runState = practiceSessionStarter.state;
    switch (runState.phase) {
      case PracticeRunPhase.answering:
        final availability = runState.availability;
        if (availability == null) {
          _replacePreparationError(config);
          return;
        }
        _replaceState(
          PracticeSetupState.started(
            config: config,
            availability: availability,
            candidatePoolTruncated: runState.candidatePoolTruncated,
          ),
        );
      case PracticeRunPhase.insufficientCandidates:
        final availability = runState.availability;
        if (availability == null) {
          _replacePreparationError(config);
          return;
        }
        _replaceState(
          PracticeSetupState.insufficientCandidates(
            config: config,
            availability: availability,
            candidatePoolTruncated: runState.candidatePoolTruncated,
          ),
        );
      case PracticeRunPhase.error:
        _replaceState(
          PracticeSetupState.error(
            config: config,
            errorCode:
                runState.errorCode ?? PracticeRunErrorCodes.preparationFailed,
          ),
        );
      case _:
        _replacePreparationError(config);
    }
  }

  QuestionConfig _requireEditableConfig(String action) {
    _requirePhase(const {
      PracticeSetupPhase.editing,
      PracticeSetupPhase.insufficientCandidates,
      PracticeSetupPhase.error,
    }, action);
    return _state.config;
  }

  void _edit(QuestionConfig config) {
    _replaceState(PracticeSetupState.editing(config));
  }

  void _replacePreparationError(QuestionConfig config) {
    _replaceState(
      PracticeSetupState.error(
        config: config,
        errorCode: PracticeRunErrorCodes.preparationFailed,
      ),
    );
  }

  void _requirePhase(Set<PracticeSetupPhase> allowed, String action) {
    if (!allowed.contains(_state.phase)) {
      throw PracticeSetupTransitionException(
        phase: _state.phase,
        action: action,
      );
    }
  }

  void _replaceState(PracticeSetupState nextState) {
    if (_closed) {
      return;
    }
    _state = nextState;
    update([contentUpdateId]);
  }

  bool _sameSet(Set<int> first, Set<int> second) {
    return first.length == second.length && first.containsAll(second);
  }

  @override
  void onClose() {
    _closed = true;
    super.onClose();
  }
}
