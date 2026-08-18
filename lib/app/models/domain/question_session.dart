import 'question_config.dart';
import 'quiz_question.dart';

/// 开始会话前可用于候选不足提示的统计结果。
final class QuestionAvailability {
  QuestionAvailability({
    required this.scopedCandidateCount,
    required this.availableCandidateCount,
    required this.wrongCandidateCount,
  }) {
    if (scopedCandidateCount < 0 ||
        availableCandidateCount < 0 ||
        wrongCandidateCount < 0 ||
        availableCandidateCount > scopedCandidateCount ||
        wrongCandidateCount > availableCandidateCount) {
      throw ArgumentError('题目候选统计必须满足非负及包含关系');
    }
  }

  final int scopedCandidateCount;
  final int availableCandidateCount;
  final int wrongCandidateCount;
}

/// 已完成无放回抽样并生成具体题目的不可变会话。
final class QuestionSession {
  QuestionSession({
    required this.config,
    required List<QuizQuestion> questions,
    required this.availability,
  }) : questions = List<QuizQuestion>.unmodifiable(questions) {
    if (this.questions.length != config.questionCount) {
      throw ArgumentError.value(questions.length, 'questions', '会话题目数量必须与配置一致');
    }
    final questionIds = this.questions.map((question) => question.id).toSet();
    if (questionIds.length != this.questions.length) {
      throw ArgumentError.value(questions, 'questions', '会话题目 ID 不能重复');
    }
    final wordIds = this.questions.map((question) => question.wordId).toSet();
    if (wordIds.length != this.questions.length) {
      throw ArgumentError.value(questions, 'questions', '同一会话不能重复抽取单词');
    }
  }

  final QuestionConfig config;
  final List<QuizQuestion> questions;
  final QuestionAvailability availability;
}
