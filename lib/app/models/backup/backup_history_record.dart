/// 最近一次导出、导入或自动保护备份的结果摘要。
final class BackupHistoryRecord {
  const BackupHistoryRecord({
    required this.id,
    required this.type,
    required this.fileName,
    required this.summaryJson,
    required this.result,
    required this.occurredAt,
  });

  final String id;
  final String type;
  final String fileName;
  final String summaryJson;
  final String result;
  final DateTime occurredAt;
}
