import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/domain/tts_config.dart';
import '../models/domain/tts_platform.dart';
import 'tts_config_repository.dart';

typedef TtsConfigDirectoryProvider = Future<Directory> Function();

/// 把第三方 TTS 配置保存在应用私有目录的 JSON 文件中。
///
/// 选择文件而非用户库表，是为了让凭据天然不进入备份导出。
final class LocalTtsConfigRepository implements TtsConfigRepository {
  LocalTtsConfigRepository({TtsConfigDirectoryProvider? directoryProvider})
    : directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const String configFileName = 'tts_config.json';
  static const int maxCredentialLength = 128;
  static const int maxAppIdLength = 64;
  static const int maxVoiceLength = 64;

  final TtsConfigDirectoryProvider directoryProvider;

  @override
  Future<TtsConfig> load() async {
    final directory = await directoryProvider();
    final file = File(p.join(directory.path, configFileName));
    if (!await file.exists()) {
      return TtsConfig.defaults();
    }
    final String content;
    try {
      content = await file.readAsString();
    } on FileSystemException catch (error) {
      throw UnsupportedTtsConfigException(
        '配置文件读取失败：${error.osError?.errorCode ?? 'unknown'}',
      );
    }
    return _decode(content);
  }

  @override
  Future<TtsConfig> save(TtsConfig config) async {
    _validate(config);
    final directory = await directoryProvider();
    await directory.create(recursive: true);
    final target = File(p.join(directory.path, configFileName));
    final temporary = File(
      p.join(
        directory.path,
        '.$configFileName.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await temporary.writeAsString(_encode(config), flush: true);
      await temporary.rename(target.path);
    } on FileSystemException catch (error) {
      try {
        if (await temporary.exists()) {
          await temporary.delete();
        }
      } on FileSystemException {
        // 保留原始写入错误。
      }
      throw UnsupportedTtsConfigException(
        '配置文件写入失败：${error.osError?.errorCode ?? 'unknown'}',
      );
    }
    return config;
  }

  String _encode(TtsConfig config) {
    return jsonEncode({
      'platform': config.platform.name,
      'xfyunAppId': config.xfyunAppId,
      'xfyunApiKey': config.xfyunApiKey,
      'xfyunApiSecret': config.xfyunApiSecret,
      'xfyunVoice': config.xfyunVoice,
      'youdaoAppKey': config.youdaoAppKey,
      'youdaoAppSecret': config.youdaoAppSecret,
      'youdaoUsVoiceName': config.youdaoUsVoiceName,
      'youdaoUkVoiceName': config.youdaoUkVoiceName,
      'speed': config.speed,
      'volume': config.volume,
      'pitch': config.pitch,
    });
  }

  TtsConfig _decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const UnsupportedTtsConfigException('配置文件不是合法 JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const UnsupportedTtsConfigException('配置文件必须是 JSON 对象');
    }
    const currentKeys = {
      'platform',
      'xfyunAppId',
      'xfyunApiKey',
      'xfyunApiSecret',
      'xfyunVoice',
      'youdaoAppKey',
      'youdaoAppSecret',
      'youdaoUsVoiceName',
      'youdaoUkVoiceName',
      'speed',
      'volume',
      'pitch',
    };
    const legacyKeys = {
      'platform',
      'xfyunAppId',
      'xfyunApiKey',
      'xfyunApiSecret',
      'xfyunVoice',
      'youdaoAppKey',
      'youdaoAppSecret',
      'youdaoVoice',
      'speed',
      'volume',
      'pitch',
    };
    final actualKeys = decoded.keys.toSet();
    final isCurrent =
        actualKeys.length == currentKeys.length &&
        actualKeys.containsAll(currentKeys);
    final isLegacy =
        actualKeys.length == legacyKeys.length &&
        actualKeys.containsAll(legacyKeys);
    if (!isCurrent && !isLegacy) {
      throw const UnsupportedTtsConfigException('配置文件字段集合不匹配协议');
    }
    final String youdaoUsVoiceName;
    final String youdaoUkVoiceName;
    if (isCurrent) {
      youdaoUsVoiceName = _readText(
        decoded,
        'youdaoUsVoiceName',
        max: maxVoiceLength,
      );
      youdaoUkVoiceName = _readText(
        decoded,
        'youdaoUkVoiceName',
        max: maxVoiceLength,
      );
    } else {
      final legacyVoice = _readText(
        decoded,
        'youdaoVoice',
        max: maxVoiceLength,
      ).trim();
      // 旧版文档误用 female/male；迁移时替换为官方词典音色。
      youdaoUsVoiceName =
          legacyVoice.isEmpty ||
              legacyVoice == 'female' ||
              legacyVoice == 'male'
          ? 'youmeimei'
          : legacyVoice;
      youdaoUkVoiceName = 'youyingying';
    }
    final config = TtsConfig(
      platform: _decodePlatform(decoded['platform']),
      xfyunAppId: _readText(decoded, 'xfyunAppId', max: maxAppIdLength),
      xfyunApiKey: _readText(decoded, 'xfyunApiKey', max: maxCredentialLength),
      xfyunApiSecret: _readText(
        decoded,
        'xfyunApiSecret',
        max: maxCredentialLength,
      ),
      xfyunVoice: _readText(decoded, 'xfyunVoice', max: maxVoiceLength),
      youdaoAppKey: _readText(
        decoded,
        'youdaoAppKey',
        max: maxCredentialLength,
      ),
      youdaoAppSecret: _readText(
        decoded,
        'youdaoAppSecret',
        max: maxCredentialLength,
      ),
      youdaoUsVoiceName: youdaoUsVoiceName,
      youdaoUkVoiceName: youdaoUkVoiceName,
      speed: _readInt(decoded, 'speed'),
      volume: _readInt(decoded, 'volume'),
      pitch: _readInt(decoded, 'pitch'),
    );
    _validate(config);
    return config;
  }

  TtsPlatform _decodePlatform(Object? value) {
    if (value is! String) {
      throw const UnsupportedTtsConfigException('platform 必须是字符串');
    }
    final match = TtsPlatform.values.where(
      (platform) => platform.name == value,
    );
    if (match.isEmpty) {
      throw const UnsupportedTtsConfigException('platform 不是受支持的值');
    }
    return match.first;
  }

  String _readText(Map<String, Object?> map, String key, {required int max}) {
    final value = map[key];
    if (value is! String || value.length > max) {
      throw UnsupportedTtsConfigException('$key 字符串长度或格式无效');
    }
    return value;
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int || value < 0 || value > 100) {
      throw UnsupportedTtsConfigException('$key 必须是 0-100 的整数');
    }
    return value;
  }

  void _validate(TtsConfig config) {
    if (config.xfyunAppId.length > maxAppIdLength ||
        config.xfyunApiKey.length > maxCredentialLength ||
        config.xfyunApiSecret.length > maxCredentialLength ||
        config.xfyunVoice.length > maxVoiceLength ||
        config.youdaoAppKey.length > maxCredentialLength ||
        config.youdaoAppSecret.length > maxCredentialLength ||
        config.youdaoUsVoiceName.length > maxVoiceLength ||
        config.youdaoUkVoiceName.length > maxVoiceLength ||
        config.speed < 0 ||
        config.speed > 100 ||
        config.volume < 0 ||
        config.volume > 100 ||
        config.pitch < 0 ||
        config.pitch > 100) {
      throw const UnsupportedTtsConfigException('TTS 配置字段长度或取值超出范围');
    }
  }
}
