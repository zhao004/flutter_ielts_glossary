/// 只提供单调递增耗时，不受设备时区或系统时间调整影响。
abstract interface class MonotonicClock {
  Duration get elapsed;
}

/// 使用 Dart Stopwatch 提供生产环境单调时钟。
final class StopwatchMonotonicClock implements MonotonicClock {
  StopwatchMonotonicClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
