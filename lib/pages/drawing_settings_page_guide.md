# DrawingSettingsPage 组件指南

## 组件职责

`DrawingSettingsPage` 是设置页面，提供应用设置和功能入口：

- **语言切换**：中英文切换（动画按钮）
- **主题切换**：深色/浅色主题切换（Switch 组件）
- **关于信息**：显示应用版本信息
- **AI API 配置**：跳转到 AI API 配置页面
- **功能入口**：云同步、存储管理、帮助（占位，未实现）

---

## 代码位置

```
lib/pages/drawing_settings_page.dart
```

---

## 输入与输出

### 输入（构造参数）

无参数（使用 `const` 构造函数）。

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 返回上一页 | 点击左上角返回按钮 |
| 切换语言 | 通过 `DrawingScannerApp.of(context)` 调用 `changeLanguage()` |
| 切换主题 | 通过 `DrawingScannerApp.of(context)` 调用 `toggleTheme()` |
| 跳转 AI API 配置页 | 点击 AI API 配置项，跳转到 AiApiConfigPage |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter: sdk: flutter
```

### 内部依赖

```
lib/l10n/app_localizations.dart  # 国际化
lib/main.dart                    # DrawingScannerApp 状态访问
ai_api_config_page.dart          # AI API 配置页面
```

---

## 状态管理

### 计算属性（Getter）

| 属性 | 类型 | 说明 |
|------|------|------|
| `_isChinese` | `bool` | 当前是否为中文（通过 `Localizations.localeOf` 判断） |
| `_isDarkMode` | `bool` | 当前是否为深色模式（通过 `Theme.of(context)` 判断） |

---

## 使用示例

### 示例1：从扫描页跳转

```dart
// 在 DrawingScannerPage 中
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DrawingSettingsPage()),
);
```

### 示例2：切换语言

```dart
// 获取应用状态并切换语言
final appState = DrawingScannerApp.of(context);
if (appState != null) {
  appState.changeLanguage(const Locale('zh'));  // 切换到中文
}
```

### 示例3：切换主题

```dart
// 获取应用状态并切换主题
final appState = DrawingScannerApp.of(context);
if (appState != null) {
  appState.toggleTheme(true);  // 切换到深色模式
}
```

---

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| `_buildAppBar` | 116-126 | 顶部导航栏（带返回按钮） |
| `_buildGridBackground` | 128-133 | 网格背景容器 |
| `_buildSettingsSection` | 135-157 | 设置分组容器（可复用） |
| `_buildLanguageSwitch` | 159-201 | 语言切换组件（图标+文本+切换按钮） |
| `_buildLanguageToggle` | 203-269 | 中英文切换按钮（双按钮+动画） |
| `_buildThemeSwitch` | 271-323 | 主题切换组件（图标+文本+Switch） |
| `_buildAboutInfo` | 325-366 | 关于信息显示（图标+文本） |
| `_buildOtherSetting` | 368-422 | 其他设置项（可复用组件） |
| `_GridPainter` | 425-444 | 网格背景绘制 |

---

## 修改注意事项

### 应用状态访问

```dart
// 通过 DrawingScannerApp.of(context) 访问应用状态
final appState = DrawingScannerApp.of(context);
if (appState != null) {
  appState.changeLanguage(const Locale('zh'));
  appState.toggleTheme(true);
}
```

### 语言切换实现

- 使用 `AnimatedContainer` 实现切换动画（200ms）
- 按钮背景色随状态变化
- 通过 `Localizations.localeOf(context)` 获取当前语言
- 选中语言：背景为主题色，文字为白色
- 未选中语言：背景透明，文字为灰色

### 主题切换实现

```dart
// 第309-319行：主题 Switch
Switch(
  value: _isDarkMode,
  onChanged: (value) {
    final appState = DrawingScannerApp.of(context);
    if (appState != null) {
      appState.toggleTheme(value);
    }
  },
  activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
  activeThumbColor: Theme.of(context).colorScheme.primary,
);
```

### 设置分组结构

```dart
// 第33-52行：设置分为 4 个分组
_buildSettingsSection(l10n.languageSetting, children: [...])  // 语言设置
_buildSettingsSection(l10n.themeSetting, children: [...])     // 主题设置
_buildSettingsSection(l10n.about, children: [...])            // 关于
_buildSettingsSection('其他', children: [...])                // 其他功能
```

### 🔴 未实现功能

| 功能 | 行号 | 说明 |
|------|------|------|
| 云同步 | 57-67 | onTap 为空操作 |
| 存储 | 68-78 | onTap 为空操作 |
| 帮助 | 79-89 | onTap 为空操作 |

### ✅ 已实现功能

| 功能 | 行号 | 说明 |
|------|------|------|
| AI API 配置 | 90-105 | 跳转到 AiApiConfigPage |

### 网格背景

页面使用 `_GridPainter` 绘制网格背景（第425-444行）。

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/main.dart` | DrawingScannerApp 定义，提供状态管理方法 |
| `lib/l10n/app_localizations.dart` | 国际化文本 |
| `lib/pages/ai_api_config_page.dart` | AI API 配置页面 |
