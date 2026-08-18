import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/app_settings_state.dart';
import 'package:flutter_ielts_glossary/app/models/domain/learning_event_types.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_rating.dart';
import 'package:flutter_ielts_glossary/app/models/domain/review_run_state.dart';
import 'package:flutter_ielts_glossary/app/pages/review/review_session_logic.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_learning_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_review_queue_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_settings_repository.dart';
import 'package:flutter_ielts_glossary/app/services/audio/audio_playback_service.dart';
import 'package:flutter_ielts_glossary/app/services/clock/app_clock.dart';

void main() {
  test('真实双库完成一次到期复习并更新队列、等级和记忆率', () async {
    final contentDatabase = ContentDatabase.forExecutor(
      NativeDatabase.memory(),
    );
    final userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(() async {
      await userDatabase.close();
      await contentDatabase.close();
    });
    await _seedContent(contentDatabase);
    final clock = _MutableClock(DateTime.utc(2026, 8, 15, 8));
    final learning = LocalLearningRepository(userDatabase, clock: clock);
    final queue = LocalReviewQueueRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
      clock: clock,
    );
    final favoriteRepository = LocalFavoriteRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
    );
    final settingsRepository = LocalSettingsRepository(
      userDatabase,
      clock: clock,
    );
    await settingsRepository.update(
      pronunciationAccent: PronunciationAccent.us,
    );
    await favoriteRepository.setWordFavorite(wordId: 1, isFavorite: true);
    final localPlayer = _RecordingLocalAudioPlayer();
    final logic = ReviewSessionLogic(
      reviewQueueRepository: queue,
      learningRepository: learning,
      favoriteRepository: favoriteRepository,
      settingsRepository: settingsRepository,
      pronunciationService: PronunciationService(localPlayer: localPlayer),
    );
    addTearDown(logic.onClose);

    await learning.recordStudyCompletion(wordId: 1);
    clock.now = clock.now.add(const Duration(hours: 4));
    await logic.start();
    expect(logic.state.phase, ReviewRunPhase.reviewing);
    expect(logic.state.currentItem?.word.word, 'academic');
    expect(logic.state.pronunciationAccent, PronunciationAccent.uk);
    expect(logic.state.isCurrentWordFavorite, isTrue);

    await logic.playCurrentPronunciation(accent: PronunciationAccent.us);
    expect(logic.state.audioSource, PronunciationPlaybackSource.localAsset);
    expect(localPlayer.playedAssets, ['assets/audio/us/academic.mp3']);

    logic.flip();
    await logic.submit(ReviewRating.good);

    final persisted = await userDatabase.userDataDao.findWordState(1);
    final events = await userDatabase.select(userDatabase.learningEvents).get();
    final remainingQueue = await queue.findDueItems();
    expect(logic.state.phase, ReviewRunPhase.completed);
    expect(logic.state.sessionAccuracy, 1);
    expect(logic.state.memoryRate?.value, 1);
    expect(persisted?.masteryLevel, 1);
    expect(persisted?.nextReviewAt, clock.now.add(const Duration(hours: 12)));
    expect(events.last.reviewRating, ReviewRating.good.name);
    expect(events.map((event) => event.eventType), [
      LearningEventTypes.studyCompleted,
      LearningEventTypes.review,
    ]);
    expect(remainingQueue.items, isEmpty);
  });
}

final class _MutableClock implements AppClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now;
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
    batch.insert(
      database.words,
      WordsCompanion.insert(
        id: const Value(1),
        word: 'academic',
        phoneticUs: const Value('/academic-us/'),
        translationZh: const Value('学术的'),
        occurrences: 180,
        frequencyGroupId: 1,
        firstLetter: 'A',
        audioUsAsset: const Value('assets/audio/us/academic.mp3'),
      ),
    );
  });
}

final class _RecordingLocalAudioPlayer implements LocalAudioPlayer {
  final List<String> playedAssets = [];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> playBytes(Uint8List bytes, {String? mimeType}) async {}

  @override
  Future<void> stop() async {}
}
