/// 内容构建、安装或复核阶段可安全展示的结构化问题。
final class ContentValidationIssue {
  const ContentValidationIssue({
    required this.code,
    required this.message,
    this.sourceFile,
    this.details = const <String, Object>{},
  });

  final String code;
  final String message;
  final String? sourceFile;
  final Map<String, Object> details;

  /// 将校验问题转换为可写入构建审计报告的结构化对象。
  Map<String, Object> toJson() {
    final result = <String, Object>{'code': code, 'message': message};
    if (sourceFile != null) {
      result['sourceFile'] = sourceFile!;
    }
    if (details.isNotEmpty) {
      result['details'] = Map<String, Object>.from(details);
    }
    return result;
  }

  @override
  String toString() {
    final location = sourceFile == null ? '' : ' [$sourceFile]';
    return '$code$location: $message';
  }
}

/// 内容不满足完整性约束时抛出，并保留问题分类统计。
final class ContentValidationException implements Exception {
  factory ContentValidationException(
    Iterable<ContentValidationIssue> issues, {
    Map<String, int>? issueCounts,
  }) {
    final issueList = List<ContentValidationIssue>.unmodifiable(issues);
    return ContentValidationException._(
      issueList,
      Map<String, int>.unmodifiable(issueCounts ?? _countIssues(issueList)),
    );
  }

  const ContentValidationException._(this.issues, this.issueCounts);

  final List<ContentValidationIssue> issues;
  final Map<String, int> issueCounts;

  int get totalIssueCount =>
      issueCounts.values.fold(0, (sum, count) => sum + count);

  /// 返回保留的问题明细和完整分类统计，供 CLI 或 CI 保存审计产物。
  Map<String, Object> toJson() => {
    'totalIssueCount': totalIssueCount,
    'issueCounts': Map<String, int>.from(issueCounts),
    'issues': [for (final issue in issues) issue.toJson()],
  };

  @override
  String toString() => issues.join('\n');

  static Map<String, int> _countIssues(List<ContentValidationIssue> issues) {
    final counts = <String, int>{};
    for (final issue in issues) {
      counts.update(issue.code, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}
