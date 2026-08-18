import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/tts_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/tts_platform.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_tts_config_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/tts_config_repository.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tts-config-test-');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  LocalTtsConfigRepository repository() {
    return LocalTtsConfigRepository(directoryProvider: () async => directory);
  }

  test('无配置文件时返回未配置的默认值', () async {
    final config = await repository().load();
    expect(config.platform, TtsPlatform.off);
  });

  test('保存后读取恢复完整配置', () async {
    const config = TtsConfig(
      platform: TtsPlatform.xfyun,
      xfyunAppId: 'app-123',
      xfyunApiKey: 'api-key',
      xfyunApiSecret: 'api-secret',
      xfyunVoice: 'henry',
      speed: 60,
      volume: 55,
      pitch: 40,
    );

    await repository().save(config);
    final loaded = await repository().load();

    expect(loaded.platform, TtsPlatform.xfyun);
    expect(loaded.xfyunAppId, 'app-123');
    expect(loaded.xfyunApiKey, 'api-key');
    expect(loaded.xfyunApiSecret, 'api-secret');
    expect(loaded.xfyunVoice, 'henry');
    expect(loaded.speed, 60);
    expect(loaded.volume, 55);
    expect(loaded.pitch, 40);
  });

  test('保存并恢复有道美式与英式 voiceName', () async {
    const config = TtsConfig(
      platform: TtsPlatform.youdao,
      youdaoAppKey: 'app-key',
      youdaoAppSecret: 'app-secret',
      youdaoUsVoiceName: 'youmeimei',
      youdaoUkVoiceName: 'youyingying',
    );

    await repository().save(config);
    final loaded = await repository().load();

    expect(loaded.youdaoUsVoiceName, 'youmeimei');
    expect(loaded.youdaoUkVoiceName, 'youyingying');
  });

  test('读取旧版 voice 配置时迁移为官方双口音 voiceName', () async {
    final file = File(
      '${directory.path}/${LocalTtsConfigRepository.configFileName}',
    );
    await file.writeAsString(
      jsonEncode({
        'platform': 'youdao',
        'xfyunAppId': '',
        'xfyunApiKey': '',
        'xfyunApiSecret': '',
        'xfyunVoice': 'catherine',
        'youdaoAppKey': 'app-key',
        'youdaoAppSecret': 'app-secret',
        'youdaoVoice': 'female',
        'speed': 50,
        'volume': 50,
        'pitch': 50,
      }),
    );

    final loaded = await repository().load();

    expect(loaded.youdaoUsVoiceName, 'youmeimei');
    expect(loaded.youdaoUkVoiceName, 'youyingying');
    await repository().save(loaded);
    final migrated = jsonDecode(await file.readAsString()) as Map;
    expect(migrated, isNot(contains('youdaoVoice')));
    expect(migrated['youdaoUsVoiceName'], 'youmeimei');
    expect(migrated['youdaoUkVoiceName'], 'youyingying');
  });

  test('畸形 JSON 或超限字段抛出稳定异常', () async {
    final file = File(
      '${directory.path}/${LocalTtsConfigRepository.configFileName}',
    );
    await file.writeAsString('{ not valid json');
    await expectLater(
      repository().load(),
      throwsA(isA<UnsupportedTtsConfigException>()),
    );

    await expectLater(
      repository().save(
        TtsConfig(
          platform: TtsPlatform.youdao,
          youdaoAppKey: 'key',
          youdaoAppSecret: 's' * 200,
        ),
      ),
      throwsA(isA<UnsupportedTtsConfigException>()),
    );

    await expectLater(
      repository().save(TtsConfig(platform: TtsPlatform.xfyun, speed: 101)),
      throwsA(isA<UnsupportedTtsConfigException>()),
    );
  });
}
