import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:flutter_ielts_glossary/app/bootstrap/application_bootstrap_service.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/services/content/content_installation.dart';
import 'package:flutter_ielts_glossary/app/services/user/user_database_recovery.dart';

import '../../support/test_app_dependencies.dart';

void main() {
  test('严格按安装、内容库、用户库顺序完成初始化', () async {
    final events = <String>[];
    final contentDatabase = await createTestContentDatabase();
    final userDatabase = createTestUserDatabase();
    await userDatabase.userDataDao.upsertAppSetting(
      AppSettingsCompanion.insert(
        dailyGoal: 20,
        pronunciationAccent: 'uk',
        autoPlayPronunciation: false,
        themeMode: 'dark',
        accentColor: Value('sky'),
        updatedAt: DateTime.utc(2026, 8, 15),
      ),
    );
    final service = ApplicationBootstrapService(
      contentInstallation: _FakeContentInstallationService(() async {
        events.add('install');
        return createTestInstallResult();
      }),
      openContentDatabase: () {
        events.add('content');
        return contentDatabase;
      },
      openUserDatabase: () {
        events.add('user');
        return userDatabase;
      },
      backupFileStore: createTestBackupFileStore(),
      backupTransferService: createTestBackupTransferService(),
      pronunciationService: createTestPronunciationService(),
      audioRecorder: createTestAudioRecorder(),
      pronunciationAssessmentConfigRepository:
          createTestAssessmentConfigRepository(),
      ttsConfigRepository: createTestTtsConfigRepository(),
    );

    final dependencies = await service.initialize();
    addTearDown(dependencies.close);

    expect(events, ['install', 'content', 'user']);
    expect(dependencies.contentDatabase, same(contentDatabase));
    expect(dependencies.userDatabase, same(userDatabase));
    expect(dependencies.initialThemePreference, AppThemePreference.dark);
    expect(dependencies.initialAccentPreference, FlexScheme.aquaBlue);
  });

  test('用户库打开失败时关闭已经打开的内容库', () async {
    final contentDatabase = await createTestContentDatabase();
    final service = ApplicationBootstrapService(
      contentInstallation: _FakeContentInstallationService(
        () async => createTestInstallResult(),
      ),
      openContentDatabase: () => contentDatabase,
      openUserDatabase: () => throw Exception('test user database failure'),
      backupFileStore: createTestBackupFileStore(),
      backupTransferService: createTestBackupTransferService(),
      pronunciationService: createTestPronunciationService(),
      audioRecorder: createTestAudioRecorder(),
      pronunciationAssessmentConfigRepository:
          createTestAssessmentConfigRepository(),
      ttsConfigRepository: createTestTtsConfigRepository(),
    );

    await expectLater(
      service.initialize(),
      throwsA(
        isA<ApplicationBootstrapException>()
            .having(
              (error) => error.stage,
              'stage',
              ApplicationBootstrapStage.openingUserDatabase,
            )
            .having(
              (error) => error.code,
              'code',
              'openingUserDatabase_failed',
            ),
      ),
    );
    await expectLater(
      contentDatabase.contentDao.findMetadata(),
      throwsA(anything),
    );
  });

  test('缺失内容元数据时不继续打开用户库', () async {
    final contentDatabase = await createTestContentDatabase(
      includeMetadata: false,
    );
    var userOpened = false;
    final service = ApplicationBootstrapService(
      contentInstallation: _FakeContentInstallationService(
        () async => createTestInstallResult(),
      ),
      openContentDatabase: () => contentDatabase,
      openUserDatabase: () {
        userOpened = true;
        return createTestUserDatabase();
      },
      backupFileStore: createTestBackupFileStore(),
      backupTransferService: createTestBackupTransferService(),
      pronunciationService: createTestPronunciationService(),
      audioRecorder: createTestAudioRecorder(),
      pronunciationAssessmentConfigRepository:
          createTestAssessmentConfigRepository(),
      ttsConfigRepository: createTestTtsConfigRepository(),
    );

    await expectLater(
      service.initialize(),
      throwsA(
        isA<ApplicationBootstrapException>().having(
          (error) => error.code,
          'code',
          'missing_content_metadata',
        ),
      ),
    );
    expect(userOpened, isFalse);
  });

  test('内容安装失败时不创建任何数据库连接', () async {
    var contentOpened = false;
    var userOpened = false;
    final service = ApplicationBootstrapService(
      contentInstallation: _FakeContentInstallationService(
        () async => throw const ContentInstallException(
          code: 'missing_content_asset',
          message: 'test missing asset',
        ),
      ),
      openContentDatabase: () {
        contentOpened = true;
        throw Exception('must not open content database');
      },
      openUserDatabase: () {
        userOpened = true;
        throw Exception('must not open user database');
      },
      backupFileStore: createTestBackupFileStore(),
      backupTransferService: createTestBackupTransferService(),
      pronunciationService: createTestPronunciationService(),
      audioRecorder: createTestAudioRecorder(),
      pronunciationAssessmentConfigRepository:
          createTestAssessmentConfigRepository(),
      ttsConfigRepository: createTestTtsConfigRepository(),
    );

    await expectLater(
      service.initialize(),
      throwsA(
        isA<ApplicationBootstrapException>()
            .having(
              (error) => error.stage,
              'stage',
              ApplicationBootstrapStage.installingContent,
            )
            .having((error) => error.code, 'code', 'missing_content_asset'),
      ),
    );
    expect(contentOpened, isFalse);
    expect(userOpened, isFalse);
  });

  test('用户库打开失败时提供先备份再重建的恢复动作', () async {
    final contentDatabase = await createTestContentDatabase();
    final recovery = _FakeUserDatabaseRecovery();
    final service = ApplicationBootstrapService(
      contentInstallation: _FakeContentInstallationService(
        () async => createTestInstallResult(),
      ),
      openContentDatabase: () => contentDatabase,
      openUserDatabase: () => throw Exception('corrupt user database'),
      backupFileStore: createTestBackupFileStore(),
      backupTransferService: createTestBackupTransferService(),
      pronunciationService: createTestPronunciationService(),
      audioRecorder: createTestAudioRecorder(),
      pronunciationAssessmentConfigRepository:
          createTestAssessmentConfigRepository(),
      ttsConfigRepository: createTestTtsConfigRepository(),
      userDatabaseRecovery: recovery,
    );

    ApplicationBootstrapException? captured;
    try {
      await service.initialize();
    } on ApplicationBootstrapException catch (error) {
      captured = error;
    }

    expect(captured?.stage, ApplicationBootstrapStage.openingUserDatabase);
    expect(captured?.code, 'user_database_open_failed');
    expect(captured?.recoveryAction, isNotNull);
    await captured!.recoveryAction!();
    expect(recovery.callCount, 1);
  });
}

final class _FakeContentInstallationService
    implements ContentInstallationService {
  const _FakeContentInstallationService(this.operation);

  final Future<ContentInstallResult> Function() operation;

  @override
  Future<ContentInstallResult> install({
    ContentInstallProgressCallback? onProgress,
  }) => operation();
}

final class _FakeUserDatabaseRecovery implements UserDatabaseRecovery {
  int callCount = 0;

  @override
  Future<UserDatabaseRecoveryResult> backupAndReset() async {
    callCount++;
    return UserDatabaseRecoveryResult(backupFiles: const []);
  }
}
