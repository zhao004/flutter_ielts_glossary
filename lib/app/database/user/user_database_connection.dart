import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'user_database.dart';

/// 打开应用支持目录中的可写用户数据库。
UserDatabase openUserDatabase({Directory? applicationSupportDirectory}) {
  return UserDatabase.forExecutor(
    driftDatabase(
      name: UserDatabase.databaseName,
      native: DriftNativeOptions(
        databaseDirectory: applicationSupportDirectory == null
            ? getApplicationSupportDirectory
            : () async => applicationSupportDirectory,
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    ),
  );
}
