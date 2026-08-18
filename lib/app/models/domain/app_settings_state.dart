import 'package:flex_color_scheme/flex_color_scheme.dart';

/// 用户可选的应用主题模式，持久化值由 Repository 集中编码。
enum AppThemePreference { system, light, dark }

/// 主题配色在设置页中的可读名称，取 flex_color_scheme 内置配色。
extension FlexSchemeLabels on FlexScheme {
  /// 稳定协议和日志使用的英文主题标识，即 [FlexScheme.name]。
  String get label => name;

  /// 设置页展示的中文配色名称；未知配色回退到库内置英文描述。
  String get displayLabel {
    const chinese = <String, String>{
      'blue': '蓝色',
      'indigo': '靛蓝',
      'hippieBlue': '嬉皮蓝',
      'aquaBlue': '水蓝',
      'brandBlue': '品牌蓝',
      'deepBlue': '深海蓝',
      'sakura': '樱花粉',
      'mandyRed': '曼迪红',
      'red': '红色',
      'redWine': '酒红',
      'purpleBrown': '紫棕',
      'green': '绿色',
      'money': '青翠',
      'jungle': '丛林绿',
      'greyLaw': '灰律蓝',
      'wasabi': '芥末绿',
      'gold': '金黄',
      'mango': '芒果黄',
      'amber': '琥珀',
      'vesuviusBurn': '熔岩橙',
      'deepPurple': '深紫',
      'ebonyClay': '乌木',
      'barossa': '巴罗萨',
      'shark': '鲨鱼灰',
      'bigStone': '巨石蓝',
      'damask': '锦缎粉',
      'bahamaBlue': '巴哈马蓝',
      'mallardGreen': '野鸭绿',
      'espresso': '咖啡棕',
      'outerSpace': '太空灰',
      'blueWhale': '蓝鲸蓝',
      'sanJuanBlue': '圣胡安蓝',
      'rosewood': '玫瑰木',
      'blumineBlue': '布卢明蓝',
      'flutterDash': '达仕蓝',
      'materialBaseline': 'Material 基线',
      'verdunHemlock': '凡尔登绿',
      'dellGenoa': '山谷绿',
      'redM3': 'M3 红',
      'pinkM3': 'M3 粉',
      'purpleM3': 'M3 紫',
      'indigoM3': 'M3 靛蓝',
      'blueM3': 'M3 蓝',
      'cyanM3': 'M3 青',
      'tealM3': 'M3 青绿',
      'greenM3': 'M3 绿',
      'limeM3': 'M3 青柠',
      'yellowM3': 'M3 黄',
      'orangeM3': 'M3 橙',
      'deepOrangeM3': 'M3 深橙',
      'blackWhite': '黑白',
      'greys': '灰色',
      'sepia': '复古褐',
      'shadBlue': 'Shad 蓝',
      'shadGray': 'Shad 灰',
      'shadGreen': 'Shad 绿',
      'shadNeutral': 'Shad 中性',
      'shadOrange': 'Shad 橙',
      'shadRed': 'Shad 红',
      'shadRose': 'Shad 玫瑰',
      'shadSlate': 'Shad 石板',
      'shadStone': 'Shad 石色',
      'shadViolet': 'Shad 紫罗兰',
      'shadYellow': 'Shad 黄',
    };
    return chinese[name] ?? FlexColor.schemes[this]?.description ?? name;
  }
}

/// 参考发音和语音识别优先使用的英语口音。
enum PronunciationAccent { uk, us }

/// 可备份的用户设置快照。
final class AppSettingsState {
  AppSettingsState({
    required this.dailyGoal,
    this.pronunciationAccent = PronunciationAccent.uk,
    this.autoPlayPronunciation = false,
    required this.themePreference,
    this.accentPreference = FlexScheme.indigo,
    required DateTime? updatedAt,
  }) : updatedAtUtc = updatedAt?.toUtc() {
    if (dailyGoal < minimumDailyGoal || dailyGoal > maximumDailyGoal) {
      throw ArgumentError.value(
        dailyGoal,
        'dailyGoal',
        '每日目标必须在 $minimumDailyGoal-$maximumDailyGoal 之间',
      );
    }
  }

  factory AppSettingsState.defaults() {
    return AppSettingsState(
      dailyGoal: defaultDailyGoal,
      pronunciationAccent: PronunciationAccent.uk,
      autoPlayPronunciation: false,
      themePreference: AppThemePreference.system,
      accentPreference: FlexScheme.indigo,
      updatedAt: null,
    );
  }

  static const int minimumDailyGoal = 1;
  static const int defaultDailyGoal = 10;
  static const int maximumDailyGoal = 500;

  final int dailyGoal;

  /// 旧版本设置字段，仅为读取旧数据库和备份保持结构兼容；应用不再将其作为默认配置。
  final PronunciationAccent pronunciationAccent;

  /// 旧版本设置字段，仅为读取旧数据库和备份保持结构兼容；应用不再执行自动播放。
  final bool autoPlayPronunciation;
  final AppThemePreference themePreference;
  final FlexScheme accentPreference;
  final DateTime? updatedAtUtc;
}
