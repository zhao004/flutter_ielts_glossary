import '../../models/domain/local_date.dart';

/// 在 UTC 持久化时间与设备本地日之间转换，测试可替换固定时区。
abstract interface class LocalTimeResolver {
  DateTime toLocal(DateTime utcTime);

  DateTime startOfDayUtc(LocalDate localDate);
}

/// 使用设备当前时区及其夏令时规则解析本地日期边界。
final class SystemLocalTimeResolver implements LocalTimeResolver {
  const SystemLocalTimeResolver();

  @override
  DateTime toLocal(DateTime utcTime) => utcTime.toUtc().toLocal();

  @override
  DateTime startOfDayUtc(LocalDate localDate) {
    return DateTime(localDate.year, localDate.month, localDate.day).toUtc();
  }
}

/// 使用固定 UTC 偏移构造可重复的本地日期测试环境。
final class FixedOffsetLocalTimeResolver implements LocalTimeResolver {
  const FixedOffsetLocalTimeResolver(this.offset);

  static const Duration maximumOffset = Duration(hours: 14);

  final Duration offset;

  void _validateOffset() {
    if (offset < -maximumOffset || offset > maximumOffset) {
      throw ArgumentError.value(offset, 'offset', '时区偏移必须在 UTC-14 至 UTC+14 之间');
    }
  }

  @override
  DateTime toLocal(DateTime utcTime) {
    _validateOffset();
    return utcTime.toUtc().add(offset);
  }

  @override
  DateTime startOfDayUtc(LocalDate localDate) {
    _validateOffset();
    return DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    ).subtract(offset);
  }
}
