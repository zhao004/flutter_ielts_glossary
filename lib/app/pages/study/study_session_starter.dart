import '../../models/domain/study_config.dart';
import '../../models/domain/study_run_state.dart';

/// 随机学习配置入口依赖的最小会话启动协议。
abstract interface class StudySessionStarter {
  StudyRunState get state;

  /// 使用已通过领域校验的配置启动随机学习。
  Future<void> start(StudyConfig config);
}
