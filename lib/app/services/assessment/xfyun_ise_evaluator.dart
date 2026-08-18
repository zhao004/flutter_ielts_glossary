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
      throw const PronunciationEvaluationException(
        'invalid_text',
        '参考文本长度无效',
      );
    }
    if (request.pcmBytes.isEmpty) {
      throw const PronunciationEvaluationException(
        'empty_audio',
        '录音为空，无法评测',
      );
    }

    final url = _buildWebSocketUrl();
    final completer = Completer<PronunciationScore>();
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(url).timeout(timeout);
      final score = await _runSession(socket, normalizedText, request.pcmBytes)
          .timeout(timeout);
      completer.complete(score);
    } on Object catch (error) {
      throw _toException(error);
    } finally {
      try {
        await socket?.close();
      } on Object {
        // 连接已失败时忽略关闭错误。
      }
    }
    return completer.future;
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
        final score = _tryParseScore(message);
        if (score != null) {
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(score);
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
    if (message is! String) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final code = decoded['code'];
    if (code is int && code != 0) {
      throw PronunciationEvaluationException(
        'xfyun_$code',
        '讯飞评测失败（$code）',
      );
    }
    final outerData = decoded['data'];
    if (outerData is! Map<String, Object?>) {
      return null;
    }
    final innerData = outerData['data'];
    final result = innerData is Map<String, Object?> ? innerData['result'] : null;
    final scoreMap = _asScoreMap(result);
    if (scoreMap == null) {
      return null;
    }
    return PronunciationScore(
      totalScore: _readScore(scoreMap, 'total_score'),
      accuracyScore: _readScore(scoreMap, 'accuracy_score'),
      fluencyScore: _readScore(scoreMap, 'fluency_score'),
      integrityScore: _readScore(scoreMap, 'integrity_score'),
    );
  }

  Map<String, Object?>? _asScoreMap(Object? result) {
    if (result is Map<String, Object?>) {
      return result;
    }
    if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map<String, Object?>) {
          return decoded;
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  double _readScore(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is num) {
      return value.toDouble().clamp(0, 100);
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed.clamp(0, 100);
      }
    }
    throw const PronunciationEvaluationException(
      'malformed_result',
      '讯飞评测返回缺少评分字段',
    );
  }

  String _buildWebSocketUrl() {
    final date = _httpDate(DateTime.now().toUtc());
    final signatureOrigin =
        'host: $host\ndate: $date\nGET $path HTTP/1.1';
    final signature = base64Encode(
      Hmac(sha256, utf8.encode(credentials.apiSecret))
          .convert(utf8.encode(signatureOrigin))
          .bytes,
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
      return const PronunciationEvaluationException(
        'timeout',
        '讯飞评测超时',
      );
    }
    return const PronunciationEvaluationException(
      'network_error',
      '讯飞评测网络请求失败',
    );
  }
}
