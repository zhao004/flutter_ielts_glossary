import 'package:uuid/uuid.dart';

/// 为可备份业务记录生成稳定 ID。
abstract interface class IdGenerator {
  String nextId();
}

/// 使用 UUID v4 生成本地业务记录 ID。
final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator([this.uuid = const Uuid()]);

  final Uuid uuid;

  @override
  String nextId() => uuid.v4();
}
