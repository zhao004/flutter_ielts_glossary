import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/domain/pronunciation_assessment_config.dart';
import '../models/domain/pronunciation_assessment_platform.dart';
import 'pronunciation_assessment_config_repository.dart';

typedef AssessmentConfigDirectoryProvider = Future<Directory> Function();

/// 把第三方发音评测配置保存在应用私有目录的 JSON 文件中。
///
/// 选择文件而非用户库表，是为了让凭据天然不进入备份导出，
/// 也避免为敏感字段扩展现有备份协议。
final class LocalPronunciationAssessmentConfigRepository
    implements PronunciationAssessmentConfigRepository {
  LocalPronunciationAssessmentConfigRepository({
    AssessmentConfigDirectoryProvider? directoryProvider,
  }) : directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const String configFileName = 'pronunciation_assessment_config.json';
  static const int maxCredentialLength = 128;
  static const int maxAppIdLength = 64;

  final AssessmentConfigDirectoryProvider directoryProvider;

  @override
  Future<PronunciationAssessmentConfig> load() async {
    final directory = await directoryProvider();
    final file = File(p.join(directory.path, configFileName));
    if (!await file.exists()) {
      return PronunciationAssessmentConfig.defaults();
    }
    final String content;
    try {
      content = await file.readAsString();
    } on FileSystemException catch (error) {
      throw UnsupportedAssessmentConfigException(
        '配置文件读取失败：${error.osError?.errorCode ?? 'unknown'}',
      );
    }
    return _decode(content);
  }

  @override
  Future<PronunciationAssessmentConfig> save(
    PronunciationAssessmentConfig config,
  ) async {
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
      throw UnsupportedAssessmentConfigException(
        '配置文件写入失败：${error.osError?.errorCode ?? 'unknown'}',
      );
    }
    return config;
  }

  String _encode(PronunciationAssessmentConfig config) {
    return jsonEncode({
      'platform': config.platform.name,
      'xfyunAppId': config.xfyunAppId,
      'xfyunApiKey': config.xfyunApiKey,
      'xfyunApiSecret': config.xfyunApiSecret,
      'youdaoAppKey': config.youdaoAppKey,
      'youdaoAppSecret': config.youdaoAppSecret,
    });
  }

  PronunciationAssessmentConfig _decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const UnsupportedAssessmentConfigException('配置文件不是合法 JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const UnsupportedAssessmentConfigException('配置文件必须是 JSON 对象');
    }
    const keys = {
      'platform',
      'xfyunAppId',
      'xfyunApiKey',
      'xfyunApiSecret',
      'youdaoAppKey',
      'youdaoAppSecret',
    };
    if (decoded.keys.toSet().length != keys.length ||
        !decoded.keys.toSet().containsAll(keys)) {
      throw const UnsupportedAssessmentConfigException('配置文件字段集合不匹配协议');
    }
    final platform = _decodePlatform(decoded['platform']);
    final config = PronunciationAssessmentConfig(
      platform: platform,
      xfyunAppId: _readText(decoded, 'xfyunAppId', max: maxAppIdLength),
      xfyunApiKey: _readText(decoded, 'xfyunApiKey', max: maxCredentialLength),
      xfyunApiSecret: _readText(
        decoded,
        'xfyunApiSecret',
        max: maxCredentialLength,
      ),
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
    );
    _validate(config);
    return config;
  }

  PronunciationAssessmentPlatform _decodePlatform(Object? value) {
    if (value is! String) {
      throw const UnsupportedAssessmentConfigException('platform 必须是字符串');
    }
    final match = PronunciationAssessmentPlatform.values.where(
      (platform) => platform.name == value,
    );
    if (match.isEmpty) {
      throw const UnsupportedAssessmentConfigException('platform 不是受支持的值');
    }
    return match.first;
  }

  String _readText(Map<String, Object?> map, String key, {required int max}) {
    final value = map[key];
    if (value is! String || value.length > max) {
      throw UnsupportedAssessmentConfigException('$key 字符串长度或格式无效');
    }
    return value;
  }

  void _validate(PronunciationAssessmentConfig config) {
    if (config.xfyunAppId.length > maxAppIdLength ||
        config.xfyunApiKey.length > maxCredentialLength ||
        config.xfyunApiSecret.length > maxCredentialLength ||
        config.youdaoAppKey.length > maxCredentialLength ||
        config.youdaoAppSecret.length > maxCredentialLength) {
      throw const UnsupportedAssessmentConfigException('评测配置字段长度超出允许范围');
    }
  }
}
