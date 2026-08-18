import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/app.dart';
import 'package:flutter_ielts_glossary/app/bootstrap/app_dependencies.dart';
import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_page.dart';

/// 用一条最小可用词条贯穿首页、词库、详情和设置页面的公共测试流程。
Future<void> runCoreNavigationFlow(
  WidgetTester tester,
  AppDependencies dependencies,
) async {
  await seedCoreNavigationContent(dependencies.contentDatabase);
  await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
  await tester.pumpAndSettle();
  expect(find.text('今日目标'), findsOneWidget);

  await tester.tap(find.text('词库'));
  await tester.pumpAndSettle();
  expect(find.text('academic'), findsOneWidget);

  await tester.tap(find.text('academic'));
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: find.byType(WordDetailsSheet),
      matching: find.text('学术的'),
    ),
    findsOneWidget,
  );
  await tester.tap(
    find.descendant(
      of: find.byType(WordDetailsSheet),
      matching: find.byTooltip('收藏单词'),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: find.byType(WordDetailsSheet),
      matching: find.byTooltip('取消收藏'),
    ),
    findsOneWidget,
  );

  Navigator.of(
    tester.element(find.byType(WordDetailsSheet)),
    rootNavigator: true,
  ).pop();
  await tester.pumpAndSettle();
  expect(find.byType(WordDetailsSheet), findsNothing);
  await tester.tap(find.byTooltip('打开我的'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('学习设置'),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  expect(find.text('学习设置'), findsOneWidget);
}

/// 为导航流程提供确定性的内存词库，不依赖正式内容资产。
Future<void> seedCoreNavigationContent(ContentDatabase database) async {
  await database.batch((batch) {
    batch.insert(
      database.frequencyGroups,
      FrequencyGroupsCompanion.insert(
        id: const drift.Value(1),
        name: '高频',
        rank: 1,
        minOccurrences: 100,
      ),
    );
    batch.insert(
      database.words,
      WordsCompanion.insert(
        id: const drift.Value(1),
        word: 'academic',
        phoneticUk: const drift.Value('ˌækəˈdemɪk'),
        phoneticUs: const drift.Value('ˌækəˈdemɪk'),
        translationZh: const drift.Value('学术的'),
        definitionEn: const drift.Value('related to education'),
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
      ),
    );
    batch.insert(
      database.sentences,
      SentencesCompanion.insert(
        id: const drift.Value(101),
        wordId: 1,
        targetForm: 'academic',
        sentenceEn: 'The academic year begins in September.',
        translationZh: const drift.Value('学年从九月开始。'),
      ),
    );
  });
}

/// 为需要真实复习卡的页面测试写入一条已到期学习记录。
Future<void> seedDueReview(UserDatabase database) async {
  final studiedAt = DateTime.utc(2020, 1, 1, 8);
  await database
      .into(database.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: const drift.Value(1),
          studiedCount: const drift.Value(1),
          lastStudiedAt: drift.Value(studiedAt),
          nextReviewAt: drift.Value(studiedAt.add(const Duration(hours: 4))),
          updatedAt: studiedAt,
        ),
      );
}
