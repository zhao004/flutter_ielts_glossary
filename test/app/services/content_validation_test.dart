import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/services/content/content_validation.dart';

void main() {
  test('校验异常可以导出完整分类统计和来源位置', () {
    final error = ContentValidationException(
      const [
        ContentValidationIssue(
          code: 'invalid_target_form',
          message: '例句不包含目标词形',
          sourceFile: 'sentences-2.json[17]',
          details: {'sentenceId': 18, 'wordId': 7, 'word': 'academic'},
        ),
        ContentValidationIssue(
          code: 'invalid_target_form',
          message: '例句不包含目标词形',
          sourceFile: 'sentences-2.json[18]',
        ),
      ],
      issueCounts: const {'invalid_target_form': 140},
    );

    expect(error.toJson(), {
      'totalIssueCount': 140,
      'issueCounts': {'invalid_target_form': 140},
      'issues': [
        {
          'code': 'invalid_target_form',
          'message': '例句不包含目标词形',
          'sourceFile': 'sentences-2.json[17]',
          'details': {'sentenceId': 18, 'wordId': 7, 'word': 'academic'},
        },
        {
          'code': 'invalid_target_form',
          'message': '例句不包含目标词形',
          'sourceFile': 'sentences-2.json[18]',
        },
      ],
    });
  });
}
