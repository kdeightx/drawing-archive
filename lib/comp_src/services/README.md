# DrawingService 组件指南

## 组件职责

`DrawingService` 提供图纸业务逻辑服务，负责处理与图纸相关的所有业务逻辑：

- **图片选择**：支持从相机或相册单选/多选图片
- **图片分析**：识别图纸编号（当前为模拟实现）
- **图纸归档**：保存图纸归档记录（当前为模拟实现）
- **图纸搜索**：搜索已归档的图纸记录（当前为模拟实现）
- **权限管理**：自动请求相机、相册、存储权限

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
| `analyzeImage()` | 图纸编号 | `Future<String>` | 返回识别出的图纸编号 |
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

### 示例 2：分析图片并保存归档

```dart
// 分析图片，识别图纸编号
final String drawingNumber = await _drawingService.analyzeImage(image);
print('识别出的图纸编号: $drawingNumber');

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

## 修改注意事项

### 🔴 重要提醒（TODO 功能）

以下功能当前为**模拟实现**，需要后续对接真实服务：

| 方法 | 行号 | 当前实现 | 待实现 |
|------|------|----------|--------|
| `analyzeImage()` | 196-215 | 生成随机图纸编号 | 调用 AI/OCR 服务识别图纸编号 |
| `saveEntry()` | 218-225 | 打印日志 | 保存到数据库/服务器 |
| `searchDrawings()` | 228-240 | 返回模拟数据 | 从数据库/服务器查询真实数据 |

### 存储路径配置

**Android 存储路径**（第 60 行）：
```dart
final folderPath = '/storage/emulated/0/DrawingScanner';
```

当前直接使用外部存储根目录，与 Download、Documents 等系统文件夹同级。如需修改存储位置，请更改此路径。

### 权限请求流程

初始化时会自动请求 `MANAGE_EXTERNAL_STORAGE` 权限（第 33-56 行）。如果用户拒绝，会尝试打开应用设置页面。

### 平台差异处理

- **Android 13+**：使用 `READ_MEDIA_IMAGES` 权限访问相册
- **Android 12 及以下**：使用 `READ_EXTERNAL_STORAGE` 权限
- **iOS**：统一使用 `photos` 权限

### 图片质量设置

选择图片时压缩质量设置为 85（第 112 行）。如需调整图片质量，请修改 `imageQuality` 参数。

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `demo/lib/comp_src/pages/drawing_scanner_page.dart` | 图纸扫描页面，使用本服务选择和分析图片 |
| `demo/lib/comp_src/pages/drawing_search_page.dart` | 图纸搜索页面，使用本服务搜索归档记录 |
| `demo/pubspec.yaml` | 项目依赖配置文件 |
