# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-09
**Commit:** d5d9167
**Branch:** master

## OVERVIEW
Flutter 图纸归档助手应用，使用 MVVM 架构和 Provider 状态管理。核心功能：拍照/相册选择图纸、AI 识别图纸编号（302.ai API）、归档管理、图纸搜索。支持 Android 7-14、iOS、Web、macOS、Linux、Windows。

## STRUCTURE
```
demo/
├── lib/
│   ├── main.dart                     # 应用入口，主题配置，Provider 注入
│   ├── l10n/                        # 国际化（zh/en）
│   └── comp_src/                    # 自定义组件源码（非标准命名）
│       ├── pages/                    # 4 个页面
│       ├── widgets/                  # 7 个可复用组件
│       ├── view_models/              # 2 个 ViewModel（状态管理）
│       └── services/                 # 1 个业务逻辑服务
├── android/                         # Android 平台配置（权限、Manifest）
├── ios/                             # iOS 平台配置（Info.plist）
├── test/                            # 测试（仅 1 个 widget_test.dart）
├── pubspec.yaml                     # 依赖配置
├── analysis_options.yaml            # Flutter lint 规则
└── COMPONENTS.md                    # 组件索引（非标准）
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| 应用入口 | `lib/main.dart` | 主题配置、语言切换、Provider 注入 |
| 核心业务逻辑 | `lib/comp_src/services/drawing_service.dart` | 图片选择、AI 识别、归档、搜索（800 行）|
| 主页面 | `lib/comp_src/pages/drawing_scanner_page.dart` | 图纸扫描主流程（668 行）|
| 状态管理 | `lib/comp_src/view_models/*.dart` | MVVM 模式，ChangeNotifier |
| 可复用组件 | `lib/comp_src/widgets/*.dart` | ActionCard, ImageDisplayCard, FullScreenImageViewer 等 |
| AI 配置 | `lib/comp_src/pages/ai_api_config_page.dart` | 302.ai API 配置（609 行）|
| 权限配置 | `android/.../AndroidManifest.xml`, `ios/Runner/Info.plist` | 相机、相册、存储权限 |
| 组件文档 | 各目录下的 `*_guide.md` 文件 | 每个组件都有详细 Markdown 文档 |

## CONVENTIONS（项目特定规则）

### 目录命名
- **非标准**: 使用 `comp_src/` 而非标准的 `components/`、`widgets/` 或 `features/`
- **结构**: `pages/`, `widgets/`, `view_models/`, `services/`（缺少 `models/`）

### 文件命名
- 页面: `{name}_page.dart`
- Widget: `{name}.dart`
- ViewModel: `{name}_view_model.dart`
- Service: `{name}_service.dart`
- 文档: `{name}_guide.md` 或 `README.md`

### 架构模式
- **MVVM + Provider**: 所有 ViewModel 继承 `ChangeNotifier`
- **依赖注入**: 通过构造函数注入 `DrawingService`
- **状态管理**: `ChangeNotifierProvider` + `Consumer`
- **导航**: 传统 `Navigator.push` + `MaterialPageRoute`

### 国际化
- 通过 `AppLocalizations.of(context)!` 统一访问
- 支持: 中文（默认）、英文
- 位置: `lib/l10n/app_*.arb`（生成文件已提交到 git）

### 主题
- 双主题: 浅色 + 深色模式
- 主色调: 蓝色 `#2563EB`（浅色）/ `#60A5FA`（深色）
- 适配: 所有组件通过 `Theme.of(context)` 动态适配

### 日志记录
- 工具: `debugPrint`
- 模式: Emoji + 简洁描述（✓/✗/⚠️/🚀/✅/❌）
- 示例: `debugPrint('✓ 已复制图片到临时文件夹: $fileName');`

### 权限管理（Android）
- **版本感知**: 根据 Android API 版本动态请求权限
  - Android 11+: `MANAGE_EXTERNAL_STORAGE`
  - Android 10: `MANAGE_EXTERNAL_STORAGE`
  - Android 7-9: `WRITE_EXTERNAL_STORAGE`
- **Platform Channel**: 使用 `com.example.demo/storage` 获取公共存储路径
- **路径**: `/storage/emulated/0/DrawingScanner/`（Android 外部存储）

### AI 集成
- API: 302.ai 多模态模型
- 配置: 从 SharedPreferences 加载（`ai_api_base_url`, `ai_api_key`, `ai_model_name`）
- 识别: 图片转 Base64 → 多模态 POST 请求 → 正则验证图纸编号格式 `^\d+\.\d+-\d+$`
- 超时: 60 秒

### 文档体系
- 每个组件都有对应的 `*_guide.md` 文档
- `COMPONENTS.md` 维护组件索引（根目录）
- 服务目录有 `README.md`

## ANTI-PATTERNS（此项目禁止的行为）

### ❌ 不要移除模拟数据
`DrawingService.searchDrawings()` 当前返回模拟数据。**在实现真实数据查询前不要删除**，因为搜索功能还未完成。

### ❌ 不要硬编码存储路径
Android 存储路径必须通过 Platform Channel 动态获取，**不要直接使用** `/storage/emulated/0/`。使用 `_getPublicExternalStorageRoot()` 方法。

### ❌ 不要回退到模拟数据
AI 识别功能已集成真实 API，**完全移除了模拟数据回退机制**。确保用户始终知道 AI 是否真正工作。

### ❌ 不要忽略权限
应用必须在使用前请求并获得权限，**不要在权限未授予时继续执行**。如果用户拒绝，提示并打开应用设置页面。

### ❌ 不要修改已提交的生成文件
国际化生成的 Dart 文件（`app_localizations.dart` 等）已提交到 git。**不要手动修改**，应修改 `.arb` 文件并重新生成。

## UNIQUE STYLES

### 调试日志
```dart
debugPrint('✓ 成功标记');
debugPrint('✗ 失败');
debugPrint('⚠️ 警告');
debugPrint('🚀 开始操作');
debugPrint('✅ 操作完成');
debugPrint('❌ 操作失败');
```

### 错误处理
```dart
try {
  final result = await drawingService.analyzeImage(image);
} catch (e) {
  debugPrint('❌ 识别失败: $e');
  rethrow; // 向上传播异常
}
```

### 超时处理
```dart
await http.post(uri).timeout(
  const Duration(seconds: 60),
  onTimeout: () => throw Exception('AI 识别超时'),
);
```

### ViewModel 状态更新
```dart
void updateNumber(int index, String number) {
  _recognizedNumbers[index] = number;
  notifyListeners(); // 必须调用
}
```

### 国际化访问
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.scanTitle)
```

### 主题颜色访问
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
color: Theme.of(context).colorScheme.primary,
backgroundColor: Theme.of(context).colorScheme.surface,
```

## COMMANDS

```bash
# 运行应用
flutter run

# 运行测试
flutter test

# 生成覆盖率报告
flutter test --coverage

# 分析代码
flutter analyze

# 格式化代码
dart format .

# 获取依赖
flutter pub get

# 升级依赖
flutter pub upgrade

# 构建应用
flutter build apk
flutter build ios

# 国际化生成
flutter gen-l10n

# 清理构建
flutter clean
```

## NOTES

### 项目状态
- **代码规模**: 198 个文件，7,645 行代码，14 个 Dart 文件（6,160 行）
- **大文件**（>500 行）: 7 个（drawing_service.dart 800 行，drawing_scanner_page.dart 668 行等）
- **架构**: MVVM + Provider，清晰分层
- **测试覆盖率**: 极低（< 5%，仅 1 个 widget smoke test）
- **文档完善度**: 高（每个组件都有详细 Markdown 文档）

### 待完成任务
1. **搜索功能**: `DrawingService.searchDrawings()` 仍返回模拟数据，需要实现从文件系统读取已归档图纸
2. **测试覆盖**: 缺少单元测试和集成测试
3. **错误处理**: 可添加统一的错误处理机制和错误上报

### 技术栈
- **UI**: Flutter (Material 3)
- **状态管理**: Provider + ChangeNotifier
- **网络**: http
- **存储**: SharedPreferences + 文件系统
- **权限**: permission_handler
- **图片**: image_picker
- **国际化**: flutter_localizations + intl
- **AI**: 302.ai 多模态 API

### 平台支持
Android 7-14, iOS, Web, macOS, Linux, Windows

### 依赖版本
- Dart SDK: ^3.10.0-290.4.beta
- Flutter SDK: 最新稳定版
