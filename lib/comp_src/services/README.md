# DrawingService 组件指南

## 组件职责

`DrawingService` 提供图纸业务逻辑服务，负责处理与图纸相关的所有业务逻辑：

- **图片选择**：支持从相机或相册单选/多选图片
- **图片分析**：识别图纸编号（使用真实 AI API）
- **图纸归档**：保存图纸归档记录到本地存储
- **图纸搜索**：搜索已归档的图纸记录（当前为模拟实现）
- **权限管理**：自动请求相机、相册、存储权限
- **AI API 集成**：调用 302.ai 多模态大模型识别图纸编号

---

## 代码位置

```
demo/lib/comp_src/services/drawing_service.dart
```

---

## 输入与输出

### 输入（参数）

| 方法 | 参数 | 类型 | 说明 |
|------|------|------|------|
| `pickImage()` | `source` | `ImageSource` | 图片来源（camera/gallery） |
| `pickMultipleImages()` | 无 | - | - |
| `analyzeImage()` | `image` | `io.File` | 要分析的图片文件 |
| `analyzeImage()` | `shouldCopy` | `bool` | 是否复制到临时文件夹（默认 true） |
| `saveEntry()` | `image` | `io.File` | 图片文件 |
| `saveEntry()` | `finalNumber` | `String` | 图纸编号 |
| `searchDrawings()` | `keyword` | `String?` | 搜索关键词（可选）|
| `searchDrawings()` | `startDate` | `DateTime?` | 开始日期（可选）|
| `searchDrawings()` | `endDate` | `DateTime?` | 结束日期（可选）|
| `searchDrawings()` | `ascending` | `bool` | 是否升序排列（默认 true）|

### 输出（返回值）

| 方法 | 返回值 | 类型 | 说明 |
|------|--------|------|------|
| `initialize()` | 初始化是否成功 | `Future<bool>` | true=成功，false=需要授权 |
| `pickImage()` | 图片文件 | `Future<io.File?>` | 返回选中的图片，取消或失败返回 null |
| `pickMultipleImages()` | 图片文件列表 | `Future<List<io.File>>` | 返回选中的图片列表 |
| `analyzeImage()` | 图纸编号 | `Future<String>` | 返回识别出的图纸编号（如：1.0101-1100） |
| `saveEntry()` | 无 | `Future<void>` | - |
| `searchDrawings()` | 图纸条目列表 | `Future<List<DrawingEntry>>` | 返回搜索结果 |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.1.2
  permission_handler: ^11.0.1
  http: ^1.2.0              # HTTP 请求
  shared_preferences: ^2.2.2 # 持久化存储
```

### 内部依赖

```
无（纯业务逻辑服务）
```

### 平台权限配置

**Android (`android/app/src/main/AndroidManifest.xml`)**:
```xml
<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- 相册权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- 存储权限（Android 11+）-->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

**iOS (`ios/Runner/Info.plist`)**:
```xml
<!-- 相机权限说明 -->
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄图纸照片</string>

<!-- 相册权限说明 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择图纸照片</string>

<!-- 照片权限说明（iOS 14+）-->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存识别后的图纸照片</string>
```

---

## 数据模型

### ImageSource（图片来源枚举）

```dart
enum ImageSource { camera, gallery }
```

| 值 | 说明 |
|----|------|
| `camera` | 从相机拍照 |
| `gallery` | 从相册选择 |

### DrawingEntry（图纸条目模型）

```dart
class DrawingEntry {
  final String number;        // 图纸编号
  final DateTime date;        // 归档日期
  final String status;        // 归档状态
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `number` | `String` | 图纸编号（格式：X.XXXX-XXXX）|
| `date` | `DateTime` | 归档日期 |
| `status` | `String` | 归档状态 |

---

## 使用示例

### 示例 1：初始化服务并选择图片

```dart
// 创建服务实例
final DrawingService _drawingService = DrawingService();

// 初始化服务（在应用启动时调用一次）
final bool initialized = await _drawingService.initialize();
if (!initialized) {
  print('服务初始化失败，需要用户授权');
  return;
}

// 从相机选择图片
final io.File? image = await _drawingService.pickImage(ImageSource.camera);
if (image != null) {
  print('已选择图片: ${image.path}');
}
```

### 示例 2：使用 AI 分析图片并保存归档

```dart
// 分析图片，识别图纸编号（调用真实 AI API）
final String drawingNumber = await _drawingService.analyzeImage(image);
print('识别出的图纸编号: $drawingNumber');
// 输出示例：1.0101-1100

// 保存归档记录
await _drawingService.saveEntry(image, drawingNumber);
print('归档成功');
```

### 示例 3：搜索已归档图纸

```dart
// 按关键词搜索
final List<DrawingEntry> results = await _drawingService.searchDrawings(
  keyword: '1.0234',
);

// 按日期范围搜索（降序）
final List<DrawingEntry> recentResults = await _drawingService.searchDrawings(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
  ascending: false,
);

// 显示搜索结果
for (final entry in results) {
  print('图纸编号: ${entry.number}, 日期: ${entry.date}');
}
```

---

## AI API 集成说明

### AI 识别实现

`_recognizeDrawingNumberWithAI()` 方法实现了真实的图纸编号识别：

#### API 配置

AI API 配置从 SharedPreferences 加载：

| 配置项 | SharedPreferences 键 | 默认值 |
|--------|----------------------|--------|
| Base URL | `ai_api_base_url` | `https://api.302.ai/v1` |
| API Key | `ai_api_key` | 空（必须由用户配置） |
| Model Name | `ai_model_name` | `gemini-1.5-flash-exp` |

#### 识别流程

```dart
// 第 241-338 行：AI 识别实现
Future<String> _recognizeDrawingNumberWithAI(io.File image) async {
  // 1. 加载 API 配置
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString('ai_api_base_url') ?? 'https://api.302.ai/v1';
  final apiKey = prefs.getString('ai_api_key') ?? '';
  final modelName = prefs.getString('ai_model_name') ?? 'gemini-1.5-flash-exp';

  // 2. 检查配置有效性
  if (apiKey.isEmpty) {
    throw Exception('API Key 未配置，请先在设置中配置 AI API');
  }

  // 3. 图片转 Base64
  final imageBytes = await image.readAsBytes();
  final base64Image = base64Encode(imageBytes);
  final mimeType = _getImageMimeType(image.path);
  final dataUri = 'data:$mimeType;base64,$base64Image';

  // 4. 构建多模态请求
  final requestBody = {
    'model': modelName,
    'stream': false,
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text': '请识别这张机械图纸中的图纸编号。\n要求：\n1. 只返回图纸编号，不要返回任何其他文字\n2. 图纸编号格式通常为：数字.数字-数字（如：1.0101-1100）\n3. 如果图片中没有清晰的图纸编号，请返回 "未识别"\n4. 不要添加任何解释或说明',
          },
          {'type': 'image_url', 'image_url': {'url': dataUri}},
        ],
      },
    ],
  };

  // 5. 发送 HTTP POST 请求
  final response = await http.post(
    Uri.parse('$baseUrl/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(requestBody),
  ).timeout(const Duration(seconds: 60));

  // 6. 验证响应格式
  if (response.statusCode == 200 || response.statusCode == 201) {
    final content = responseData['choices']?.first['message']?['content'];
    final cleanResult = content.trim().replaceAll('\n', '').replaceAll('\r', '');

    // 检查图纸编号格式：数字.数字-数字
    final numberPattern = RegExp(r'^\d+\.\d+-\d+$');
    if (!numberPattern.hasMatch(cleanResult)) {
      throw Exception('AI 识别结果格式不正确: "$cleanResult"');
    }

    return cleanResult;
  } else {
    throw Exception('AI 识别失败 (${response.statusCode}): ${errorMsg}');
  }
}
```

#### 错误处理

- **API Key 未配置**：抛出异常提示用户配置
- **网络错误**：抛出 HTTP 异常（包含状态码和错误信息）
- **识别结果格式错误**：抛出异常（不回退到模拟数据）
- **超时**：60 秒超时限制

**重要**：当前实现**完全移除了模拟数据回退机制**，确保用户始终知道 AI 是否真正工作。

---

## 修改注意事项

### ⚠️ 重要：搜索功能仍为模拟实现

| 方法 | 行号 | 当前实现 | 待实现 |
|------|------|----------|--------|
| `searchDrawings()` | 459-471 | 返回模拟数据 | 从数据库/服务器查询真实数据 |

### AI API 配置要求

**必须在使用 `analyzeImage()` 之前配置 AI API**：

```dart
// 通过 AI API 配置页面配置
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const AiApiConfigPage(),
));
```

**配置验证**：
- Base URL：非空
- API Key：非空（必需）
- Model Name：非空

### 存储路径配置

**Android 存储路径**（第 61 行）：
```dart
final folderPath = '/storage/emulated/0/DrawingScanner';
```

当前直接使用外部存储根目录，与 Download、Documents 等系统文件夹同级。

**临时图片存储**：
- 所有发送给 AI 的图片会复制到 `DrawingScanner/AI_` 文件夹
- 文件命名格式：`AI_{timestamp}_{original_filename}`
- 已归档的图片（重命名为图纸编号）不会在清理时删除

### 权限请求流程

初始化时会自动请求 `MANAGE_EXTERNAL_STORAGE` 权限（第 34-56 行）。如果用户拒绝，会尝试打开应用设置页面。

### 平台差异处理

- **Android 13+**：使用 `photos` 权限访问相册
- **Android 12 及以下**：使用 `storage` 权限
- **iOS**：统一使用 `photos` 权限

### 图片质量设置

选择图片时压缩质量设置为 85（第 113 行）。如需调整图片质量，请修改 `imageQuality` 参数。

### 支持的图片格式

| 格式 | MIME 类型 | 说明 |
|------|----------|------|
| JPEG | `image/jpeg` | 默认格式 |
| PNG | `image/png` | 支持透明背景 |
| GIF | `image/gif` | 动图仅首帧 |
| WebP | `image/webp` | 高效压缩格式 |

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `demo/lib/comp_src/pages/drawing_scanner_page.dart` | 图纸扫描页面，使用本服务选择和分析图片 |
| `demo/lib/comp_src/pages/drawing_search_page.dart` | 图纸搜索页面，使用本服务搜索归档记录 |
| `demo/lib/comp_src/pages/ai_api_config_page.dart` | AI API 配置页面，配置识别服务参数 |
| `demo/lib/comp_src/view_models/ai_api_config_view_model.dart` | AI API 配置 ViewModel |
| `demo/pubspec.yaml` | 项目依赖配置文件 |
