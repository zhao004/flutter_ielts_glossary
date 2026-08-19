# 雅思词汇库

基于 Flutter 的本地优先雅思词汇学习应用。词库内容、学习记录和核心练习流程均可在设备本地运行；只有配置可选的第三方语音服务时，才会发起网络请求。

## 项目概览

应用将只读词库与可写的用户学习数据分离存储，围绕查词、学习、练习、复习和数据迁移组织学习流程。

| 场景 | 当前能力 |
| --- | --- |
| 查词与词条 | 按词频组、首字母和掌握等级筛选；支持 FTS5 中英文搜索、排序、分页和单词详情。 |
| 学习与复习 | 随机抽词、翻卡、自评、收藏和学习进度持久化；使用六级间隔调度生成到期复习队列。 |
| 专项练习 | 英译中选择、中文/音标/释义/听音拼写和例句填空；支持提示、判题与错题优先。 |
| 学习记录 | 单词与例句收藏、学习趋势、活动日历、每日目标、主题和强调色。 |
| 数据迁移 | 版本化 ZIP 备份、SHA-256 完整性校验、导入预检，以及合并或覆盖恢复。 |
| 语音 | 优先播放随包 UK/US 音频；无本地音频时可配置科大讯飞或有道的 TTS；发音练习可接入对应的第三方评测服务。 |

> 备份文件当前未加密。请勿通过不可信渠道传输，且不要将第三方服务凭据写入源码、测试数据或提交记录。

## 运行应用

### 环境要求

- Flutter `3.44.9` stable；项目 SDK 约束为 Dart `^3.12.2`。
- 已配置 Android 或 iOS 的 Flutter 开发环境，并连接设备或启动模拟器。

### 首次运行

在项目根目录执行：

```bash
flutter pub get
flutter run
```

首次启动时，应用会校验 `assets/data/` 中的内容清单和 SQLite 词库，将内容安装到应用支持目录，再创建用户学习数据库。初始化失败会停留在恢复界面，不会以不完整的本地依赖进入业务页面。

当前随包快照不含 UK/US 本地音频。要使用发音播放或云端评测，请在应用的语音服务设置中填写已授权服务的凭据，并授予麦克风权限；未配置时不影响查词、学习、练习和复习。

## 开发与验证

### 生成代码

仓库已包含所需的 Drift 生成文件。修改数据库表、DAO 或带有生成注解的模型后，重新生成代码；不要手工编辑 `*.g.dart`：

```bash
dart run build_runner build
```

### 常用验证命令

按变更范围选择执行。提交前通常至少运行格式检查、静态分析和直接相关的测试。

| 目的 | 命令 |
| --- | --- |
| 检查 Dart 格式 | `dart format --output=none --set-exit-if-changed lib tool test` |
| 静态分析 | `flutter analyze` |
| 运行全部测试 | `flutter test` |
| 验证打包词库 | `dart run tool/verify_content_database.dart --directory assets/data` |
| 验证主导航流程 | `flutter test test/app/core_navigation_test.dart` |
| 验证窄屏、字体放大和深色主题 | `flutter test test/app/responsive_layout_test.dart` |

持续集成会执行格式检查、分析、测试和词库校验，配置见 [Flutter validation 工作流](.github/workflows/flutter.yml)。

## 架构与目录

页面通过 GetX 的 Binding 和 Logic 获取领域能力，页面层不直接访问 Drift。Repository 负责组合两个数据库中的数据，Service 承载内容安装、复习排程、出题、备份和语音等跨页面能力。

```text
Page / Logic / Binding
          |
   Repository + Service
       |           |
ContentDatabase   UserDatabase
  只读词库         可写学习数据
```

主要目录如下：

```text
lib/
  main.dart              应用入口
  app/
    bootstrap/           启动初始化、依赖装配与恢复流程
    database/            内容库、用户库、表定义和 DAO
    models/              领域模型、内容模型和备份模型
    pages/               页面、GetX Logic 与 Binding
    repositories/        数据访问接口及本地实现
    routes/              路由名称与页面注册
    services/            内容、复习、出题、备份、音频和语音服务
    theme/               主题与强调色
    widgets/             应用级复用组件
assets/
  data/                  随包 SQLite 词库、内容清单和构建报告
  design/icons/          SVG 图标资源
tool/                     词库构建与独立校验 CLI
test/                     单元、Repository、Widget 和导航流程测试
```

`ContentDatabase` 只保存词条、例句和搜索索引；`UserDatabase` 保存学习状态、收藏、练习记录、设置与备份历史。内容更新或用户数据恢复不会直接覆盖另一类数据库。

## 词库数据

当前随包词库的信息来自 [内容清单](assets/data/content_manifest.json)：

| 项目 | 值 |
| --- | --- |
| 内容版本 | `2026.08.16-2278d049` |
| 词库来源 | [chunsi-w/ielts-vocab-cloudflare](https://github.com/chunsi-w/ielts-vocab-cloudflare) 的 `public/data` |
| 冻结来源提交 | `2278d049dacca60181aea4cba3deae1546a63381` |
| 单词数 | 34,211 |
| 例句数 | 76,332 |
| 有效词频组 | 6 |

构建报告位于 [content_build_report.json](assets/data/content_build_report.json)。来源统计中存在 1 条单词数差异、1 条分组数差异和 140 条无法形成独立目标词边界的例句；构建器只会在来源整体 SHA-256 与警告计数完全匹配时保留这些已审计问题。运行时会排除不合格的例句填空候选。

公开分发前，应单独确认词库、例句、记忆法和音频的授权范围。构建器要求显式提供授权或署名文件，也不会下载来源仓库中的远程音频。

### 更新或复现词库

准备与上述提交一致的 `public/data` 目录，以及已经确认授权范围的说明文件，然后在项目根目录运行：

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

固定 `--generated-at` 后，使用相同来源与配置可以生成字节级一致的数据库、清单和报告。`--overwrite` 只会在新产物完整通过校验后原子替换现有文件。

构建完成后独立复核产物：

```bash
dart run tool/verify_content_database.dart --directory assets/data
```

如需接入已授权的本地音频，必须同时提供 `--audio-map-file` 和 `--audio-directory`，并将最终音频资源按 Flutter 资产规则加入工程。可用参数及约束以 CLI 帮助为准：

```bash
dart run tool/build_content_database.dart --help
```

## 数据与隐私

- 学习数据、收藏、设置和备份历史保存在用户数据库中；词库内容位于独立的只读内容库。
- 导出的备份包包含业务学习数据，不包含 TTS 或发音评测的第三方凭据。
- 选择云端 TTS 或发音评测后，相关文本或录音会按所选服务的协议发送到第三方；使用前应确认其服务条款和隐私政策。
- 用户数据库无法打开时，应用可先将旧数据库备份到应用私有目录，再创建空学习数据；之后可通过备份恢复记录。

## 当前边界

- 核心页面已接入真实 Logic、Repository、路由和本地数据库，不使用示例学习数据替代正式流程。
- 测试覆盖主要业务路径、`375 x 812` 窄屏、`1.4` 倍系统字体和深色主题；仍需在目标 Android/iOS 设备上完成安全区、文件选择、分享、麦克风权限及系统字体渲染验收。
- 仓库尚未提供设备级 `integration_test/` 自动化流程，也未随包分发本地发音音频。
