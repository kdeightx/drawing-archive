# AiApiConfigPage 组件文档

## 组件职责

AI API 配置页面 - 使用 MVVM 架构，让用户配置第三方大模型 API 参数（Base URL、API Key、模型名称），包含表单验证、测试连接功能和配置持久化。

## 代码位置

```
demo/lib/comp_src/pages/ai_api_config_page.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| 无 | - | - | 无构造参数（使用 `const` 构造函数） |

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 显示 SnackBar | 保存成功显示提示，测试连接显示结果（顶部浮窗） |
| 返回上一页 | 保存成功后自动返回设置页面 |
| 测试连接 | 发送测试请求验证 API 配置是否正确 |
| 持久化配置 | 使用 SharedPreferences 保存配置到本地 |

## 依赖项

### 外部依赖
- `package:flutter/material.dart`
- `package:provider/provider.dart` - 状态管理

### 内部依赖
- `../../l10n/app_localizations.dart` - 国际化文本
- `../view_models/ai_api_config_view_model.dart` - AI API 配置 ViewModel

## 状态管理

### 架构模式

**MVVM + Provider**：
- **Model**: SharedPreferences 持久化存储
- **View**: `_AiApiConfigView`（StatefulWidget）
- **ViewModel**: `AiApiConfigViewModel`（ChangeNotifier）

### 状态变量（ViewModel 管理的状态）

| 变量 | 类型 | 说明 | 所在位置 |
|------|------|------|----------|
| `baseUrl` | `String` | Base URL（默认：https://api.302.ai/v1） | ViewModel |
| `apiKey` | `String` | API Key | ViewModel |
| `modelName` | `String` | 模型名称（默认：gemini-1.5-flash-exp） | ViewModel |
| `isTesting` | `bool` | 是否正在测试连接 | ViewModel |
| `errorMessage` | `String?` | 错误信息 | ViewModel |

### 控制器（View 层）

| 控制器 | 用途 |
|--------|------|
| `_apiKeyController` | 控制 API Key 输入框（密码模式） |
| `_baseUrlController` | 控制 Base URL 输入框 |
| `_modelNameController` | 控制模型名称输入框 |
| `_formKey` | 表单状态键，用于验证 |

## 使用示例

### 示例 1：从设置页跳转

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AiApiConfigPage()),
);
```

### 示例 2：读取已保存的配置

```dart
final viewModel = context.read<AiApiConfigViewModel>();
await viewModel.init();

print('Base URL: ${viewModel.baseUrl}');
print('API Key: ${viewModel.apiKey}');
print('Model Name: ${viewModel.modelName}');
```

### 示例 3：测试 API 连接

```dart
final viewModel = context.read<AiApiConfigViewModel>();

// 更新配置
viewModel.updateBaseUrl('https://api.302.ai/v1');
viewModel.updateApiKey('sk-xxxxx');
viewModel.updateModelName('gemini-1.5-flash-exp');

// 测试连接
final success = await viewModel.testConnection();
if (success) {
  print('连接成功！');
} else {
  print('连接失败：${viewModel.errorMessage}');
}
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildAppBar` | 269-282 | 顶部导航栏（带返回按钮） |
| `_buildGridBackground` | 284-290 | 网格背景绘制器 |
| `_buildInfoCard` | 292-338 | 说明卡片（配置引导） |
| `_buildInputCard` | 340-418 | 可复用的输入卡片组件 |
| `_buildActionButtons` | 420-481 | 操作按钮组（测试连接、保存） |
| `_GridPainter` | 484-509 | 网格背景绘制器 |

## 修改注意事项

### MVVM 架构关键点

```dart
// 第 15-18 行：使用 Provider 提供 ViewModel
ChangeNotifierProvider(
  create: (_) => AiApiConfigViewModel(),
  child: const _AiApiConfigView(),
)

// 第 43-58 行：initState 中异步加载配置
WidgetsBinding.instance.addPostFrameCallback((_) async {
  final viewModel = context.read<AiApiConfigViewModel>();
  await viewModel.init(); // 必须等待加载完成

  if (mounted) {
    // 同步到输入框
    _baseUrlController.text = viewModel.baseUrl;
    _apiKeyController.text = viewModel.apiKey;
    _modelNameController.text = viewModel.modelName;
  }
});
```

**重要**：不能在 ViewModel 构造函数中调用异步方法。使用 `init()` 方法在页面初始化后调用。

### 测试连接功能

```dart
// 第 127-183 行：测试连接处理
void _handleTest(AiApiConfigViewModel viewModel) async {
  // 1. 更新 ViewModel 中的值
  viewModel.updateBaseUrl(_baseUrlController.text);
  viewModel.updateApiKey(_apiKeyController.text);
  viewModel.updateModelName(_modelNameController.text);

  // 2. 验证表单
  if (!(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  // 3. 清除之前的错误
  viewModel.clearError();

  // 4. 测试连接
  final success = await viewModel.testConnection();

  // 5. 显示结果（顶部 SnackBar）
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(success ? '连接成功！' : viewModel.errorMessage ?? '连接失败')),
        ],
      ),
      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: mediaQuery.size.height - topPosition - 60, // 定位到顶部
      ),
    ),
  );
}
```

**特点**：
- 不显示"正在测试"的加载提示（用户要求简化）
- 结果提示显示在屏幕顶部（AppBar 下方）
- 成功：绿色背景 + 成功图标
- 失败：红色背景 + 错误图标

### 保存功能

```dart
// 第 69-125 行：保存配置处理
void _handleSave(AiApiConfigViewModel viewModel) async {
  // 1. 更新 ViewModel
  viewModel.updateBaseUrl(_baseUrlController.text);
  viewModel.updateApiKey(_apiKeyController.text);
  viewModel.updateModelName(_modelNameController.text);

  // 2. 验证表单
  if (_formKey.currentState?.validate() ?? false) {
    // 3. 保存配置（持久化到 SharedPreferences）
    final success = await viewModel.saveConfig();

    // 4. 显示提示
    ScaffoldMessenger.of(context).showSnackBar(...);

    // 5. 返回上一页
    if (success) {
      Navigator.pop(context);
    }
  }
}
```

### 表单验证规则

```dart
// 第 215-220 行：Base URL 验证（其他字段类似）
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return l10n.errorBaseUrlRequired;
  }
  return null;
},
```

当前验证规则：**非空即可**。可扩展为：
- API Key 格式验证（如长度、前缀等）
- URL 格式验证（使用 `Uri.tryParse`）
- 模型名称白名单验证

### 网格背景

页面使用 `_GridPainter` 绘制精密工业风格网格背景（第 484-509 行）。

## 相关文件

| 文件 | 说明 |
|------|------|
| `demo/lib/comp_src/pages/ai_api_config_page.dart` | 本页面代码 |
| `demo/lib/comp_src/view_models/ai_api_config_view_model.dart` | AI API 配置 ViewModel |
| `lib/l10n/app_zh.arb` | 中文国际化文本 |
| `lib/l10n/app_en.arb` | 英文国际化文本 |
