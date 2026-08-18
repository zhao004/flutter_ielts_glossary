import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/content/content_asset_names.dart';
import 'content_asset_reader.dart';

/// 从 Flutter AssetBundle 读取内容资产，并把数据库拆成固定大小的字节块。
final class FlutterContentAssetReader implements ContentAssetReader {
  FlutterContentAssetReader({
    AssetBundle? bundle,
    this.chunkSize = defaultChunkSize,
  }) : bundle = bundle ?? rootBundle {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', '分块大小必须为正整数');
    }
  }

  static const int defaultChunkSize = 1024 * 1024;

  final AssetBundle bundle;
  final int chunkSize;

  @override
  Future<List<int>> readManifestBytes() async {
    final data = await _load(ContentAssetNames.manifestAsset);
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  @override
  Stream<List<int>> readDatabaseBytes() async* {
    final data = await _load(ContentAssetNames.databaseAsset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      yield Uint8List.sublistView(bytes, offset, end);
    }
  }

  Future<ByteData> _load(String assetName) async {
    try {
      return await bundle.load(assetName);
    } on FlutterError {
      throw ContentAssetReadException(
        code: 'missing_content_asset',
        message: '无法读取打包内容资产 $assetName',
      );
    }
  }
}
