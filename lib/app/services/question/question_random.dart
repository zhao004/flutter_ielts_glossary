import 'dart:math';

/// 出题算法只依赖整数随机能力，测试可注入固定种子实现完全复现。
abstract interface class QuestionRandomSource {
  int nextInt(int max);
}

/// 使用 Dart 标准随机数实现生产与种子测试两种模式。
final class DartQuestionRandomSource implements QuestionRandomSource {
  DartQuestionRandomSource({int? seed}) : _random = Random(seed);

  final Random _random;

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', '随机上界必须大于 0');
    }
    return _random.nextInt(max);
  }
}

/// 使用部分 Fisher-Yates 洗牌完成无放回抽样，避免重复抽取和无限重试。
final class QuestionRandomSampler {
  const QuestionRandomSampler(this.randomSource);

  final QuestionRandomSource randomSource;

  List<T> sampleWithoutReplacement<T>(Iterable<T> candidates, int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', '抽样数量不能小于 0');
    }
    final pool = candidates.toList(growable: false);
    if (count > pool.length) {
      throw RangeError.range(count, 0, pool.length, 'count', '抽样数量超过候选池');
    }
    final mutablePool = pool.toList(growable: true);
    for (var index = 0; index < count; index++) {
      final swapIndex =
          index + randomSource.nextInt(mutablePool.length - index);
      final current = mutablePool[index];
      mutablePool[index] = mutablePool[swapIndex];
      mutablePool[swapIndex] = current;
    }
    return List<T>.unmodifiable(mutablePool.take(count));
  }

  List<T> shuffled<T>(Iterable<T> candidates) {
    final pool = candidates.toList(growable: false);
    return sampleWithoutReplacement(pool, pool.length);
  }

  T pick<T>(Iterable<T> candidates) {
    final pool = candidates.toList(growable: false);
    if (pool.isEmpty) {
      throw StateError('不能从空候选池中抽取元素');
    }
    return pool[randomSource.nextInt(pool.length)];
  }
}
