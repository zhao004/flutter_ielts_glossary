import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/widgets/custom_count_button.dart';

void main() {
  testWidgets('自定义数量会校验边界并回显已保存的值', (tester) async {
    var value = 10;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CustomCountButton(
              value: value,
              minimum: 5,
              maximum: 30,
              unit: '题',
              dialogTitle: '自定义题目数量',
              fieldLabel: '本次练习题数',
              enabled: true,
              onChanged: (nextValue) => setState(() => value = nextValue),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('自定义（当前 10题）'));
    await tester.pumpAndSettle();
    expect(find.text('自定义题目数量'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-count-input')),
      '4',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('请输入 5-30 之间的整数'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-count-input')),
      '17',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(value, 17);
    expect(find.text('自定义（当前 17题）'), findsOneWidget);
  });
}
