# AiApiConfigViewModel 组件文档

## 组件职责

`AiApiConfigViewModel` 是 AI API 配置页面的状态管理类，负责：

- **配置管理**：管理 Base URL、API Key、模型名称的读写
- **持久化**：使用 SharedPreferences 保存和加载配置
- **测试连接**：发送测试请求验证 API 配置是否正确
- **状态通知**：通过 ChangeNotifier 通知 UI 更新

---

## 代码位置

```
demo/lib/comp_src/view_models/ai_api_config_view_model.dart
```

---

## 输入与输出

### 输入（方法调用）

| 方法 | 参数 | 类型 | 说明 |
|------|------|------|------|
| `init()` | 无 | - | 初始化配置，从 SharedPreferences 加载 |
| `updateBaseUrl()` | `value` | `String` | 更新 Base URL |
| `updateApiKey()` | `value` | `String` | 更新 API Key |
| `updateModelName()` | `value` | `String` | 更新模型名称 |
| `saveConfig()` | 无 | - | 保存配置到 SharedPreferences |
| `testConnection()` | 无 | - | 测试 API 连接 |
| `clearError()` | 无 | - | 清除错误信息和测试结果 |
| `resetToDefaults()` | 无 | - | 重置为默认值并清除持久化配置 |

### 输出（状态变化）

| 状态 | 类型 | 说明 |
|------|------|------|
| `baseUrl` | `String` | Base URL（默认：https://api.302.ai/v1） |
| `apiKey` | `String` | API Key |
| `modelName` | `String` | 模型名称（默认：gemini-1.5-flash-exp） |
| `isTesting` | `bool` | 是否正在测试连接 |
| `errorMessage` | `String?` | 错误信息 |
| `testResult` | `String?` | 测试连接结果 |
| `isConfigValid` | `bool` | 配置是否有效（所有字段非空） |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0              # HTTP 请求
  shared_preferences: ^2.2.2 # 持久化存储
```

### 内部依赖

```
无（纯 ViewModel，不依赖其他项目组件）
```

---

## 使用示例

### 示例 1：初始化并加载配置

```dart
// 在页面 initState 中调用
final viewModel = context.read<AiApiConfigViewModel>();
await viewModel.init();

// 配置已加载，可以同步到 UI
_baseUrlController.text = viewModel.baseUrl;
_apiKeyController.text = viewModel.apiKey;
_modelNameController.text = viewModel.modelName;
```

### 示例 2：保存配置

```dart
final viewModel = context.read<AiApiConfigViewModel>();

// 更新配置
viewModel.updateBaseUrl('https://api.302.ai/v1');
viewModel.updateApiKey('sk-xxxxx');
viewModel.updateModelName('gemini-1.5-flash-exp');

// 保存到本地
final success = await viewModel.saveConfig();
if (success) {
  print('配置已保存');
} else {
  print('保存失败：${viewModel.errorMessage}');
}
```

### 示例 3：测试 API 连接

```dart
final viewModel = context.read<AiApiConfigViewModel>();

// 配置必须有效才能测试
if (viewModel.isConfigValid) {
  final success = await viewModel.testConnection();
  if (success) {
    print('连接成功！');
    print(viewModel.testResult); // AI 响应内容
  } else {
    print('连接失败：${viewModel.errorMessage}');
  }
} else {
  print('请先填写所有必填字段');
}
```

---

## 实现细节

### 状态管理机制

```dart
class AiApiConfigViewModel extends ChangeNotifier {
  // 第 12-22 行：常量和 SharedPreferences 键名
  static const String defaultBaseUrl = 'https://api.302.ai/v1';
  static const String defaultModelName = 'gemini-1.5-flash-exp';
  static const String _keyBaseUrl = 'ai_api_base_url';
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyModelName = 'ai_model_name';

  // 第 26-44 行：私有状态变量
  String _baseUrl = defaultBaseUrl;
  String _apiKey = '';
  String _modelName = defaultModelName;
  bool _isTesting = false;
  String? _errorMessage;
  String? _testResult;

  // 公共 getter
  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;
  // ...
}
```

**重要**：所有状态更新后必须调用 `notifyListeners()` 通知 UI。

### 初始化流程

```dart
// 第 64-84 行：异步加载配置
Future<void> init() async {
  await _loadConfig();
}

Future<void> _loadConfig() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
    _apiKey = prefs.getString(_keyApiKey) ?? '';
    _modelName = prefs.getString(_keyModelName) ?? defaultModelName;

    notifyListeners(); // 通知 UI 更新
  } catch (e) {
    debugPrint('❌ 加载配置失败: $e');
  }
}
```

**为什么不能在构造函数中初始化？**
- 构造函数不能是异步的
- SharedPreferences 需要异步调用
- 解决方案：提供公共 `init()` 方法在页面 `initState` 中调用

### 保存配置

```dart
// 第 87-115 行：保存到 SharedPreferences
Future<bool> saveConfig() async {
  if (!isConfigValid) {
    _errorMessage = '请填写所有必填字段';
    notifyListeners();
    return false;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl.trim());
    await prefs.setString(_keyApiKey, _apiKey.trim());
    await prefs.setString(_keyModelName, _modelName.trim());

    _errorMessage = null;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = '保存配置失败: $e';
    notifyListeners();
    return false;
  }
}
```

### 测试连接实现

```dart
// 第 117-211 行：测试 API 连接
Future<bool> testConnection() async {
  if (!isConfigValid) {
    _errorMessage = '请先填写所有必填字段';
    notifyListeners();
    return false;
  }

  _isTesting = true;
  notifyListeners(); // UI 显示加载状态

  try {
    final uri = Uri.parse('$_baseUrl/chat/completions');

    // 构建测试请求（简单文本消息）
    final requestBody = {
      'model': _modelName,
      'stream': false,
      'messages': [
        {
          'role': 'user',
          'content': 'Hello, this is a test message.',
        }
      ],
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${_apiKey.trim()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices']?.first['message']?['content'];

      _testResult = '连接成功！\nAI 响应: ${content ?? "无内容"}';
      _errorMessage = null;
      _isTesting = false;
      notifyListeners();
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['error']?['message'] ?? '未知错误';

      _errorMessage = '连接失败 (${response.statusCode}): $errorMsg';
      _testResult = null;
      _isTesting = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    _errorMessage = '测试失败: $e';
    _testResult = null;
    _isTesting = false;
    notifyListeners();
    return false;
  }
}
```

**调试信息**：
- 请求 URL、请求体、响应状态码、响应体都会通过 `debugPrint` 输出
- 方便排查连接问题

### 识别图纸编号

```dart
// 第 213-297 行：调用 AI API 识别图纸编号
Future<String> recognizeDrawingNumber(String imageBase64) async {
  if (!isConfigValid) {
    throw Exception('AI API 配置无效，请先配置');
  }

  try {
    final uri = Uri.parse('$_baseUrl/chat/completions');

    // 构建多模态请求（文本 + 图片）
    final requestBody = {
      'model': _modelName,
      'stream': false,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': '请识别这张机械图纸中的图纸编号。\n要求：\n1. 只返回图纸编号，不要返回任何其他文字\n2. 图纸编号格式通常为：数字.数字-数字（如：1.0101-1100）\n3. 如果图片中没有清晰的图纸编号，请返回 "未识别"\n4. 不要添加任何解释或说明',
            },
            {
              'type': 'image_url',
              'image_url': {'url': imageBase64},
            },
          ],
        },
      ],
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${_apiKey.trim()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices']?.first['message']?['content'];

      if (content == null || content.isEmpty) {
        throw Exception('AI 未返回识别结果');
      }

      // 清理结果并验证格式
      final cleanResult = content.trim().replaceAll('\n', '').replaceAll('\r', '');
      final numberPattern = RegExp(r'^\d+\.\d+-\d+$');

      if (!numberPattern.hasMatch(cleanResult)) {
        throw Exception('AI 识别结果格式不正确: $cleanResult');
      }

      return cleanResult;
    } else {
      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['error']?['message'] ?? '未知错误';
      throw Exception('AI 识别失败 (${response.statusCode}): $errorMsg');
    }
  } catch (e) {
    debugPrint('AI 识别失败: $e');
    rethrow;
  }
}
```

**注意**：
- 这个方法目前不在 AiApiConfigViewModel 中，它应该在 DrawingService 或单独的 RecognitionService 中
- 如果需要，可以将此方法移到专门的识别服务中

---

## 修改注意事项

### 为什么不在构造函数中初始化？

```dart
// ❌ 错误做法
AiApiConfigViewModel() {
  _loadConfig(); // 无法 await，可能导致配置未加载就使用
}

// ✅ 正确做法
AiApiConfigViewModel(); // 构造函数不执行异步操作

Future<void> init() async {
  await _loadConfig(); // 提供公共异步方法
}

// 在页面 initState 中调用
WidgetsBinding.instance.addPostFrameCallback((_) async {
  final viewModel = context.read<AiApiConfigViewModel>();
  await viewModel.init(); // 等待加载完成

  if (mounted) {
    _baseUrlController.text = viewModel.baseUrl;
    // ...
  }
});
```

### 状态更新模式

所有状态更新都必须遵循以下模式：

```dart
void updateBaseUrl(String value) {
  _baseUrl = value;
  notifyListeners(); // 必须调用，否则 UI 不更新
}
```

### 错误处理模式

```dart
try {
  // 执行操作
  final result = await someAsyncOperation();

  // 成功：清除错误
  _errorMessage = null;
  notifyListeners();
  return true;
} catch (e) {
  // 失败：设置错误信息
  _errorMessage = '操作失败: $e';
  notifyListeners();
  return false;
}
```

### 调试日志

所有关键操作都会输出调试日志：

```dart
debugPrint('📖 开始加载配置...');
debugPrint('  Base URL: $_baseUrl');
debugPrint('  API Key: ${_apiKey.isNotEmpty ? "已填写 (${_apiKey.length} 字符)" : "空"}');
debugPrint('✅ 配置加载完成');
```

在生产环境中，可以：
- 移除所有 `debugPrint`
- 或使用日志级别控制

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `demo/lib/comp_src/pages/ai_api_config_page.dart` | AI API 配置页面，使用此 ViewModel |
| `demo/lib/comp_src/services/drawing_service.dart` | 图纸服务，调用此 ViewModel 的配置进行 AI 识别 |
