import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'content_database.dart';

/// 打开已由安装服务校验并复制到应用支持目录的只读词库。
ContentDatabase openInstalledContentDatabase({
  Directory? applicationSupportDirectory,
}) {
  return ContentDatabase.forExecutor(
    driftDatabase(
      name: ContentDatabase.databaseName,
      native: DriftNativeOptions(
        databaseDirectory: applicationSupportDirectory == null
            ? getApplicationSupportDirectory
            : () async => applicationSupportDirectory,
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON');
          database.execute('PRAGMA query_only = ON');
        },
      ),
    ),
  );
}
