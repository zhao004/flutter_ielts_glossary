/// 应用当前公开的页面路由名称，避免页面组件依赖路由表实现。
abstract final class AppRouteNames {
  static const String home = '/home';
  static const String vocabulary = '/vocabulary';
  static const String study = '/study';
  static const String studyFlashcards = '/study/flashcards';
  static const String practice = '/practice';
  static const String practiceQuiz = '/practice/quiz';
  static const String practiceSpelling = '/practice/spelling';
  static const String practiceCloze = '/practice/cloze';
  static const String review = '/review';
  static const String favorites = '/favorites';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String colorSchemes = '/color-schemes';
  static const String speechServices = '/speech-services';
  static const String dataBackup = '/data-backup';
  static const String pronunciation = '/pronunciation';
  static const String wordDetailsPattern = '/word/:wordId';

  /// 生成指定单词的详情页路由，并拒绝无效稳定 ID。
  static String wordDetails(int wordId) {
    if (wordId <= 0) {
      throw ArgumentError.value(wordId, 'wordId', '单词 ID 必须为正整数');
    }
    return '/word/$wordId';
  }
}
