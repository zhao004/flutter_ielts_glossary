import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'content_installer.dart';
import 'flutter_content_asset_reader.dart';

/// 使用应用支持目录和 Flutter 根资产包创建平台安装器。
Future<ContentInstaller> createPlatformContentInstaller({
  AssetBundle? bundle,
}) async {
  return ContentInstaller(
    applicationSupportDirectory: await getApplicationSupportDirectory(),
    assetReader: FlutterContentAssetReader(bundle: bundle),
  );
}
