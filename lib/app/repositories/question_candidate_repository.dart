import '../models/domain/question_candidate.dart';
import '../models/domain/question_config.dart';

abstract final class QuestionCandidatePoolLimits {
  static const int minimum = 100;
  static const int maximum = 500;
}

/// 数据库候选查询结果，同时说明池是否因运行时上限被截断。
final class QuestionCandidateBatch {
  QuestionCandidateBatch({
    required List<QuestionCandidate> candidates,
    required this.databaseQualifiedWordCount,
    required this.poolLimit,
  }) : candidates = List<QuestionCandidate>.unmodifiable(candidates) {
    if (databaseQualifiedWordCount < 0) {
      throw ArgumentError.value(
        databaseQualifiedWordCount,
        'databaseQualifiedWordCount',
        '数据库候选数量不能小于 0',
      );
    }
    if (poolLimit <= 0 || this.candidates.length > poolLimit) {
      throw ArgumentError.value(poolLimit, 'poolLimit', '候选池上限无效');
    }
  }

  final List<QuestionCandidate> candidates;

  /// 数据库字段级资格数量；填空目标词形的最终边界检查仍由领域服务完成。
  final int databaseQualifiedWordCount;
  final int poolLimit;

  bool get isTruncated => databaseQualifiedWordCount > candidates.length;
}

/// 将只读内容库和用户错题历史组合为出题候选快照。
abstract interface class QuestionCandidateRepository {
  Future<QuestionCandidateBatch> loadCandidateBatch(
    QuestionConfig config, {
    int? minimumPoolLimit,
  });
}
