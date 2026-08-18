import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// 集中实现有道智云 HTTP API 共用的 UUID salt 与截断签名规则。
final class YoudaoApiSigner {
  const YoudaoApiSigner._();

  /// 每次请求生成新的 UUID v4，满足服务端防重放要求。
  static String createSalt() => const Uuid().v4();

  /// 按 `sha256(appKey + input + salt + curtime + appSecret)` 生成签名。
  static String sign({
    required String appKey,
    required String appSecret,
    required String query,
    required String salt,
    required String curtime,
  }) {
    final input = query.length <= 20
        ? query
        : '${query.substring(0, 10)}'
              '${query.length}'
              '${query.substring(query.length - 10)}';
    return sha256
        .convert(utf8.encode('$appKey$input$salt$curtime$appSecret'))
        .toString();
  }
}
