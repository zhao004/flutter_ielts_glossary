/// 打包内容资产无法读取或流式解码失败。
final class ContentAssetReadException implements Exception {
  const ContentAssetReadException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// 为安装器提供清单字节和数据库字节流，隔离 Flutter AssetBundle。
abstract interface class ContentAssetReader {
  Future<List<int>> readManifestBytes();

  Stream<List<int>> readDatabaseBytes();
}
