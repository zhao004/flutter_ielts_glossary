/// 约束词库中本地音频资产的虚拟路径，供播放与构建校验共用。
final class AudioAssetPathPolicy {
  const AudioAssetPathPolicy();

  static const String assetRoot = 'assets/audio/';
  static const Set<String> supportedAccents = {'uk', 'us'};
  static const Set<String> supportedExtensions = {'.mp3', '.m4a', '.aac'};

  /// 校验资源路径，并在传入口音时确保目录与数据库字段一致。
  bool isAllowed(String? path, {String? accent}) {
    if (path == null || path.isEmpty || path.length > 255) {
      return false;
    }
    if (!path.startsWith(assetRoot) ||
        path.contains('..') ||
        path.contains('\\') ||
        path.contains('//')) {
      return false;
    }

    final relativePath = path.substring(assetRoot.length).split('/');
    if (relativePath.length < 2 ||
        relativePath.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        ) ||
        !supportedAccents.contains(relativePath.first) ||
        (accent != null &&
            (!supportedAccents.contains(accent) ||
                relativePath.first != accent))) {
      return false;
    }

    final extensionStart = path.lastIndexOf('.');
    if (extensionStart <= assetRoot.length ||
        extensionStart == path.length - 1) {
      return false;
    }
    final extension = path.substring(extensionStart).toLowerCase();
    return supportedExtensions.contains(extension);
  }
}
