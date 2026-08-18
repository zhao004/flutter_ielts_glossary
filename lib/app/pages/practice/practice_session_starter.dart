import '../../models/domain/practice_run_state.dart';
import '../../models/domain/question_config.dart';

/// 练习配置入口依赖的最小会话启动协议。
abstract interface class PracticeSessionStarter {
  PracticeRunState get state;

  /// 使用已通过领域校验的配置启动练习。
  Future<void> start(QuestionConfig config);
}
