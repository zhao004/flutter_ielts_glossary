import 'dart:async';

/// Logic 持有的周期刷新句柄，离开页面时必须取消。
abstract interface class PeriodicTicker {
  bool get isActive;

  void cancel();
}

/// 隔离 dart:async Timer，测试可以手动触发刷新而不等待真实时间。
abstract interface class PeriodicTickerFactory {
  PeriodicTicker start({
    required Duration interval,
    required void Function() onTick,
  });
}

/// 使用 Timer.periodic 刷新计时展示，最终耗时仍读取单调时钟。
final class DartPeriodicTickerFactory implements PeriodicTickerFactory {
  const DartPeriodicTickerFactory();

  @override
  PeriodicTicker start({
    required Duration interval,
    required void Function() onTick,
  }) {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', '刷新间隔必须大于 0');
    }
    return _DartPeriodicTicker(Timer.periodic(interval, (_) => onTick()));
  }
}

final class _DartPeriodicTicker implements PeriodicTicker {
  _DartPeriodicTicker(this._timer);

  final Timer _timer;

  @override
  bool get isActive => _timer.isActive;

  @override
  void cancel() => _timer.cancel();
}
