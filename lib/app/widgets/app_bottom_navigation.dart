import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma 设计稿中的固定五入口导航，中心闪电按钮悬浮于导航栏上沿。
/// 切换动作通过 [onTabSelected] 交给外壳控制器，避免在导航栏内部触发路由跳转。
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  static const _labels = <String>['首页', '词库', '学习', '复习', '我的'];
  static const _icons = <String>['home', 'book', 'zap', 'clock', 'user'];

  @override
  Widget build(BuildContext context) {
    assert(currentIndex >= 0 && currentIndex < _labels.length);
    final theme = Theme.of(context);
    final inactive = theme.appTextTertiary;
    final selected = theme.colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.appCardSurface.withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: theme.appBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppLayout.bottomNavigationHeight,
          child: Row(
            children: List.generate(_labels.length, (index) {
              final isStudy = index == 2;
              return Expanded(
                child: _NavigationDestination(
                  label: _labels[index],
                  iconName: _icons[index],
                  selected: currentIndex == index,
                  isStudy: isStudy,
                  selectedColor: selected,
                  inactiveColor: inactive,
                  onTap: () {
                    if (index != currentIndex) {
                      onTabSelected(index);
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

final class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    required this.label,
    required this.iconName,
    required this.selected,
    required this.isStudy,
    required this.selectedColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final String iconName;
  final bool selected;
  final bool isStudy;
  final Color selectedColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : inactiveColor;
    final heroColors = AppTheme.heroColorsOf(Theme.of(context));
    final tooltip = switch (label) {
      '首页' => '打开首页',
      '词库' => '打开词库',
      '学习' => '开始学习',
      '复习' => '打开复习',
      '我的' => '打开我的',
      _ => label,
    };
    final icon = isStudy
        ? Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [heroColors.start, heroColors.end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.bolt, size: 28, color: heroColors.foreground),
          )
        : Icon(
            switch (iconName) {
              'home' => Icons.home,
              'book' => Icons.book,
              'zap' => Icons.bolt,
              'clock' => Icons.schedule,
              'user' => Icons.person,
              _ => Icons.circle,
            },
            size: 24,
            color: color,
          );
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppLayout.bottomNavigationHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: isStudy ? -20 : 8,
                  left: 0,
                  right: 0,
                  child: Center(child: icon),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 3,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
