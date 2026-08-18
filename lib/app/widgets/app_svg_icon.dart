import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma 导出的 SVG 图标路径，统一维护资源名称避免页面散落字符串。
abstract final class AppIconAssets {
  static const String home = 'assets/design/icons/nav_home.svg';
  static const String book = 'assets/design/icons/nav_book.svg';
  static const String zap = 'assets/design/icons/nav_zap.svg';
  static const String clock = 'assets/design/icons/nav_clock.svg';
  static const String user = 'assets/design/icons/nav_user.svg';
  static const String search = 'assets/design/icons/search.svg';
  static const String starOutline = 'assets/design/icons/star_outline.svg';
  static const String starFilled = 'assets/design/icons/star_filled.svg';
  static const String volume = 'assets/design/icons/volume.svg';
  static const String chevronLeft = 'assets/design/icons/chevron_left.svg';
  static const String reviewX = 'assets/design/icons/review_x.svg';
  static const String reviewCheck = 'assets/design/icons/review_check.svg';
  static const String backupBack = 'assets/design/icons/backup_back.svg';
  static const String backupHome = 'assets/design/icons/backup_home.svg';
  static const String backupExport = 'assets/design/icons/backup_export.svg';
  static const String backupImport = 'assets/design/icons/backup_import.svg';
  static const String pronunciationMic =
      'assets/design/icons/pronunciation_mic.svg';
}

/// 渲染 Figma 导出的固定尺寸图标，并提供统一的可选色彩过滤。
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.asset, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final String asset;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
    return SizedBox(width: size, height: size, child: icon);
  }
}
