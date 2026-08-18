import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/initial_binding.dart';
import 'bootstrap/app_dependencies.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme_controller.dart';
import 'widgets/app_viewport_frame.dart';

/// 应用根组件，集中承载路由和后续主题、国际化配置。
class IeltsGlossaryApp extends StatelessWidget {
  const IeltsGlossaryApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppThemeController>(
      init: AppThemeController(
        themePreference: dependencies.initialThemePreference,
        accentPreference: dependencies.initialAccentPreference,
      ),
      builder: (themeController) => GetMaterialApp(
        title: '雅思词汇库',
        debugShowCheckedModeBanner: false,
        theme: themeController.lightTheme,
        darkTheme: themeController.darkTheme,
        themeMode: themeController.themeMode,
        builder: (context, child) =>
            AppViewportFrame(child: child ?? const SizedBox.shrink()),
        initialBinding: InitialBinding(dependencies),
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}
