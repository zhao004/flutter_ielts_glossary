# Repository Guidelines

## Project Structure & Module Organization

应用入口位于 `lib/main.dart`。业务代码集中在 `lib/app/`：页面及其 GetX Logic/Binding 放在 `pages/`，数据访问接口与本地实现放在 `repositories/`，领域能力放在 `services/`，Drift 数据库及表定义放在 `database/`，路由、主题和通用组件分别位于 `routes/`、`theme/`、`widgets/`。测试在 `test/` 中按应用结构组织；复用装配放在 `test/support/`，固定输入放在 `test/fixtures/`。词库构建与校验 CLI 位于 `tool/`，随包发布的数据、图标和字体位于 `assets/`。Android 与 iOS 宿主工程分别在 `android/`、`ios/`。

## Build, Test, and Development Commands

- `flutter pub get`：解析项目依赖。
- `flutter run`：在已连接设备或模拟器上运行应用。
- `dart run build_runner build`：重新生成 Drift/JSON 的 `*.g.dart`；不要手工编辑生成文件。
- `dart format --output=none --set-exit-if-changed lib tool test`：检查格式。
- `flutter analyze`：执行 `flutter_lints` 静态分析。
- `flutter test`：运行全部单元与 Widget 测试。
- `flutter test test/app/responsive_layout_test.dart`：检查窄屏、字体放大和深色主题布局。
- `dart run tool/verify_content_database.dart --directory assets/data`：校验打包词库、清单和报告的一致性。
- `flutter build apk`：生成 Android 发布构建。

## Coding Style & Naming Conventions

遵循 Dart 官方格式（两个空格缩进）和 `analysis_options.yaml`。文件使用 `lower_snake_case.dart`，类型使用 `UpperCamelCase`，变量与方法使用 `lowerCamelCase`。公共 Widget 使用中文 `///` 文档说明用途、生命周期或边界；注释解释设计意图，不复述代码。优先延续现有 Page/Logic/Binding、Repository 和 Service 边界，避免让 UI 直接访问数据库。

## Testing Guidelines

使用 `flutter_test`，测试文件以 `_test.dart` 结尾，并尽量镜像 `lib/app/` 路径。修复缺陷时添加能复现问题的回归测试；数据库、异步竞态、导航和响应式 UI 变更应覆盖失败与边界路径。项目未配置数值覆盖率门槛，但提交前至少运行直接相关测试及 `flutter analyze`。

## Commit & Pull Request Guidelines

提交采用 Conventional Commits，说明使用中文且主题不超过 50 字符，例如 `feat(vocabulary): 新增词频筛选`、`fix(backup): 修复导入回滚`。每个提交只包含一个可独立验证的逻辑变更。Pull Request 应说明背景、行为变化和验证命令；关联对应 issue。UI 变更附前后截图，词库资产变更附来源、构建参数和校验结果。不得提交密钥、`.env`、构建产物或 `.cache/` 临时文件。
