import 'package:get/get.dart';

import 'app_route_names.dart';
import '../pages/shell/main_shell_binding.dart';
import '../pages/shell/main_shell_page.dart';
import '../pages/word_details/word_details_binding.dart';
import '../pages/word_details/word_details_page.dart';
import '../pages/study/study_binding.dart';
import '../pages/study/study_page.dart';
import '../pages/practice/practice_binding.dart';
import '../pages/practice/practice_page.dart';
import '../models/domain/question_config.dart';
import '../pages/favorites/favorites_binding.dart';
import '../pages/favorites/favorites_page.dart';
import '../pages/statistics/statistics_binding.dart';
import '../pages/statistics/statistics_page.dart';
import '../pages/data_backup/backup_binding.dart';
import '../pages/data_backup/backup_page.dart';
import '../pages/color_scheme/color_scheme_page.dart';
import '../pages/speech_services_config/speech_services_config_binding.dart';
import '../pages/speech_services_config/speech_services_config_page.dart';
import '../pages/pronunciation_practice/pronunciation_practice_binding.dart';
import '../pages/pronunciation_practice/pronunciation_practice_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: _Paths.home,
      page: () => const MainShellPage(),
      binding: MainShellBinding(),
    ),
    GetPage(
      name: AppRouteNames.wordDetailsPattern,
      page: () {
        final wordId = int.tryParse(Get.parameters['wordId'] ?? '') ?? -1;
        return WordDetailsPage(wordId: wordId);
      },
      binding: WordDetailsBinding(),
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 240),
    ),
    GetPage(
      name: AppRouteNames.studyFlashcards,
      page: () => const StudyPage(),
      binding: StudyBinding(),
    ),
    GetPage(
      name: _Paths.practice,
      page: () => const PracticePage(),
      binding: PracticeBinding(),
    ),
    GetPage(
      name: AppRouteNames.practiceQuiz,
      page: () => const PracticePage(),
      binding: PracticeBinding(
        initialConfig: QuestionConfig.defaultsFor(
          QuestionType.choiceEnglishToChinese,
        ),
      ),
    ),
    GetPage(
      name: AppRouteNames.practiceSpelling,
      page: () => const PracticePage(),
      binding: PracticeBinding(
        initialConfig: QuestionConfig.defaultsFor(QuestionType.spelling),
      ),
    ),
    GetPage(
      name: AppRouteNames.practiceCloze,
      page: () => const PracticePage(),
      binding: PracticeBinding(
        initialConfig: QuestionConfig(
          type: QuestionType.cloze,
          questionCount: 15,
        ),
      ),
    ),
    GetPage(
      name: _Paths.favorites,
      page: () => const FavoritesPage(),
      binding: FavoritesBinding(),
    ),
    GetPage(
      name: _Paths.statistics,
      page: () => const StatisticsPage(),
      binding: StatisticsBinding(),
    ),
    GetPage(
      name: _Paths.dataBackup,
      page: () => const BackupPage(),
      binding: BackupBinding(),
    ),
    GetPage(name: _Paths.colorSchemes, page: () => const ColorSchemePage()),
    GetPage(
      name: _Paths.speechServices,
      page: () => const SpeechServicesConfigPage(),
      binding: SpeechServicesConfigBinding(),
    ),
    GetPage(
      name: _Paths.pronunciation,
      page: () {
        final arguments = Get.arguments;
        final word = arguments is String
            ? arguments
            : arguments is Map
            ? arguments['word']?.toString() ?? ''
            : '';
        final phonetic = arguments is Map
            ? arguments['phonetic']?.toString()
            : null;
        final translation = arguments is Map
            ? arguments['translation']?.toString()
            : null;
        return PronunciationPracticePage(
          expectedWord: word,
          phonetic: phonetic,
          translation: translation,
        );
      },
      binding: PronunciationPracticeBinding(),
    ),
  ];
}
