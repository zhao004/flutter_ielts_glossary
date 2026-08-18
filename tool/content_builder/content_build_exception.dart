import 'package:flutter_ielts_glossary/app/services/content/content_validation.dart';

export 'package:flutter_ielts_glossary/app/services/content/content_validation.dart'
    show ContentValidationException;

typedef ContentBuildIssue = ContentValidationIssue;

/// 文件访问、构建或发布阶段的单一失败。
final class ContentBuildException implements Exception {
  const ContentBuildException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
