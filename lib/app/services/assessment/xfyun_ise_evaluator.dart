import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../models/domain/pronunciation_score.dart';
import 'pronunciation_evaluator.dart';

/// 科大讯飞 ISE 语音评测的稳定凭据。
final class XfyunIseCredentials {
  const XfyunIseCredentials({
    required this.appId,
    required this.apiKey,
    required this.apiSecret,
  });

  final String appId;
  final String apiKey;
  final String apiSecret;
}

/// 解析讯飞 ISE 成功帧中的 JSON、Base64 XML 或兼容 JSON 评分结果。
///
/// ISE 的 `read_word` 结果通常位于 `data.data`，其值是 Base64 编码的 XML；
/// 保留 JSON 分支是为了兼容历史代理和测试网关的响应格式。
final class XfyunIseResponseParser {
  const XfyunIseResponseParser({this.category = 'read_word'});

  /// 本次请求使用的 ISE 评测类别，用于选取同名 XML 根评分节点。
  final String category;

  static const _scoreKeys = [
    'total_score',
    'accuracy_score',
    'fluency_score',
    'integrity_score',
  ];

  /// 解析单个 WebSocket 帧；中间帧返回空，错误帧抛出稳定领域异常。
  PronunciationScore? parse(Object? message) {
    if (message is! String) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return null;
    }
    final root = _asMap(decoded);
    if (root == null) {
      return null;
    }
    final codeValue = root['code'];
    if (codeValue != null) {
      final code = int.tryParse(codeValue.toString());
      if (code == null) {
        throw const PronunciationEvaluationException(
          'malformed_result',
          '讯飞评测返回错误码无效',
        );
      }
      if (code != 0) {
        throw PronunciationEvaluationException('xfyun_$code', '讯飞评测失败（$code）');
      }
    }

    final outerData = _asMap(root['data']);
    if (outerData == null) {
      return null;
    }
    final status = _readStatus(outerData);
    final payload = _extractPayload(outerData);
    if (payload == null || payload is String && payload.trim().isEmpty) {
      if (status == 2) {
        throw const PronunciationEvaluationException(
          'malformed_result',
          '讯飞评测完成帧缺少评分数据',
        );
      }
      return null;
    }

    final scoreMap = _scoreMap(payload);
    if (scoreMap == null) {
      if (status == 2) {
        throw const PronunciationEvaluationException(
          'malformed_result',
          '讯飞评测完成帧无法解析评分 XML',
        );
      }
      return null;
    }
    final totalScore = _readScore(scoreMap, 'total_score');
    // read_word 只保证总分；领域模型当前要求四个非空维度，因此缺失维度沿用总分。
    return PronunciationScore(
      totalScore: totalScore,
      accuracyScore:
          _readOptionalScore(scoreMap, 'accuracy_score') ?? totalScore,
      fluencyScore: _readOptionalScore(scoreMap, 'fluency_score') ?? totalScore,
      integrityScore:
          _readOptionalScore(scoreMap, 'integrity_score') ?? totalScore,
    );
  }

  Map<String, Object?>? _scoreMap(Object? payload) {
    final map = _asMap(payload);
    if (map != null) {
      if (map.containsKey('total_score')) {
        return map;
      }
      final nested = map['result'] ?? map['data'];
      if (!identical(nested, payload)) {
        return _scoreMap(nested);
      }
      return null;
    }
    if (payload is! String) {
      return null;
    }
    final text = payload.trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.startsWith('<')) {
      return _xmlScoreMap(text);
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return _scoreMap(decoded);
      }
    } on FormatException {
      // 非 JSON 时继续按 ISE 的 Base64 XML 处理。
    }
    try {
      final encoded = text.replaceAll(RegExp(r'\s+'), '');
      final xml = utf8.decode(base64Decode(encoded), allowMalformed: false);
      return _xmlScoreMap(xml);
    } on Object {
      return null;
    }
  }

  Map<String, Object?>? _xmlScoreMap(String source) {
    final elements = RegExp(
      r'<((?:[A-Za-z_][A-Za-z0-9_.-]*:)?[A-Za-z_][A-Za-z0-9_.-]*)\b([^>]*)>',
      caseSensitive: false,
    );
    Map<String, Object?>? fallback;
    final scalarValues = <String, Object?>{};
    for (final element in elements.allMatches(source)) {
      final map = <String, Object?>{};
      final tagName = _normalizeXmlName(element.group(1)!);
      final attributes = element.group(2)!;
      for (final match in RegExp(
        r'''([A-Za-z_][A-Za-z0-9_.:-]*)\s*=\s*"([^"]*)"''',
      ).allMatches(attributes)) {
        map[_normalizeXmlName(match.group(1)!)] = match.group(2)!;
      }
      for (final match in RegExp(
        r"""([A-Za-z_][A-Za-z0-9_.:-]*)\s*=\s*'([^']*)'""",
      ).allMatches(attributes)) {
        map[_normalizeXmlName(match.group(1)!)] = match.group(2)!;
      }
      if (tagName == category && map.containsKey('total_score')) {
        return map;
      }
      if (_scoreKeys.contains(tagName) && map.containsKey('value')) {
        scalarValues[tagName] = map['value'];
      }
      if (map.containsKey('total_score')) {
        fallback ??= map;
      }
    }

    for (final key in _scoreKeys) {
      final escapedKey = RegExp.escape(key);
      final match = RegExp(
        '<(?:[A-Za-z_][A-Za-z0-9_.-]*:)?$escapedKey\\b[^>]*>\\s*([^<]+?)\\s*</(?:[A-Za-z_][A-Za-z0-9_.-]*:)?$escapedKey\\s*>',
        caseSensitive: false,
      ).firstMatch(source);
      if (match != null) {
        scalarValues[key] = match.group(1)!.trim();
      }
    }
    if (scalarValues.containsKey('total_score')) {
      return scalarValues;
    }
    return fallback;
  }

  String _normalizeXmlName(String value) {
    final separator = value.lastIndexOf(':');
    return (separator < 0 ? value : value.substring(separator + 1))
        .toLowerCase();
  }

  Object? _extractPayload(Map<String, Object?> outerData) {
    final raw = outerData['data'];
    final map = _asMap(raw);
    if (map == null) {
      return raw;
    }
    return map['result'] ?? map['data'];
  }

  int? _readStatus(Map<String, Object?> outerData) {
    final direct = int.tryParse(outerData['status']?.toString() ?? '');
    if (direct != null) {
      return direct;
    }
    final nested = _asMap(outerData['data']);
    return int.tryParse(nested?['status']?.toString() ?? '');
  }

  Map<String, Object?>? _asMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  double _readScore(Map<String, Object?> map, String key) {
    final value = map[key];
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      throw const PronunciationEvaluationException(
        'malformed_result',
        '讯飞评测返回缺少评分字段',
      );
    }
    return parsed.clamp(0, 100).toDouble();
  }

  double? _readOptionalScore(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) {
      return null;
    }
    return _readScore(map, key);
  }
}

/// 使用讯飞开放平台「语音评测（ISE）」WebSocket 接口评分。
final class XfyunIseEvaluator implements PronunciationEvaluatorPort {
  XfyunIseEvaluator({
    required this.credentials,
    this.timeout = const Duration(seconds: 15),
  }) {
    if (credentials.appId.trim().isEmpty ||
        credentials.apiKey.trim().isEmpty ||
        credentials.apiSecret.trim().isEmpty) {
      throw ArgumentError('讯飞评测凭据不完整');
    }
  }

  static const String host = 'ise-api.xfyun.cn';
  static const String path = '/v2/open-ise';
  static const int frameBytes = 1280;

  final XfyunIseCredentials credentials;
  final Duration timeout;

  @override
  Future<PronunciationScore> evaluate(
    PronunciationEvaluationRequest request,
  ) async {
    final normalizedText = request.referenceText.trim();
    if (normalizedText.isEmpty || normalizedText.length > 200) {
      throw const PronunciationEvaluationException('invalid_text', '参考文本长度无效');
    }
    if (request.pcmBytes.isEmpty) {
      throw const PronunciationEvaluationException('empty_audio', '录音为空，无法评测');
    }

    final url = _buildWebSocketUrl();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(url).timeout(timeout);
      return await _runSession(
        socket,
        normalizedText,
        request.pcmBytes,
      ).timeout(timeout);
    } on Object catch (error) {
      throw _toException(error);
    } finally {
      try {
        await socket?.close();
      } on Object {
        // 连接已失败时忽略关闭错误。
      }
    }
  }

  Future<PronunciationScore> _runSession(
    WebSocket socket,
    String text,
    Uint8List pcm,
  ) {
    final resultCompleter = Completer<PronunciationScore>();
    late final StreamSubscription<dynamic> subscription;
    subscription = socket.listen(
      (message) {
        try {
          final score = _tryParseScore(message);
          if (score != null && !resultCompleter.isCompleted) {
            resultCompleter.complete(score);
          }
        } on Object catch (error) {
          if (!resultCompleter.isCompleted) {
            resultCompleter.completeError(error);
          }
        }
      },
      onError: (Object error) {
        if (!resultCompleter.isCompleted) {
          resultCompleter.completeError(error);
        }
      },
      onDone: () {
        if (!resultCompleter.isCompleted) {
          resultCompleter.completeError(
            const PronunciationEvaluationException(
              'connection_closed',
              '评测服务提前断开',
            ),
          );
        }
      },
      cancelOnError: true,
    );

    // 首帧：common + business + 第一段音频。
    final firstChunk = pcm.sublist(
      0,
      pcm.length > frameBytes ? frameBytes : pcm.length,
    );
    socket.add(
      jsonEncode({
        'common': {'app_id': credentials.appId},
        'business': {
          'sub': 'ise',
          'ent': 'en_vip',
          'aue': 'raw',
          'auf': 'audio/L16;rate=16000',
          'cmd': 'ssb',
          'category': 'read_word',
          'text': '\uFEFF$text',
          'tte': 'utf-8',
          'rstcd': 'utf8',
          'rst': 'entirety',
          'ise_unite': '1',
          'extra_ability': 'multi_dimension',
          'plev': '0',
          'aus': 1,
        },
        'data': {
          'status': 0,
          'data': base64Encode(firstChunk),
          'encoding': 'raw',
        },
      }),
    );

    // 后续音频帧。
    var offset = firstChunk.length;
    while (offset < pcm.length) {
      final end = offset + frameBytes > pcm.length
          ? pcm.length
          : offset + frameBytes;
      socket.add(
        jsonEncode({
          'data': {
            'status': 1,
            'data': base64Encode(pcm.sublist(offset, end)),
            'encoding': 'raw',
          },
        }),
      );
      offset = end;
    }

    // 结束帧。
    socket.add(
      jsonEncode({
        'data': {'status': 2},
      }),
    );

    return resultCompleter.future.whenComplete(() => subscription.cancel());
  }

  PronunciationScore? _tryParseScore(Object? message) {
    return const XfyunIseResponseParser().parse(message);
  }

  String _buildWebSocketUrl() {
    final date = _httpDate(DateTime.now().toUtc());
    final signatureOrigin = 'host: $host\ndate: $date\nGET $path HTTP/1.1';
    final signature = base64Encode(
      Hmac(
        sha256,
        utf8.encode(credentials.apiSecret),
      ).convert(utf8.encode(signatureOrigin)).bytes,
    );
    final authorizationOrigin =
        'api_key="${credentials.apiKey}", algorithm="hmac-sha256", '
        'headers="host date request-line", signature="$signature"';
    final authorization = base64Encode(utf8.encode(authorizationOrigin));
    return 'wss://$host$path'
        '?authorization=${Uri.encodeComponent(authorization)}'
        '&date=${Uri.encodeComponent(date)}'
        '&host=$host';
  }

  String _httpDate(DateTime time) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[time.weekday - 1];
    final month = months[time.month - 1];
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$weekday, $day $month ${time.year} $hour:$minute:$second GMT';
  }

  PronunciationEvaluationException _toException(Object error) {
    if (error is PronunciationEvaluationException) {
      return error;
    }
    if (error is TimeoutException) {
      return const PronunciationEvaluationException('timeout', '讯飞评测超时');
    }
    return const PronunciationEvaluationException(
      'network_error',
      '讯飞评测网络请求失败',
    );
  }
}
