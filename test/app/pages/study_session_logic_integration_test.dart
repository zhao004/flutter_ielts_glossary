import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_run_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/study_setup_state.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_session_logic.dart';
import 'package:flutter_ielts_glossary/app/pages/study/study_setup_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_settings_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_study_candidate_repository.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';
import 'package:flutter_ielts_glossary/app/services/id/id_generator.dart';
import 'package:flutter_ielts_glossary/app/services/question/question_random.dart';

void main() {
  test('真实内容库与用户库完成随机学习、评级和学习事件闭环', () async {
    final contentDatabase = ContentDatabase.forExecutor(
      NativeDatabase.memory(),
    );
    final userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    final clock = _MutableClock(DateTime.utc(2026, 8, 15, 12));
    await _seedContent(contentDatabase);
    final learningRepository = LocalLearningRepository(
      userDatabase,
      clock: clock,
      idGenerator: _SequenceIdGenerator(),
    );
    final settingsRepository = LocalSettingsRepository(
      userDatabase,
      clock: clock,
    );
    await settingsRepository.update(
      pronunciationAccent: PronunciationAccent.us,
      autoPlayPronunciation: true,
    );
    final favoriteRepository = LocalFavoriteRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
    );
    await favoriteRepository.setWordFavorite(wordId: 1, isFavorite: true);
    final pronunciationService = PronunciationService(
      localPlayer: _NoopLocalAudioPlayer(),
    );
    final sessionLogic = StudySessionLogic(
      studyCandidateRepository: LocalStudyCandidateRepository(
        contentDatabase.contentDao,
        randomSource: DartQuestionRandomSource(seed: 20260815),
      ),
      learningRepository: learningRepository,
      favoriteRepository: favoriteRepository,
      pronunciationService: pronunciationService,
    );
    final setupLogic = StudySetupLogic(
      settingsRepository: settingsRepository,
      studySessionStarter: sessionLogic,
      autoLoad: false,
    );
    addTearDown(() async {
      setupLogic.onClose();
      sessionLogic.onClose();
      await userDatabase.close();
      await contentDatabase.close();
    });

    await setupLogic.load();
    expect(
      setupLogic.state.config?.pronunciationAccent,
      PronunciationAccent.us,
    );
    expect(setupLogic.state.config?.autoPlayPronunciation, isTrue);
    setupLogic.selectFrequencyGroups(const {1});
    setupLogic.setWordCount(3);
    await setupLogic.start();
    expect(setupLogic.state.phase, StudySetupPhase.started);
    expect(sessionLogic.state.phase, StudyRunPhase.answering);
    expect(sessionLogic.state.favoriteWordIds, contains(1));

    for (var index = 0; index < 3; index++) {
      await sessionLogic.flip();
      await sessionLogic.rate(StudyRating.known);
    }

    final states = await userDatabase.select(userDatabase.userWordStates).get();
    final events = await userDatabase.select(userDatabase.learningEvents).get();
    expect(sessionLogic.state.phase, StudyRunPhase.completed);
    expect(states, hasLength(3));
    expect(states.map((state) => state.masteryLevel), everyElement(5));
    expect(events, hasLength(3));
    expect(
      events.map((event) => event.eventType),
      everyElement('study_completed'),
    );
  });
}

Future<void> _seedContent(ContentDatabase database) async {
  await database.batch((batch) {
    batch.insert(
      database.frequencyGroups,
      FrequencyGroupsCompanion.insert(
        id: const Value(1),
        name: '100 次以上',
        rank: 1,
        minOccurrences: 100,
      ),
    );
    batch.insertAll(
      database.words,
      List.generate(
        3,
        (index) => WordsCompanion.insert(
          id: Value(index + 1),
          word: 'word-${index + 1}',
          translationZh: Value('释义 ${index + 1}'),
          occurrences: 100 - index,
          frequencyGroupId: 1,
          firstLetter: 'W',
        ),
      ),
    );
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
}

final class _SequenceIdGenerator implements IdGenerator {
  var _next = 0;

  @override
  String nextId() => 'study-event-${_next++}';
}

final class _NoopLocalAudioPlayer implements LocalAudioPlayer {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {}

  @override
  Future<void> stop() async {}
}
