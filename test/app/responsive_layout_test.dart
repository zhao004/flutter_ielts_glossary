import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/app.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_page.dart';
import 'package:flutter_ielts_glossary/app/routes/app_route_names.dart';

import '../support/core_navigation_flow.dart';
import '../support/test_app_dependencies.dart';

void main() {
  testWidgets('主要页面在窄屏放大字体深色主题下无布局异常', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await seedCoreNavigationContent(dependencies.contentDatabase);
    await seedDueReview(dependencies.userDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    _expectNoLayoutException(tester, '首页');

    await tester.tap(find.text('词库'));
    await tester.pumpAndSettle();
    expect(find.text('academic'), findsOneWidget);
    _expectNoLayoutException(tester, '词库');

    final academicWord = find.text('academic');
    await tester.ensureVisible(academicWord);
    await tester.pumpAndSettle();
    await tester.tap(academicWord);
    await tester.pumpAndSettle();
    expect(find.byType(WordDetailsSheet), findsOneWidget);
    _expectNoLayoutException(tester, '单词详情');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('学习'));
    await tester.pumpAndSettle();
    expect(find.text('学习模式'), findsOneWidget);
    _expectNoLayoutException(tester, '学习中心');

    await tester.tap(find.text('复习'));
    await tester.pumpAndSettle();
    expect(find.text('今日待复习 1 个单词'), findsOneWidget);
    _expectNoLayoutException(tester, '复习');

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('学习设置'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('学习设置'), findsOneWidget);
    _expectNoLayoutException(tester, '设置');

    Get.offNamed(AppRouteNames.favorites);
    await tester.pumpAndSettle();
    expect(find.text('还没有收藏单词'), findsOneWidget);
    _expectNoLayoutException(tester, '收藏');

    Get.offNamed(AppRouteNames.statistics);
    await tester.pumpAndSettle();
    expect(find.text('学习总览'), findsOneWidget);
    _expectNoLayoutException(tester, '统计');

    Get.offNamed(AppRouteNames.dataBackup);
    await tester.pumpAndSettle();
    expect(find.text('导出备份'), findsWidgets);
    _expectNoLayoutException(tester, '数据备份');

    Get.offNamed(AppRouteNames.pronunciation, arguments: {'word': 'academic'});
    await tester.pumpAndSettle();
    expect(find.text('尚未配置第三方评测'), findsOneWidget);
    _expectNoLayoutException(tester, '发音练习');
  });
}

void _expectNoLayoutException(WidgetTester tester, String page) {
  expect(
    tester.takeException(),
    isNull,
    reason: '$page 在本次窄屏布局检查中报告了 Flutter 异常。',
  );
}
