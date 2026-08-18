import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/app_bottom_navigation.dart';
import '../home/home_page.dart';
import '../review/review_page.dart';
import '../settings/settings_page.dart';
import '../study/study_hub_page.dart';
import '../vocabulary/vocabulary_page.dart';
import 'main_shell_controller.dart';

/// 五个一级入口的持久外壳：底部导航固定，正文使用懒加载 IndexedStack
/// 保留每个页面与 Logic 的状态，避免切换时重建页面导致的闪动。
final class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

final class _MainShellPageState extends State<MainShellPage> {
  static final List<Widget Function()> _tabBuilders = [
    () => const HomePage(),
    () => const VocabularyPage(),
    () => const StudyHubPage(),
    () => const ReviewPage(),
    () => const SettingsPage(),
  ];

  final List<Widget?> _tabs = List<Widget?>.filled(_tabBuilders.length, null);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainShellController>(
      builder: (controller) {
        final index = controller.currentIndex;
        // 只有首次访问时才构建对应一级页面，构建后常驻以保留状态。
        _tabs[index] ??= _tabBuilders[index]();
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              for (var i = 0; i < _tabBuilders.length; i++)
                _tabs[i] ?? const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: index,
            onTabSelected: controller.select,
          ),
        );
      },
    );
  }
}
