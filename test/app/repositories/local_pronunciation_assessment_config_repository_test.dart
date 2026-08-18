import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_platform.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_pronunciation_assessment_config_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/pronunciation_assessment_config_repository.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'assessment-config-test-',
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  LocalPronunciationAssessmentConfigRepository repository() {
    return LocalPronunciationAssessmentConfigRepository(
      directoryProvider: () async => directory,
    );
  }

  test('无配置文件时返回默认值（本地评测）', () async {
    final config = await repository().load();
    expect(config.platform, PronunciationAssessmentPlatform.off);
  });

  test('保存后读取恢复完整配置', () async {
    const config = PronunciationAssessmentConfig(
      platform: PronunciationAssessmentPlatform.xfyun,
      xfyunAppId: 'app-123',
      xfyunApiKey: 'api-key',
      xfyunApiSecret: 'api-secret',
      youdaoAppKey: 'unused',
      youdaoAppSecret: 'unused',
    );

    final saved = await repository().save(config);
    expect(saved.platform, PronunciationAssessmentPlatform.xfyun);

    final loaded = await repository().load();
    expect(loaded.platform, PronunciationAssessmentPlatform.xfyun);
    expect(loaded.xfyunAppId, 'app-123');
    expect(loaded.xfyunApiKey, 'api-key');
    expect(loaded.xfyunApiSecret, 'api-secret');
  });

  test('超过允许长度或畸形 JSON 会抛出稳定异常', () async {
    final file = File(
      '${directory.path}/${LocalPronunciationAssessmentConfigRepository.configFileName}',
    );
    await file.writeAsString('{ not valid json');
    await expectLater(
      repository().load(),
      throwsA(isA<UnsupportedAssessmentConfigException>()),
    );

    await file.writeAsString(
      '{"platform":"off","xfyunAppId":"","xfyunApiKey":"","'
      'xfyunApiSecret":"","youdaoAppKey":"","youdaoAppSecret":""}',
    );
    expect(
      (await repository().load()).platform,
      PronunciationAssessmentPlatform.off,
    );

    await expectLater(
      repository().save(
        PronunciationAssessmentConfig(
          platform: PronunciationAssessmentPlatform.youdao,
          youdaoAppKey: 'k' * 200,
        ),
      ),
      throwsA(isA<UnsupportedAssessmentConfigException>()),
    );
  });
}
