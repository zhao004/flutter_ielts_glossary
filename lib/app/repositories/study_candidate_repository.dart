import '../models/domain/study_candidate.dart';
import '../models/domain/study_config.dart';

/// 随机学习候选查询接口。
abstract interface class StudyCandidateRepository {
  Future<StudyCandidateBatch> loadCandidates(StudyConfig config);
}
