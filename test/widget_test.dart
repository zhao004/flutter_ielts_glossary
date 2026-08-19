import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:get/get.dart';

import 'package:flutter_ielts_glossary/app/models/domain/learning_statistics.dart';
import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/question_config.dart';
import 'package:flutter_ielts_glossary/app/app.dart';
import 'package:flutter_ielts_glossary/app/routes/app_pages.dart';
import 'package:flutter_ielts_glossary/app/routes/app_route_names.dart';
import 'package:flutter_ielts_glossary/app/theme/app_theme.dart';
import 'package:flutter_ielts_glossary/app/theme/app_theme_controller.dart';
import 'package:flutter_ielts_glossary/app/pages/home/home_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/home/home_page.dart';
import 'package:flutter_ielts_glossary/app/models/domain/local_date.dart';
import 'package:flutter_ielts_glossary/app/repositories/statistics_repository.dart';
import 'package:flutter_ielts_glossary/app/bindings/initial_binding.dart';
import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/pages/vocabulary/vocabulary_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/vocabulary/vocabulary_page.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/word_details/word_details_page.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/practice/practice_page.dart';
import 'package:flutter_ielts_glossary/app/pages/review/review_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/review/review_page.dart';
import 'package:flutter_ielts_glossary/app/widgets/app_bottom_navigation.dart';
import 'package:flutter_ielts_glossary/app/pages/favorites/favorites_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/favorites/favorites_page.dart';
import 'package:flutter_ielts_glossary/app/pages/statistics/statistics_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/statistics/statistics_page.dart';
import 'package:flutter_ielts_glossary/app/pages/settings/settings_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/settings/settings_page.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/data_backup/backup_page.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_binding.dart';
import 'package:flutter_ielts_glossary/app/pages/pronunciation_practice/pronunciation_practice_page.dart';
import 'support/core_navigation_flow.dart';
import 'support/test_app_dependencies.dart';

void main() {
  testWidgets('应用启动后显示首页仪表盘', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('今日目标'), findsOneWidget);
    expect(find.text('本周进度'), findsOneWidget);
  });

  testWidgets('应用启动时恢复已保存的主题偏好', (tester) async {
    final dependencies = await createTestAppDependencies(
      initialThemePreference: AppThemePreference.dark,
    );
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('今日目标'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('应用启动时恢复配色并支持运行时切换', (tester) async {
    final dependencies = await createTestAppDependencies(
      initialAccentPreference: FlexScheme.rosewood,
    );
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('今日目标'))).colorScheme.primary,
      AppTheme.light(accent: FlexScheme.rosewood).colorScheme.primary,
    );

    Get.find<AppThemeController>().apply(accentPreference: FlexScheme.aquaBlue);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('今日目标'))).colorScheme.primary,
      AppTheme.light(accent: FlexScheme.aquaBlue).colorScheme.primary,
    );
  });

  testWidgets('375 窄屏、放大字体和深色主题下核心配置无布局异常', (tester) async {
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
    await _seedPracticeContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('今日目标'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byTooltip('开始学习'));
    await tester.pumpAndSettle();
    expect(find.text('学习模式'), findsOneWidget);
    await tester.tap(find.text('拼写练习'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('英文释义'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('英文释义'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开我的'));
    await tester.pumpAndSettle();
    expect(find.text('学习设置'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('系统'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('系统'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页统计失败显示独立错误态并支持重试', (tester) async {
    final repository = _WidgetStatisticsRepository()..fail = true;
    final logic = HomeLogic(statisticsRepository: repository, autoLoad: false);
    Get.put<HomeLogic>(logic);
    addTearDown(() {
      Get.reset();
    });

    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    await logic.load();
    await tester.pump();

    expect(find.text('首页数据加载失败'), findsOneWidget);
    expect(find.text('暂无学习记录'), findsNothing);

    repository.fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('今日目标'), findsOneWidget);
  });

  testWidgets('词库页面在无内容时显示空状态', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    VocabularyBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: VocabularyPage()));
    await tester.pumpAndSettle();

    expect(find.text('词库').first, findsOneWidget);
    expect(find.text('没有匹配的单词'), findsOneWidget);
  });

  testWidgets('首页可以通过导航操作进入词库', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开词库'));
    await tester.pumpAndSettle();

    expect(find.text('词库').first, findsOneWidget);
    expect(find.text('没有匹配的单词'), findsOneWidget);
  });

  testWidgets('详情页面在词条不存在时显示可理解状态', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    WordDetailsBinding().dependencies();

    await tester.pumpWidget(
      const GetMaterialApp(home: WordDetailsPage(wordId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('找不到这个单词'), findsOneWidget);
  });

  testWidgets('详情页面展示真实释义、例句和记忆法', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedWordDetailsContent(dependencies.contentDatabase);
    InitialBinding(dependencies).dependencies();
    WordDetailsBinding().dependencies();

    await tester.pumpWidget(
      const GetMaterialApp(home: WordDetailsPage(wordId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('学术的'), findsWidgets);
    expect(find.text('释义'), findsOneWidget);
    expect(find.text('学术的'), findsOneWidget);
    expect(find.text('/ˌækəˈdemɪk/'), findsOneWidget);
    expect(find.text('US'), findsOneWidget);
    expect(find.text('UK'), findsOneWidget);
    expect(find.text('评测'), findsOneWidget);
    for (final key in [
      const ValueKey('word-details-audio-us'),
      const ValueKey('word-details-audio-uk'),
      const ValueKey('word-details-assessment'),
    ]) {
      final button = tester.widget<TextButton>(find.byKey(key));
      expect(button.style?.shape?.resolve({}), isA<StadiumBorder>());
    }
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('例句'), findsOneWidget);
    expect(find.text('记忆法'), findsOneWidget);
    expect(find.text('The academic year begins in September.'), findsOneWidget);
  });

  testWidgets('词库卡片点击弹出详情弹层', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedWordDetailsContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开词库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('academic'));
    await tester.pumpAndSettle();

    expect(find.text('academic'), findsWidgets);
    expect(find.text('学术的'), findsWidgets);
    final listFavorite = find.byKey(const ValueKey('vocabulary-favorite-1'));
    expect(tester.widget<IconButton>(listFavorite).tooltip, '收藏单词');
    await tester.tap(find.byKey(const ValueKey('word-details-favorite')));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(listFavorite).tooltip, '取消收藏');
  });

  testWidgets('词库进入详情返回后保留列表滚动位置', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedPracticeContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开词库'));
    await tester.pumpAndSettle();

    final listFinder = find.byKey(
      const PageStorageKey<String>('vocabulary-list'),
    );
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pumpAndSettle();
    final before = tester
        .widget<CustomScrollView>(listFinder)
        .controller!
        .offset;
    expect(before, greaterThan(0));

    await tester.tap(find.text('woman'));
    await tester.pumpAndSettle();
    expect(find.text('woman'), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final after = tester
        .widget<CustomScrollView>(listFinder)
        .controller!
        .offset;
    expect(after, closeTo(before, 0.1));
  });

  testWidgets('词库筛选改变结果集后回到列表顶部', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedPracticeContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开词库'));
    await tester.pumpAndSettle();
    final listFinder = find.byKey(
      const PageStorageKey<String>('vocabulary-list'),
    );
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CustomScrollView>(listFinder).controller!.offset,
      greaterThan(0),
    );

    await tester.enterText(
      find.byType(TextField, skipOffstage: false),
      'wheat',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(tester.widget<CustomScrollView>(listFinder).controller!.offset, 0);
    expect(find.text('共 1 个单词'), findsOneWidget);
  });

  testWidgets('随机学习可以完成一次真实翻卡会话', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedWordDetailsContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('开始学习'));
    await tester.pumpAndSettle();
    expect(find.text('学习模式'), findsOneWidget);
    await tester.tap(find.text('翻卡学习'));
    await tester.pumpAndSettle();
    expect(find.text('翻卡查看释义，按掌握程度评分'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('study-custom-word-count')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-count-input')),
      '20',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始学习'));
    await tester.pumpAndSettle();
    expect(find.text('改为学习 1 个'), findsOneWidget);
    await tester.tap(find.text('改为学习 1 个'));
    await tester.tap(find.text('开始学习'));
    await tester.pumpAndSettle();
    expect(find.text('academic'), findsOneWidget);

    final favorite = find.byKey(const ValueKey('study-favorite'));
    expect(favorite, findsOneWidget);
    expect(tester.widget<IconButton>(favorite).tooltip, '收藏单词');
    final appBarRect = tester.getRect(find.byType(AppBar));
    final favoriteRect = tester.getRect(favorite);
    expect(favoriteRect.top, greaterThanOrEqualTo(appBarRect.top));
    expect(favoriteRect.bottom, lessThanOrEqualTo(appBarRect.bottom));
    expect(favoriteRect.center.dx, greaterThan(appBarRect.center.dx));

    final ukAudio = find.byKey(const ValueKey('study-pronunciation-uk'));
    final usAudio = find.byKey(const ValueKey('study-pronunciation-us'));
    final pronunciationPractice = find.byKey(
      const ValueKey('study-pronunciation-practice'),
    );
    for (final buttonFinder in [ukAudio, usAudio, pronunciationPractice]) {
      final button = tester.widget<TextButton>(buttonFinder);
      expect(button.style?.shape?.resolve({}), isA<StadiumBorder>());
    }

    await tester.binding.setSurfaceSize(const Size(375, 812));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    await tester.pumpAndSettle();
    final ukAudioRect = tester.getRect(ukAudio);
    final usAudioRect = tester.getRect(usAudio);
    final pronunciationPracticeRect = tester.getRect(pronunciationPractice);
    expect(ukAudioRect.center.dy, closeTo(usAudioRect.center.dy, 0.01));
    expect(
      ukAudioRect.center.dy,
      closeTo(pronunciationPracticeRect.center.dy, 0.01),
    );
    expect(tester.takeException(), isNull, reason: '翻卡学习操作区在窄屏放大字体下不应发生布局异常。');
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(const Size(800, 900));
    await tester.pumpAndSettle();

    await tester.tap(favorite);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(favorite).tooltip, '取消收藏');

    expect(find.text('发音练习'), findsOneWidget);
    await tester.tap(pronunciationPractice);
    await tester.pumpAndSettle();
    expect(find.text('尚未配置第三方评测'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('academic'), findsWidgets);

    await tester.tap(find.text('academic'));
    await tester.pumpAndSettle();
    expect(find.text('学术的'), findsOneWidget);
    await tester.tap(find.text('认识'));
    await tester.pumpAndSettle();

    expect(find.text('学习完成'), findsOneWidget);
  });

  testWidgets('练习页面可以完成五道真实选择题', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedPracticeContent(dependencies.contentDatabase);
    InitialBinding(dependencies).dependencies();
    PracticeBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();
    expect(find.text('选择题'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('practice-custom-question-count')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-count-input')),
      '5',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始答题'));
    await tester.pumpAndSettle();

    expect(find.text('英译中'), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-favorite')), findsNothing);
    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();
      if (index == 0) {
        final favorite = _expectPracticeFavoriteInAppBar(tester);
        await tester.tap(favorite);
        await tester.pumpAndSettle();
        expect(tester.widget<IconButton>(favorite).tooltip, '取消收藏当前单词');
        await tester.binding.setSurfaceSize(const Size(375, 812));
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        await tester.pumpAndSettle();
        _expectPracticeFavoriteInAppBar(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '练习反馈页在窄屏放大字体下不应发生布局异常。',
        );
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.binding.setSurfaceSize(const Size(800, 900));
        await tester.pumpAndSettle();
      }
      if (index < 4) {
        await tester.tap(find.text('下一题'));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('完成练习'));
    await tester.pumpAndSettle();

    expect(find.text('练习完成'), findsOneWidget);
  });

  testWidgets('练习页面的听音拼写可以播放提示', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedPracticeContent(dependencies.contentDatabase);
    InitialBinding(dependencies).dependencies();
    PracticeBinding(
      initialConfig: QuestionConfig(
        type: QuestionType.spelling,
        questionCount: 5,
        spellingPromptType: SpellingPromptType.audio,
      ),
    ).dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();
    expect(find.text('拼写练习'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('practice-custom-question-count')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-count-input')),
      '5',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始拼写'));
    await tester.pumpAndSettle();

    expect(find.text('听音拼写'), findsOneWidget);
    expect(find.text('播放发音'), findsOneWidget);
    await tester.tap(find.text('播放发音'));
    await tester.pumpAndSettle();
    expect(find.text('播放发音'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'incorrect');
    await tester.tap(find.text('提交答案'));
    await tester.pumpAndSettle();
    _expectPracticeFavoriteInAppBar(tester);
  });

  testWidgets('练习页面的例句填空可以逐级显示首字母提示', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedPracticeContent(dependencies.contentDatabase);
    InitialBinding(dependencies).dependencies();
    PracticeBinding(
      initialConfig: QuestionConfig(type: QuestionType.cloze, questionCount: 5),
    ).dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();

    expect(find.text('例句填空'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('practice-custom-question-count')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-count-input')),
      '5',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始填空'));
    await tester.pumpAndSettle();

    expect(find.text('根据语境填入正确词形'), findsOneWidget);
    expect(find.textContaining('首字母 w'), findsOneWidget);
    await tester.tap(find.textContaining('首字母 w'));
    await tester.pumpAndSettle();
    expect(find.text('💡 提示：w____'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'incorrect');
    await tester.tap(find.text('确认答案'));
    await tester.pumpAndSettle();
    _expectPracticeFavoriteInAppBar(tester);
  });

  testWidgets('例句填空入口先展示题量配置再开始练习', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedPracticeContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('开始学习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('例句填空'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRouteNames.practiceCloze);
    expect(
      find.byKey(const ValueKey('practice-custom-question-count')),
      findsOneWidget,
    );
    expect(find.text('开始填空'), findsOneWidget);
    expect(find.text('根据语境填入正确词形'), findsNothing);
  });

  testWidgets('复习页面在没有到期单词时显示空状态', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    ReviewBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: ReviewPage()));
    await tester.pumpAndSettle();

    expect(find.text('暂时没有到期单词'), findsOneWidget);
  });

  testWidgets('到期复习提示态对齐卡片布局并在翻卡后展示操作', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedWordDetailsContent(dependencies.contentDatabase);
    await seedDueReview(dependencies.userDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开复习'));
    await tester.pumpAndSettle();

    expect(find.text('今日待复习 1 个单词'), findsOneWidget);
    expect(find.text('academic'), findsWidgets);
    final reviewFab = find.byKey(const ValueKey('review-start-fab'));
    expect(reviewFab, findsOneWidget);
    expect(find.text('开始复习 →'), findsNothing);
    expect(
      tester.getRect(reviewFab).bottom,
      lessThan(tester.getRect(find.byType(AppBottomNavigation)).top),
    );
    await tester.tap(reviewFab);
    await tester.pumpAndSettle();
    expect(find.byType(ReviewSessionPage), findsOneWidget);

    await tester.tap(find.byTooltip('返回复习列表'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewSessionPage), findsNothing);
    expect(find.text('今日待复习 1 个单词'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-start-fab')));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewSessionPage), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    final card = find.byKey(const ValueKey('review-flip-card'));
    expect(card, findsOneWidget);
    expect(tester.getSize(card), const Size(370, 260));
    expect(find.text('点击卡片查看释义后作答'), findsOneWidget);
    expect(find.text('学术的'), findsNothing);
    expect(find.text('掌握等级 0/5'), findsNothing);
    expect(find.byTooltip('播放UK发音'), findsOneWidget);
    expect(find.byTooltip('播放US发音'), findsOneWidget);
    expect(find.text('发音练习'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('review-pronunciation-uk')));
    await tester.pumpAndSettle();
    expect(find.text('学术的'), findsNothing);
    expect(find.text('掌握等级 0/5'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('review-flip-card')));
    await tester.pumpAndSettle();

    expect(find.text('学术的'), findsOneWidget);
    expect(find.text('掌握等级 0/5'), findsOneWidget);
    expect(find.text('发音练习'), findsNothing);
    expect(find.text('重学'), findsOneWidget);
    expect(find.text('困难'), findsOneWidget);
    expect(find.text('记得'), findsOneWidget);
    expect(find.text('轻松'), findsOneWidget);

    await tester.tap(find.text('记得'));
    await tester.pumpAndSettle();
    expect(find.text('复习完成'), findsOneWidget);
  });

  testWidgets('单词详情可以进入当前单词发音练习', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedWordDetailsContent(dependencies.contentDatabase);

    await tester.pumpWidget(IeltsGlossaryApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开词库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('academic'));
    await tester.pumpAndSettle();
    expect(find.text('academic'), findsWidgets);
    await tester.tap(find.byTooltip('进入发音评测'));
    await tester.pumpAndSettle();
    expect(find.text('尚未配置第三方评测'), findsOneWidget);
  });

  testWidgets('收藏页面在没有收藏内容时显示空状态', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    FavoritesBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: FavoritesPage()));
    await tester.pumpAndSettle();

    expect(find.text('还没有收藏单词'), findsOneWidget);
  });

  testWidgets('收藏单词在当前页面底部打开详情弹窗', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    await _seedWordDetailsContent(dependencies.contentDatabase);
    await dependencies.favoriteRepository.setWordFavorite(
      wordId: 1,
      isFavorite: true,
    );
    InitialBinding(dependencies).dependencies();
    FavoritesBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: FavoritesPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('academic'));
    await tester.pumpAndSettle();

    expect(find.byType(WordDetailsSheet), findsOneWidget);
    expect(find.byType(WordDetailsPage), findsNothing);
    expect(find.byType(ModalBarrier), findsAtLeastNWidgets(1));
  });

  testWidgets('统计页面展示真实空数据报告', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    StatisticsBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: StatisticsPage()));
    await tester.pumpAndSettle();

    expect(find.text('学习总览'), findsOneWidget);
    expect(find.text('复习记忆率'), findsOneWidget);
  });

  testWidgets('设置页面展示已加载的本地设置和词库信息', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    SettingsBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('每日目标：'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('每日目标：'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('语音服务配置'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('语音服务配置'), findsOneWidget);
    expect(find.text('语音能力'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('关于词库'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('关于词库'), findsOneWidget);
    await tester.tap(find.text('关于词库'));
    await tester.pumpAndSettle();
    final aboutDialog = find.byType(AlertDialog);
    expect(aboutDialog, findsOneWidget);
    expect(
      find.descendant(
        of: aboutDialog,
        matching: find.textContaining('词库 test-v1'),
      ),
      findsOneWidget,
    );
    expect(find.text('关闭'), findsOneWidget);
  });

  testWidgets('自定义每日目标在对话框退出动画期间保持输入控制器有效', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    SettingsBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    final customGoal = find.text('自定义目标');
    await tester.ensureVisible(customGoal);
    await tester.pumpAndSettle();
    await tester.tap(customGoal);
    await tester.pump();

    await tester.enterText(find.byType(TextField), '27');
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final saved = await dependencies.userDatabase.userDataDao.findAppSetting();
    expect(saved?.dailyGoal, 27);
  });

  testWidgets('设置页从统一入口打开语音服务配置', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    SettingsBinding().dependencies();

    await tester.pumpWidget(
      GetMaterialApp(home: const SettingsPage(), getPages: AppPages.routes),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('语音服务配置'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    final speechServicesEntry = find.text('语音服务配置');
    await tester.ensureVisible(speechServicesEntry);
    await tester.pumpAndSettle();
    await tester.tap(speechServicesEntry);
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRouteNames.speechServices);
    expect(find.text('第三方 TTS'), findsOneWidget);
    expect(find.text('第三方发音评测'), findsOneWidget);
  });

  testWidgets('设置页快捷入口以独立页面打开收藏和统计', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    SettingsBinding().dependencies();

    await tester.pumpWidget(
      GetMaterialApp(home: const SettingsPage(), getPages: AppPages.routes),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('我的收藏'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('我的收藏'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRouteNames.favorites);
    expect(find.byType(FavoritesPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('学习统计'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('学习统计'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRouteNames.statistics);
    expect(find.byType(StatisticsPage), findsOneWidget);
  });

  testWidgets('设置页跳转配色选择页并保存选择', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    SettingsBinding().dependencies();

    await tester.pumpWidget(
      GetMaterialApp(home: const SettingsPage(), getPages: AppPages.routes),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('主题配色'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('主题配色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('蓝色'));
    await tester.pumpAndSettle();

    final saved = await dependencies.userDatabase.userDataDao.findAppSetting();
    expect(saved?.accentColor, 'blue');
  });

  testWidgets('备份页面展示导入导出和历史状态', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    BackupBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: BackupPage()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '数据备份'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);
    expect(find.byTooltip('返回首页'), findsOneWidget);
    expect(find.text('导出备份'), findsNWidgets(2));
    expect(find.text('⚠ 导入前请确认备份文件来源可靠。'), findsOneWidget);
    expect(find.text('选择备份文件'), findsOneWidget);
    expect(find.text('还没有备份操作记录。'), findsOneWidget);
  });

  testWidgets('发音练习在未配置第三方评测时显示明确状态', (tester) async {
    final dependencies = await createTestAppDependencies();
    addTearDown(() async {
      Get.reset();
      await dependencies.close();
    });
    InitialBinding(dependencies).dependencies();
    PronunciationPracticeBinding().dependencies();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: PronunciationPracticePage(expectedWord: 'academic'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('尚未配置第三方评测'), findsOneWidget);
    expect(find.text('前往配置'), findsOneWidget);
  });
}

Finder _expectPracticeFavoriteInAppBar(WidgetTester tester) {
  final favorite = find.byKey(const ValueKey('practice-favorite'));
  expect(favorite, findsOneWidget);
  expect(find.text('收藏当前单词'), findsNothing);
  expect(find.text('已收藏当前单词'), findsNothing);

  final appBarRect = tester.getRect(find.byType(AppBar));
  final favoriteRect = tester.getRect(favorite);
  expect(favoriteRect.top, greaterThanOrEqualTo(appBarRect.top));
  expect(favoriteRect.bottom, lessThanOrEqualTo(appBarRect.bottom));
  expect(favoriteRect.center.dx, greaterThan(appBarRect.center.dx));
  return favorite;
}

Future<void> _seedWordDetailsContent(ContentDatabase database) async {
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
        mnemonic: const drift.Value('academy 的形容词'),
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
        audioUkAsset: const drift.Value('assets/audio/uk/academic.mp3'),
        audioUsAsset: const drift.Value('assets/audio/us/academic.mp3'),
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
        source: const drift.Value('Cambridge IELTS'),
        location: const drift.Value('Test 1'),
      ),
    );
  });
}

Future<void> _seedPracticeContent(ContentDatabase database) async {
  const words = ['wheat', 'whale', 'wheel', 'world', 'woman'];
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
    for (var index = 1; index <= 5; index++) {
      final word = words[index - 1];
      batch.insert(
        database.words,
        WordsCompanion.insert(
          id: drift.Value(index),
          word: word,
          translationZh: drift.Value('释义 $index'),
          definitionEn: drift.Value('definition $index'),
          occurrences: 200 - index,
          frequencyGroupId: 1,
          firstLetter: 'W',
          audioUkAsset: drift.Value('assets/audio/uk/$word.mp3'),
        ),
      );
      batch.insert(
        database.sentences,
        SentencesCompanion.insert(
          id: drift.Value(100 + index),
          wordId: index,
          targetForm: word,
          sentenceEn: 'We practice $word every day.',
          translationZh: drift.Value('我们每天练习 $word。'),
        ),
      );
    }
  });
}

final class _WidgetStatisticsRepository implements StatisticsRepository {
  bool fail = false;

  @override
  Future<LearningDashboardStatistics> loadDashboard({
    int calendarDays = 365,
    int trendDays = 30,
  }) async {
    if (fail) {
      throw Exception('statistics unavailable');
    }
    final day = DailyLearningStatistics(
      date: LocalDate(year: 2026, month: 8, day: 15),
      eventCount: 1,
      answeredCount: 1,
      correctCount: 1,
    );
    return LearningDashboardStatistics(
      generatedAtUtc: DateTime.utc(2026, 8, 15),
      today: day,
      dailyGoal: 10,
      currentStreakDays: 1,
      dueReviewCount: 0,
      masteredWordCount: 0,
      learningWordCount: 1,
      favoriteWordCount: 0,
      favoriteSentenceCount: 0,
      calendarDays: [day],
      accuracyTrend: [day],
    );
  }
}
