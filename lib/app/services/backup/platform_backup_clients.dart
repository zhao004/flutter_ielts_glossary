import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_transfer_service.dart';

/// `file_picker` 适配器；只声明 `.ieltsbackup` 自定义扩展名。
final class FilePickerBackupClient implements BackupPickerClient {
  const FilePickerBackupClient();

  @override
  Future<PickedBackupSource?> pickBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['ieltsbackup'],
    );
    if (file == null) {
      return null;
    }
    final bytes = file.path == null ? await file.readAsBytes() : null;
    final size = bytes?.length ?? await File(file.path!).length();
    return PickedBackupSource(
      name: file.name,
      size: size,
      bytes: bytes,
      path: file.path,
    );
  }
}

/// `share_plus` 适配器；分享结果转换为稳定领域状态。
final class SharePlusBackupClient implements BackupShareClient {
  const SharePlusBackupClient();

  @override
  Future<BackupShareStatus> shareBackup(File file) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        subject: '雅思词汇库学习数据备份',
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => BackupShareStatus.success,
      ShareResultStatus.dismissed => BackupShareStatus.dismissed,
      ShareResultStatus.unavailable => BackupShareStatus.unavailable,
    };
  }
}
