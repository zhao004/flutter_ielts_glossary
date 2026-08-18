/// 指定时间范围内基于实际复习结果计算的记忆率。
final class ReviewMemoryRate {
  const ReviewMemoryRate({
    required this.correctReviews,
    required this.completedReviews,
  }) : assert(correctReviews >= 0),
       assert(completedReviews >= correctReviews);

  final int correctReviews;
  final int completedReviews;

  double get value =>
      completedReviews == 0 ? 0 : correctReviews / completedReviews;
}
