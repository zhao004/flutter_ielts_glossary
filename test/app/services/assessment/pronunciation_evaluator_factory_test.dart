import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_config.dart';
import 'package:flutter_ielts_glossary/app/models/domain/pronunciation_assessment_platform.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/pronunciation_evaluator_factory.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/xfyun_ise_evaluator.dart';
import 'package:flutter_ielts_glossary/app/services/assessment/youdao_assess_evaluator.dart';

void main() {
  const factory = PronunciationEvaluatorFactory();

  test('未选平台或凭据不完整时返回空，回退本地评测', () {
    expect(factory.create(PronunciationAssessmentConfig.defaults()), isNull);
    expect(
      factory.create(
        const PronunciationAssessmentConfig(
          platform: PronunciationAssessmentPlatform.xfyun,
          xfyunAppId: 'app',
        ),
      ),
      isNull,
    );
    expect(
      factory.create(
        const PronunciationAssessmentConfig(
          platform: PronunciationAssessmentPlatform.youdao,
          youdaoAppKey: 'key',
        ),
      ),
      isNull,
    );
  });

  test('凭据完整时创建对应平台的评测器', () {
    expect(
      factory.create(
        const PronunciationAssessmentConfig(
          platform: PronunciationAssessmentPlatform.xfyun,
          xfyunAppId: 'app',
          xfyunApiKey: 'key',
          xfyunApiSecret: 'secret',
        ),
      ),
      isA<XfyunIseEvaluator>(),
    );
    expect(
      factory.create(
        const PronunciationAssessmentConfig(
          platform: PronunciationAssessmentPlatform.youdao,
          youdaoAppKey: 'key',
          youdaoAppSecret: 'secret',
        ),
      ),
      isA<YoudaoAssessEvaluator>(),
    );
  });
}
