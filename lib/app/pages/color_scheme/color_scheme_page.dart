import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/domain/app_settings_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_controller.dart';
import '../settings/settings_logic.dart';

/// 主题配色选择页，展示 flex_color_scheme 的全部内置配色。
class ColorSchemePage extends StatelessWidget {
  const ColorSchemePage({super.key});

  /// 可选用色目录，按 flex_color_scheme 内置顺序，排除 Material 基线配色。
  ///
  /// 使用配色映射的枚举键，避免将供展示的 [FlexSchemeData.name] 当作枚举名。
  static final List<FlexScheme> schemes = FlexColor.schemes.entries
      .where(
        (entry) =>
            entry.key != FlexScheme.material &&
            entry.key != FlexScheme.materialHc,
      )
      .map((entry) => entry.key)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主题配色')),
      body: GetBuilder<SettingsLogic>(
        id: SettingsLogic.updateId,
        builder: (logic) {
          final settings = logic.state.settings;
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return _SchemeTile(
                scheme: scheme,
                selected: settings.accentPreference == scheme,
                enabled: !logic.state.isUpdating,
                onTap: () => _select(logic, scheme),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _select(SettingsLogic logic, FlexScheme scheme) async {
    await logic.updateSettings(accentPreference: scheme);
    final saved = logic.state.settings;
    if (saved != null && Get.isRegistered<AppThemeController>()) {
      Get.find<AppThemeController>().apply(
        themePreference: saved.themePreference,
        accentPreference: saved.accentPreference,
      );
    }
  }
}

final class _SchemeTile extends StatelessWidget {
  const _SchemeTile({
    required this.scheme,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final FlexScheme scheme;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = AppTheme.swatchFor(scheme);
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? primary : theme.appBorder,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    color: AppTheme.light(accent: scheme).colorScheme.onPrimary,
                    size: 26,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            scheme.displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? primary : theme.appTextSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
