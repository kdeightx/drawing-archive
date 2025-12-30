# DrawingSettingsPage 组件指南

## 组件职责

`DrawingSettingsPage` 是设置页面，提供应用设置和功能入口：

- **语言切换**：中英文切换
- **主题切换**：深色/浅色主题切换
- **关于信息**：显示应用版本信息
- **功能入口**：云同步、存储管理、帮助（占位）

---

## 代码位置

```
lib/pages/drawing_settings_page.dart
```

---

## 输入与输出

### 输入（构造参数）

无参数。

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 返回上一页 | 点击左上角返回按钮 |
| 切换语言 | 通过 `DrawingScannerApp.of(context)` 调用 `changeLanguage()` |
| 切换主题 | 通过 `DrawingScannerApp.of(context)` 调用 `toggleTheme()` |

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
```

---

## 状态管理

### 计算属性（Getter）

| 属性 | 类型 | 说明 |
|------|------|------|
| `_isChinese` | `bool` | 当前是否为中文 |
| `_isDarkMode` | `bool` | 当前是否为深色模式 |

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
| LanguageSwitch | 142-184行 | 语言切换组件 |
| LanguageToggle | 186-252行 | 中英文切换按钮 |
| ThemeSwitch | 254-306行 | 主题切换组件（使用 Switch） |
| AboutInfo | 308-349行 | 关于信息显示 |
| OtherSetting | 351-405行 | 其他设置项（云同步/存储/帮助） |
| GridPainter | 408-427行 | 网格背景绘制 |

---

## 修改注意事项

### 应用状态访问

```dart
// 第197行和第224行：获取应用状态
final appState = DrawingScannerApp.of(context);
if (appState != null) {
  appState.changeLanguage(const Locale('zh'));
}
```

### 语言切换实现

- 使用 `AnimatedContainer` 实现切换动画
- 按钮背景色随状态变化
- 通过 `Localizations.localeOf(context)` 获取当前语言

### 主题切换实现

```dart
// 第292-302行：主题 Switch
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

### 未实现功能

| 功能 | 行号 | 说明 |
|------|------|------|
| 云同步 | 56-66 | onTap 为空操作 |
| 存储 | 67-77 | onTap 为空操作 |
| 帮助 | 78-88 | onTap 为空操作 |

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/main.dart` | DrawingScannerApp 定义，提供状态管理方法 |
| `lib/l10n/app_localizations.dart` | 国际化文本 |
