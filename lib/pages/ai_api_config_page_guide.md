# AiApiConfigPage 组件文档

## 组件职责

AI API 配置页面 - 用于让用户配置第三方大模型 API 参数（API Key、Base URL、模型名称），包含表单验证、用户引导和配置保存功能。

## 代码位置

`lib/pages/ai_api_config_page.dart`

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| 无 | - | - | 无构造参数（使用 `const` 构造函数） |

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 显示 SnackBar | 保存成功显示提示，验证失败显示错误 |
| 返回上一页 | 保存成功后自动返回设置页面 |
| 表单验证 | 确保所有必填字段都已填写 |

## 依赖项

### 外部依赖
- `package:flutter/material.dart`

### 内部依赖
- `../l10n/app_localizations.dart` - 国际化文本

## 状态管理

### 状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `_apiKeyController` | `TextEditingController` | API Key 输入控制器 |
| `_baseUrlController` | `TextEditingController` | Base URL 输入控制器 |
| `_modelNameController` | `TextEditingController` | 模型名称输入控制器 |
| `_formKey` | `GlobalKey<FormState>` | 表单状态键，用于验证 |

### 控制器

| 控制器 | 用途 |
|--------|------|
| `_apiKeyController` | 控制 API Key 输入框（密码模式） |
| `_baseUrlController` | 控制 Base URL 输入框 |
| `_modelNameController` | 控制模型名称输入框 |

## 使用示例

### 示例 1：从设置页跳转

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AiApiConfigPage()),
);
```

### 示例 2：获取用户输入的配置

```dart
// 当前页面不持久化，如需获取用户输入：
final apiKey = _apiKeyController.text.trim();
final baseUrl = _baseUrlController.text.trim();
final modelName = _modelNameController.text.trim();
```

### 示例 3：表单验证

```dart
if (_formKey.currentState?.validate() ?? false) {
  // 验证通过，执行保存逻辑
}
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildAppBar` | 137-147 | 顶部导航栏（带返回按钮） |
| `_buildGridBackground` | 149-154 | 网格背景绘制器 |
| `_buildInfoCard` | 156-198 | 说明卡片（配置引导） |
| `_buildInputCard` | 200-270 | 可复用的输入卡片组件 |
| `_buildSaveButton` | 272-294 | 保存按钮（全宽） |
| `_GridPainter` | 297-316 | 网格背景绘制器 |

## 修改注意事项

### 保存逻辑未持久化

```dart
// 第29-55行：当前仅显示提示，未实际持久化
void _handleSave() {
  if (_formKey.currentState?.validate() ?? false) {
    // TODO: 添加持久化逻辑
    // 例如：使用 shared_preferences 保存配置
    Navigator.pop(context);
  }
}
```

如需实现持久化，可添加：
```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.0
```

### API Key 密码模式

```dart
// 第218行：API Key 输入框使用密码模式
obscureText: isPassword,
```

API Key 输入框默认启用密码模式，隐藏输入内容。

### 表单验证规则

```dart
// 第86-91行：API Key 验证（其他字段类似）
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return l10n.errorApiKeyRequired;
  }
  return null;
},
```

当前验证规则：非空即可。可扩展为：
- API Key 格式验证（如长度、前缀等）
- URL 格式验证（使用 `Uri.tryParse`）
- 模型名称白名单验证

### 输入框样式

```dart
// 第224-227行：边框样式配置
border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(
    color: _isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
    width: 1,
  ),
),
```

### 网格背景

页面使用 `_GridPainter` 绘制网格背景（第297-316行）。

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/pages/drawing_settings_page.dart` | 通过设置页面跳转 |
| `lib/l10n/app_zh.arb` | 中文国际化文本 |
| `lib/l10n/app_en.arb` | 英文国际化文本 |
