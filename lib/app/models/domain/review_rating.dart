/// 用户在翻开复习卡后对实际回忆难度给出的四档评价。
enum ReviewRating { again, hard, good, easy }

/// 提供评分对记忆统计和调度的稳定语义。
extension ReviewRatingMemory on ReviewRating {
  /// 只有完全没有回忆出的“重学”不计为一次成功提取。
  bool get recalled => this != ReviewRating.again;
}
