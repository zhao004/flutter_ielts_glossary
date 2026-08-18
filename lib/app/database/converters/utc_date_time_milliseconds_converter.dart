import 'package:drift/drift.dart';

/// 在数据库中以 UTC Unix 毫秒保存时间，避免设备时区变化影响业务判断。
class UtcDateTimeMillisecondsConverter extends TypeConverter<DateTime, int> {
  const UtcDateTimeMillisecondsConverter();

  @override
  DateTime fromSql(int fromDb) {
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}
