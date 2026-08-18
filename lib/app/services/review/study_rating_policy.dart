import '../../models/domain/study_rating.dart';

/// 将学习自评转换为稳定掌握等级的领域策略。
abstract interface class StudyRatingPolicy {
  int masteryLevelFor(StudyRating rating);
}

/// 与参考项目学习页一致的 1/3/5 映射；后续产品调整只替换此策略。
final class ReferenceStudyRatingPolicy implements StudyRatingPolicy {
  const ReferenceStudyRatingPolicy();

  @override
  int masteryLevelFor(StudyRating rating) {
    return switch (rating) {
      StudyRating.unknown => 1,
      StudyRating.familiar => 3,
      StudyRating.known => 5,
    };
  }
}
