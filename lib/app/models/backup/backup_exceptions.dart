/// 备份文件协议、压缩包或字段校验失败。
final class BackupFormatException implements Exception {
  const BackupFormatException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'backup_format_error: $code';
}

/// 备份业务导入阶段产生的稳定错误。
final class BackupImportException implements Exception {
  const BackupImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'backup_import_error: $code';
}
