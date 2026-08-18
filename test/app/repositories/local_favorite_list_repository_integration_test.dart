import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ielts_glossary/app/database/content/content_database.dart';
import 'package:flutter_ielts_glossary/app/database/user/user_database.dart';
import 'package:flutter_ielts_glossary/app/models/domain/favorite_page.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_content_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_list_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_favorite_repository.dart';
import 'package:flutter_ielts_glossary/app/repositories/local_learning_repository.dart';

void main() {
  late ContentDatabase contentDatabase;
  late UserDatabase userDatabase;

  setUp(() async {
    contentDatabase = ContentDatabase.forExecutor(NativeDatabase.memory());
    userDatabase = UserDatabase.forExecutor(NativeDatabase.memory());
    await contentDatabase.batch((batch) {
      batch.insert(
        contentDatabase.frequencyGroups,
        FrequencyGroupsCompanion.insert(
          id: const Value(1),
          name: '高频',
          rank: 1,
          minOccurrences: 100,
        ),
      );
      batch.insert(
        contentDatabase.words,
        WordsCompanion.insert(
          id: const Value(1),
          word: 'alpha',
          occurrences: 120,
          frequencyGroupId: 1,
          firstLetter: 'A',
        ),
      );
      batch.insert(
        contentDatabase.sentences,
        SentencesCompanion.insert(
          id: const Value(11),
          wordId: 1,
          targetForm: 'alpha',
          sentenceEn: 'Alpha comes first.',
        ),
      );
    });
  });

  tearDown(() async {
    await userDatabase.close();
    await contentDatabase.close();
  });

  test('真实双库组合单词和例句收藏及学习状态', () async {
    final content = LocalContentRepository(contentDatabase.contentDao);
    final favorites = LocalFavoriteRepository(
      contentDatabase.contentDao,
      userDatabase.userDataDao,
    );
    final learning = LocalLearningRepository(userDatabase);
    final repository = LocalFavoriteListRepository(
      favorites,
      content,
      learning,
    );

    await favorites.setWordFavorite(wordId: 1, isFavorite: true);
    await favorites.setSentenceFavorite(sentenceId: 11, isFavorite: true);
    await learning.recordStudyCompletion(wordId: 1);

    final words = await repository.findPage(FavoriteFilter(masteryLevel: 0));
    final sentences = await repository.findPage(
      FavoriteFilter(type: FavoriteCollectionType.sentences),
    );

    expect(words.items, hasLength(1));
    expect((words.items.single as FavoriteWordItem).word.word, 'alpha');
    expect(
      (words.items.single as FavoriteWordItem).learningState?.masteryLevel,
      0,
    );
    expect(sentences.items, hasLength(1));
    expect((sentences.items.single as FavoriteSentenceItem).sentence.id, 11);
  });
}
