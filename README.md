# 雅思词汇库

基于 Flutter 的本地优先雅思词汇学习应用。项目将词库内容与用户学习数据分库存储，覆盖查词、随机学习、专项练习、间隔复习、收藏、统计、备份和发音练习等核心流程。

完整的产品范围、数据模型和阶段验收标准见 [项目规划](flutter-project-plan.md)。

## 核心能力

| 模块 | 当前能力 |
| --- | --- |
| 词库 | 词频组、首字母和掌握等级筛选，FTS5 中英文搜索，排序、分页与单词详情 |
| 学习 | 随机抽词、翻卡、自评、收藏、UK/US 发音，以及学习进度持久化 |
| 练习 | 选择题、中文拼写、音标拼写、听音拼写和例句填空，支持提示、判题与错题优先 |
| 复习 | 六级间隔调度、到期队列、记得/忘记反馈和记忆率统计 |
| 个人数据 | 单词与例句收藏、学习趋势、活动日历、每日目标、主题和强调色设置 |
| 备份 | 版本化 ZIP 备份、SHA-256 完整性校验、导入预检，以及合并或覆盖恢复 |
| 语音 | 词库本地音频播放、可选第三方 TTS，以及可选第三方发音评测 |

应用启动时会校验并安装随包词库，不依赖在线接口完成核心学习流程。备份包当前未加密，请勿通过不可信渠道传输。

## 技术架构

- Flutter `3.44.9`、Dart `^3.12.2`。
- GetX 负责路由、页面状态和依赖绑定。
- Drift 管理 SQLite 数据访问，内容库使用 FTS5 全文索引。
- `ContentDatabase` 是只读内容库，`UserDatabase` 保存可写的学习记录、收藏、设置和备份历史。
- Repository 组合两个数据库的数据，页面 Logic 不直接依赖 Drift 实现。
- `just_audio`、`record` 与 HTTP/WebSocket 服务适配器提供发音播放和第三方评测能力。

主要目录：

```text
lib/
  app/
    bootstrap/      应用初始化与依赖装配
    database/       内容库、用户库及 DAO
    models/         领域模型与备份模型
    pages/          页面、Logic 与 Binding
    repositories/   数据访问边界及本地实现
    services/       内容安装、复习、出题、备份、音频和语音服务
    theme/          主题与强调色
    widgets/        应用级复用组件
assets/data/        随包词库、内容清单与构建报告
tool/               词库构建和独立校验 CLI
test/               单元、Repository、Widget 与导航流程测试
```

## 快速开始

安装 Flutter `3.44.9` stable，并准备 Android 或 iOS 开发环境。然后执行：

```bash
flutter pub get
flutter run
```

仓库已经包含运行所需的 Drift 与 JSON 生成代码。修改数据库表、DAO 或 JSON 模型后，重新生成代码：

```bash
dart run build_runner build
```

首次启动会将 `assets/data/` 中的内容库复制到应用支持目录并校验版本和 SHA-256。初始化失败时应用停留在恢复界面，不会带着不完整依赖进入业务页面。

词库未提供音频时，发音播放需要先配置第三方 TTS；发音评测始终需要配置第三方服务并授予麦克风权限。当前随包资产不含 UK/US 本地音频。

## 词库数据

当前随包快照的信息来自 [内容清单](assets/data/content_manifest.json)：

| 项目 | 值 |
| --- | --- |
| 来源 | `chunsi-w/ielts-vocab-cloudflare` 的 `public/data` |
| 来源提交 | `2278d049dacca60181aea4cba3deae1546a63381` |
| 内容版本 | `2026.08.16-2278d049` |
| 单词 | 34,211 |
| 例句 | 76,332 |
| 有效词频组 | 6 |

来源的 `stats.json` 比实际分块多记录 1 个单词，另有 140 条例句目标词形无法形成独立词边界。构建器仅在来源整体 SHA-256 和警告计数完全匹配时保留这些已知问题；运行时会排除不合格的例句填空候选。分类结果见 [内容构建报告](assets/data/content_build_report.json)。

公开分发前仍需单独确认词库、例句、记忆法和音频的授权范围。构建器要求显式传入授权或署名文件，不会下载来源中的远程音频。

### 复现当前内容库

先准备对应来源提交的 `public/data` 和已确认的授权说明文件，再执行：

```bash
dart run tool/build_content_database.dart \
  --input /path/to/source/public/data \
  --output assets/data \
  --content-version 2026.08.16-2278d049 \
  --source-revision 2278d049dacca60181aea4cba3deae1546a63381 \
  --generated-at 2026-08-05T11:15:42Z \
  --license-notice-file /path/to/LICENSE-NOTICE.txt \
  --expected-word-count 34211 \
  --preserve-known-source-inconsistencies \
  --expected-source-sha256 3635e2764cdd048bc61c5bdef831a165b616fbb9ad71b6b75e3fb5e0c03ce8f8 \
  --expected-source-warning-counts invalid_target_form=140,stats_word_count_mismatch=1,group_word_count_mismatch=1 \
  --validation-report-file .cache/content-validation.json \
  --overwrite
```

`--generated-at` 固定来源提交时间，使同一来源和配置可以生成字节级一致的数据库、清单和报告。`--overwrite` 只会在新产物完整通过校验后原子替换现有文件。

独立复核构建产物：

```bash
dart run tool/verify_content_database.dart --directory assets/data
```

如需接入已授权的本地音频，同时提供 `--audio-map-file` 和 `--audio-directory`；可用参数及约束以 CLI 帮助为准：

```bash
dart run tool/build_content_database.dart --help
```

## 开发与验证

按变更范围选择项目已有的验证命令：

```bash
dart format --output=none --set-exit-if-changed lib tool test
flutter analyze
flutter test
dart run tool/verify_content_database.dart --directory assets/data
```

关键宿主 Widget 流程可以单独运行：

```bash
flutter test test/app/core_navigation_test.dart
flutter test test/app/responsive_layout_test.dart
```

GitHub Actions 的验证配置见 [Flutter validation 工作流](.github/workflows/flutter.yml)。

## 当前边界

- 核心页面已接入真实 Logic、Repository、路由和本地数据库，不使用示例学习数据代替正式流程。
- 页面测试覆盖主要业务路径、`375 x 812` 窄屏、`1.4` 倍系统字体和深色主题；这不能替代真机安全区与系统字体渲染验收。
- 系统文件选择、分享、麦克风权限，以及第三方 TTS 和评测服务仍需在目标 Android/iOS 设备上验收。
- 当前仓库未配置设备级 `integration_test/` 套件，也未包含本地发音音频资产。
