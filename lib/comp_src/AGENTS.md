# comp_src - Component Source

**Generated:** 2026-01-09
**Commit:** d5d9167

## OVERVIEW
核心业务逻辑和 UI 组件源码。MVVM 架构，使用 Provider 状态管理。

## STRUCTURE
```
comp_src/
├── pages/                    # 页面组件（4 个）
│   ├── drawing_scanner_page.dart
│   ├── drawing_search_page.dart
│   ├── drawing_settings_page.dart
│   └── ai_api_config_page.dart
├── widgets/                  # 可复用组件（7 个）
│   ├── action_card.dart
│   ├── action_buttons.dart
│   ├── image_display_card.dart
│   ├── search_input_card.dart
│   ├── search_results_list.dart
│   ├── smart_process_stepper.dart
│   └── full_screen_image_viewer.dart
├── view_models/              # 状态管理层（2 个）
│   ├── drawing_scanner_view_model.dart
│   └── ai_api_config_view_model.dart
└── services/                 # 业务逻辑服务（1 个）
    ├── drawing_service.dart
    └── README.md
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| 核心业务逻辑 | `services/drawing_service.dart` | 图片选择、AI 识别、归档、搜索（800 行）|
| 主页面流程 | `pages/drawing_scanner_page.dart` | 扫描、识别、归档完整流程（668 行）|
| AI 配置 | `pages/ai_api_config_page.dart` | 302.ai API 配置界面（609 行）|
| 状态管理 | `view_models/*.dart` | 所有状态更新逻辑 |
| 图片展示 | `widgets/image_display_card.dart` | 支持缩放、旋转的图片卡片 |
| 全屏查看 | `widgets/full_screen_image_viewer.dart` | 手势缩放、旋转（487 行）|

## CONVENTIONS

### MVVM 架构
- **Model**: `DrawingService`（纯业务逻辑）
- **View**: 所有页面和 Widget
- **ViewModel**: 继承 `ChangeNotifier`，通过 `notifyListeners()` 通知 UI

### Provider 使用模式
```dart
// Provider 注入 ViewModel
ChangeNotifierProvider(
  create: (_) => DrawingScannerViewModel(drawingService: drawingService),
  child: const _DrawingScannerView(),
);

// UI 订阅状态
Consumer<DrawingScannerViewModel>(
  builder: (context, viewModel, child) {
    return Text('${viewModel.selectedImages.length}');
  },
);
```

### 文件命名
- 页面：`{name}_page.dart`
- Widget：`{name}.dart`
- ViewModel：`{name}_view_model.dart`
- Service：`{name}_service.dart`

### 文档
- 每个组件都有 `*_guide.md` 文档
- 服务目录有 `README.md`
- 参见 `../../COMPONENTS.md` 组件索引

## ANTI-PATTERNS

### ❌ 不要在 ViewModel 中直接操作 UI
ViewModel 只管理状态和业务逻辑，**不要包含 UI 控制器**（如 `ScrollController`、`AnimationController`）。这些应该在 View 层（Widget）中管理。

### ❌ 不要在 Service 中存储 UI 状态
`DrawingService` 是纯业务逻辑服务，**不依赖 UI 上下文**。所有 UI 相关状态由 ViewModel 管理。

### ❌ 不要硬编码字符串
所有用户可见文本必须使用国际化：`AppLocalizations.of(context)!.someString`。

## RELATED FILES
- `../../main.dart` - 应用入口，Provider 全局注入
- `../../lib/l10n/` - 国际化资源
- `../../pubspec.yaml` - 项目依赖配置
