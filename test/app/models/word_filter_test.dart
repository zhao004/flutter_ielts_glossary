import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/word_filter.dart';

void main() {
  test('标准化首字母与关键词并计算分页偏移', () {
    final filter = WordFilter(
      firstLetter: ' a ',
      keyword: '  academic  ',
      page: 3,
      pageSize: 20,
    );

    expect(filter.firstLetter, 'A');
    expect(filter.keyword, 'academic');
    expect(filter.offset, 40);
  });

  test('拒绝非法首字母、页码和词频组 ID', () {
    expect(() => WordFilter(firstLetter: 'AB'), throwsArgumentError);
    expect(() => WordFilter(page: 0), throwsArgumentError);
    expect(() => WordFilter(frequencyGroupIds: const {0}), throwsArgumentError);
  });
}
