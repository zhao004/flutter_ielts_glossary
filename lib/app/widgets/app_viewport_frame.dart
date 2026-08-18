import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 将应用内容限制在设计稿的移动端宽度，并在宽屏上提供外层背景。
class AppViewportFrame extends StatelessWidget {
  const AppViewportFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
            minHeight: constraints.maxHeight,
          ),
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.appPageBackground,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(
                      alpha: isDark ? 0.6 : 0.2,
                    ),
                    blurRadius: isDark ? 32 : 60,
                    spreadRadius: isDark ? 0 : 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerLowest,
                theme.colorScheme.surfaceContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(child: content),
        );
      },
    );
  }
}
