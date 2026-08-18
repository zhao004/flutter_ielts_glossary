import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/content/content_asset_names.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_asset_reader.dart';
import 'package:flutter_ielts_glossary/app/services/content/flutter_content_asset_reader.dart';

void main() {
  test('按固定资产路径读取清单并分块输出数据库', () async {
    final bundle = _MemoryAssetBundle({
      ContentAssetNames.manifestAsset: [1, 2, 3],
      ContentAssetNames.databaseAsset: [4, 5, 6, 7, 8],
    });
    final reader = FlutterContentAssetReader(bundle: bundle, chunkSize: 2);

    final manifest = await reader.readManifestBytes();
    final chunks = await reader.readDatabaseBytes().toList();

    expect(manifest, [1, 2, 3]);
    expect(chunks, [
      [4, 5],
      [6, 7],
      [8],
    ]);
    expect(bundle.requestedKeys, [
      ContentAssetNames.manifestAsset,
      ContentAssetNames.databaseAsset,
    ]);
  });

  test('资产缺失时转换为稳定错误码', () async {
    final reader = FlutterContentAssetReader(bundle: _MemoryAssetBundle({}));

    await expectLater(
      reader.readManifestBytes(),
      throwsA(
        isA<ContentAssetReadException>().having(
          (error) => error.code,
          'code',
          'missing_content_asset',
        ),
      ),
    );
  });
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, List<int>> assets;
  final List<String> requestedKeys = [];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    final bytes = assets[key];
    if (bytes == null) {
      throw FlutterError('Missing test asset');
    }
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
