/// 所有业务时间都通过此接口获取，避免领域规则依赖真实系统时间。
abstract interface class AppClock {
  DateTime nowUtc();
}

/// 生产环境 UTC 时钟。
final class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
