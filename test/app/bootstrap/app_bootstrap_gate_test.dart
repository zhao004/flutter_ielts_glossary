import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/bootstrap/app_bootstrap_gate.dart';
import 'package:flutter_ielts_glossary/app/bootstrap/app_dependencies.dart';
import 'package:flutter_ielts_glossary/app/bootstrap/application_bootstrap_service.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  testWidgets('初始化期间显示加载状态，完成后进入应用', (tester) async {
    _setMobileViewport(tester);
    final completer = Completer<AppDependencies>();
    final dependencies = await createTestAppDependencies();
    addTearDown(dependencies.close);
    Future<AppDependencies> initialize({
      ApplicationBootstrapProgressCallback? onProgress,
    }) => completer.future;
    await tester.pumpWidget(
      AppBootstrapGate(initialize: initialize, appBuilder: _readyApp),
    );

    expect(find.text('正在准备本地词库'), findsOneWidget);

    completer.complete(dependencies);
    await tester.pumpAndSettle();

    expect(find.text('应用就绪'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(dependencies.isClosed, isTrue);
  });

  testWidgets('内容复制阶段展示百分比进度', (tester) async {
    _setMobileViewport(tester);
    final completer = Completer<AppDependencies>();
    final dependencies = await createTestAppDependencies();
    addTearDown(dependencies.close);

    Future<AppDependencies> initialize({
      ApplicationBootstrapProgressCallback? onProgress,
    }) {
      onProgress?.call(
        const ApplicationBootstrapProgress(
          stage: ApplicationBootstrapStage.installingContent,
          fraction: 0.5,
        ),
      );
      return completer.future;
    }

    await tester.pumpWidget(
      AppBootstrapGate(initialize: initialize, appBuilder: _readyApp),
    );
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    completer.complete(dependencies);
    await tester.pumpAndSettle();
    expect(find.text('应用就绪'), findsOneWidget);
  });

  testWidgets('初始化失败后显示可操作错误状态并允许重试', (tester) async {
    _setMobileViewport(tester);
    var attempts = 0;
    AppDependencies? dependencies;
    Future<AppDependencies> initialize({
      ApplicationBootstrapProgressCallback? onProgress,
    }) async {
      attempts++;
      if (attempts == 1) {
        throw Exception('test initialization failure');
      }
      return dependencies ??= await createTestAppDependencies();
    }

    await tester.pumpWidget(
      AppBootstrapGate(initialize: initialize, appBuilder: _readyApp),
    );
    await tester.pumpAndSettle();

    expect(find.text('本地词库暂时不可用'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('应用就绪'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(dependencies?.isClosed, isTrue);
  });

  testWidgets('用户库损坏时先确认备份重建，再重新初始化应用', (tester) async {
    _setMobileViewport(tester);
    var attempts = 0;
    var recoveries = 0;
    AppDependencies? dependencies;
    Future<AppDependencies> initialize({
      ApplicationBootstrapProgressCallback? onProgress,
    }) async {
      attempts++;
      if (attempts == 1) {
        throw ApplicationBootstrapException(
          stage: ApplicationBootstrapStage.openingUserDatabase,
          code: 'user_database_open_failed',
          message: '用户学习数据初始化失败',
          recoveryAction: () async {
            recoveries++;
          },
        );
      }
      return dependencies ??= await createTestAppDependencies();
    }

    await tester.pumpWidget(
      AppBootstrapGate(initialize: initialize, appBuilder: _readyApp),
    );
    await tester.pumpAndSettle();

    expect(find.text('本地学习数据需要重建'), findsOneWidget);
    await tester.tap(find.text('备份并重建学习数据'));
    await tester.pumpAndSettle();
    expect(find.text('确认重建学习数据？'), findsOneWidget);
    await tester.tap(find.text('备份并重建'));
    await tester.pumpAndSettle();

    expect(recoveries, 1);
    expect(attempts, 2);
    expect(find.text('应用就绪'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(dependencies?.isClosed, isTrue);
  });
}

Widget _readyApp(AppDependencies dependencies) {
  return const MaterialApp(
    home: Scaffold(body: Center(child: Text('应用就绪'))),
  );
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
