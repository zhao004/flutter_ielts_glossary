import 'word_details.dart';

/// 随机学习卡片使用的词库候选。
final class StudyCandidate {
  const StudyCandidate(this.word);

  final WordDetails word;
}

/// 随机学习候选查询结果，包含数据库可用数量以支持候选不足提示。
final class StudyCandidateBatch {
  StudyCandidateBatch({
    required List<StudyCandidate> candidates,
    required this.availableCount,
    required this.requestedCount,
  }) : candidates = List<StudyCandidate>.unmodifiable(candidates) {
    if (availableCount < 0 || requestedCount <= 0) {
      throw ArgumentError('学习候选数量无效');
    }
    if (this.candidates.length > requestedCount ||
        this.candidates.length > availableCount) {
      throw ArgumentError('学习候选结果超出查询范围');
    }
  }

  final List<StudyCandidate> candidates;
  final int availableCount;
  final int requestedCount;

  bool get hasEnoughCandidates => candidates.length >= requestedCount;
}
