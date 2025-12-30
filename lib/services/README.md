# DrawingService 组件指南

## 组件职责

`DrawingService` 是应用的核心业务逻辑层，负责处理与图纸相关的所有业务操作：

- **图片选择**：从相机或相册选择图片（单选/多选）
- **权限管理**：处理相机、相册、存储权限请求
- **AI识别**：分析图片并识别图纸编号（当前为模拟实现）
- **数据保存**：保存图纸归档记录（当前为模拟实现）
- **搜索查询**：搜索已归档的图纸记录（当前为模拟实现）

---

## 代码位置

```
lib/services/drawing_service.dart
```

---

## 输入与输出

### 输入（参数）

| 方法 | 参数 | 类型 | 说明 |
|------|------|------|------|
| `pickImage()` | `source` | `ImageSource` | 图片来源：`camera`（相机）或 `gallery`（相册） |
| `pickMultipleImages()` | 无 | - | - |
| `analyzeImage()` | `image` | `File` | 待分析的图片文件 |
| `saveEntry()` | `image` | `File` | 要保存的图片文件 |
| | `finalNumber` | `String` | 确认的图纸编号 |
| `searchDrawings()` | `keyword` | `String?` | 搜索关键词（可选） |
| | `startDate` | `DateTime?` | 开始日期（可选） |
| | `endDate` | `DateTime?` | 结束日期（可选） |
| | `ascending` | `bool` | 是否升序排序（默认true） |

### 输出（返回值）

| 方法 | 返回值 | 类型 | 说明 |
|------|--------|------|------|
| `pickImage()` | 图片文件或 null | `Future<File?>` | 成功返回 File，取消/失败返回 null |
| `pickMultipleImages()` | 图片文件列表 | `Future<List<File>>` | 返回选中的图片列表，失败返回空列表 |
| `analyzeImage()` | 图纸编号 | `Future<String>` | 返回识别出的图纸编号字符串 |
| `saveEntry()` | 无 | `Future<void>` | 保存完成无返回值 |
| `searchDrawings()` | 搜索结果列表 | `Future<List<DrawingEntry>>` | 返回符合条件的图纸条目列表 |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  image_picker: ^1.1.2       # 图片选择
  permission_handler: ^11.0.1  # 权限管理
  flutter:                    # Flutter SDK
```

### 内部依赖

```
无（纯业务逻辑层，不依赖其他页面或组件）
```

### 平台权限配置

**Android (`android/app/src/main/AndroidManifest.xml`)**:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

**iOS (`ios/Runner/Info.plist`)**:
```xml
<key>NSCameraUsageDescription</key>
<string>需要相机权限拍摄图纸</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择图纸</string>
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

### DrawingEntry（图纸条目）

```dart
class DrawingEntry {
  final String number;      // 图纸编号
  final DateTime date;      // 归档日期
  final String status;      // 状态标识（国际化key）
}
```

---

## 使用示例

### 示例1：从相机/相册选择图片

```dart
// 创建 DrawingService 实例
final DrawingService _drawingService = DrawingService();

// 从相机拍照
final File? image = await _drawingService.pickImage(ImageSource.camera);
if (image != null) {
  print('拍照成功: ${image.path}');
}

// 从相册多选
final List<File> images = await _drawingService.pickMultipleImages();
print('已选择 ${images.length} 张图片');
```

### 示例2：分析图片识别编号

```dart
final File image = File('/path/to/drawing.jpg');

// 调用AI识别（当前为模拟实现）
final String drawingNumber = await _drawingService.analyzeImage(image);
print('识别结果: $drawingNumber');
// 输出示例: "3.4567-7890"
```

### 示例3：保存和搜索归档记录

```dart
// 保存归档记录
final File image = File('/path/to/drawing.jpg');
await _drawingService.saveEntry(image, '1.1234-5678');

// 搜索已归档图纸
final results = await _drawingService.searchDrawings(
  keyword: '1.1234',
  startDate: DateTime(2024, 1, 1),
  ascending: true,
);
```

---

## 修改注意事项

### 🔴 重要提醒（TODO 功能）

以下功能当前为**模拟实现**，需要后续对接真实服务：

| 方法 | 行号 | 当前实现 | 待实现 |
|------|------|----------|--------|
| `analyzeImage()` | 118-126 | 返回随机编号 | 对接 OCR/AI 服务 |
| `saveEntry()` | 129-136 | 延时+打印 | 保存到数据库/服务器 |
| `searchDrawings()` | 139-151 | 返回固定数据 | 从数据库/服务器查询 |

### 权限处理逻辑

- Android 13+ 使用 `Permission.photos`
- Android 12 及以下使用 `Permission.storage`
- iOS 统一使用 `Permission.photos`
- 相机权限统一使用 `Permission.camera`

### 平台差异处理

```dart
// 第85-92行：相册权限平台差异
if (io.Platform.isAndroid) {
  permission = Permission.photos;  // Android 13+
} else {
  permission = Permission.photos;  // iOS
}
```

### 图片质量设置

```dart
// 第34行：图片质量设置（85%）
imageQuality: 85,
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/pages/drawing_scanner_page.dart` | 使用 DrawingService 的主要页面 |
| `lib/pages/drawing_search_page.dart` | 使用搜索功能的页面 |
| `pubspec.yaml` | 依赖配置文件 |
