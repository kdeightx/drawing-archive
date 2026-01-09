# lib/ - Application Layer

**Generated:** 2026-01-09
**Commit:** d5d9167

## OVERVIEW
Flutter 应用层，包含入口点、国际化配置和核心组件源码。

## STRUCTURE
```
lib/
├── main.dart                      # 应用入口
├── l10n/                         # 国际化资源
│   ├── app_localizations.dart
│   ├── app_localizations_zh.dart
│   ├── app_localizations_en.dart
│   ├── app_zh.arb
│   └── app_en.arb
└── comp_src/                     # 自定义组件源码
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| 应用入口配置 | `main.dart` | 主题、Provider、国际化初始化 |
| 国际化字符串 | `l10n/app_*.arb` | 翻译文本定义 |
| 组件源码 | `comp_src/` | 所有业务逻辑和 UI 组件 |

## CONVENTIONS

### 国际化
- 所有字符串通过 `AppLocalizations.of(context)!` 访问
- `.arb` 文件是源文件，`.dart` 文件自动生成（已提交到 git）
- 支持：中文（zh）、英文（en）

### 主题配置
- 浅色主题：蓝色主调 `#2563EB`
- 深色主题：浅蓝色 `#60A5FA`
- 统一通过 `Theme.of(context)` 访问主题颜色

### Provider 注入
- `DrawingService` 作为全局单例通过 `MultiProvider` 注入
- ViewModel 通过 `ChangeNotifierProvider` 创建和注入

## ANTI-PATTERNS

### ❌ 不要直接修改生成的国际化文件
`app_localizations*.dart` 文件是自动生成的，**只修改 `.arb` 文件**并重新运行 `flutter gen-l10n`。

## RELATED FILES
- `../pubspec.yaml` - 依赖配置
- `../analysis_options.yaml` - 代码规范配置
- `./comp_src/AGENTS.md` - 组件源码文档
