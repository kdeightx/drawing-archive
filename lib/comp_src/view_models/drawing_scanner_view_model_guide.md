# DrawingScannerViewModel 组件指南

## 组件职责

`DrawingScannerViewModel` 是图纸扫描页面的状态管理和业务逻辑层，使用 Provider 模式管理页面的所有状态：

- **图片管理**：支持单张/多张图片选择、删除、切换、清空
- **AI 识别**：支持单张/批量识别，可重复上传未识别的图片
- **进度管理**：展示识别进度（发送数据、扫描中、完成）
- **编号管理**：管理编号输入、分页显示、AI 识别结果、识别失败状态
- **旋转控制**：支持图片 90 度旋转（顺时针/逆时针）
- **图片预览导航**：管理全屏图片预览的导航状态
- **数据持久化**：保存已识别的图片到本地存储
- **生命周期管理**：自动清理资源，防止内存泄漏

---

## 代码位置

```
lib/comp_src/view_models/drawing_scanner_view_model.dart
```

---

## 输入与输出

### 输入（构造参数）

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `drawingService` | `DrawingService` | 是 | 图纸业务逻辑服务实例 |

### 输出（状态和操作）

| 状态/操作 | 类型 | 说明 |
|----------|------|------|
| `selectedImages` | `List<File>` | 已选择的图片列表 |
| `currentImageIndex` | `int` | 当前查看的图片索引 |
| `recognizedNumbers` | `List<String>` | AI 识别的编号列表 |
| `numberControllers` | `List<TextEditingController>` | 编号输入控制器列表 |
| `recognitionFailedList` | `List<bool>` | 每张图片的识别失败状态 |
| `numberPage` | `int` | 编号列表当前页码 |
| `totalPages` | `int` | 编号列表总页数（计算属性）|
| `numbersPerPage` | `int` | 每页显示的编号数量（固定为 5）|
| `isAnalyzing` | `bool` | 是否正在分析（AI 识别中）|
| `analyzingIndex` | `int` | 当前正在识别的图片索引（-1 表示没有正在识别的图片）|
| `isSaving` | `bool` | 是否正在保存 |
| `progressState` | `ProgressState?` | 当前进度状态（sending/scanning/completed）|
| `aiRecognitionFailed` | `bool` | AI 识别是否失败（网络或 API 错误）|
| `currentRotation` | `int` | 当前旋转角度（0/90/180/270）|
| `shouldOpenImagePreview` | `bool` | 是否需要打开全屏图片预览（导航状态）|
| `previewImageIndex` | `int` | 要预览的图片索引 |
| `pickImage()` | `Future<void>` | 选择单张图片（相机），不自动触发识别 |
| `pickMultipleImages()` | `Future<bool>` | 选择多张图片（相册），不自动触发识别 |
| `uploadAndRecognizeAll()` | `Future<void>` | 上传并识别所有未识别的图片 |
| `analyzeImage()` | `Future<void>` | 分析单张图片（当前图片）|
| `analyzeAllImages()` | `Future<void>` | 批量分析所有图片（包括已识别的）|
| `saveAllImages()` | `Future<int>` | 保存所有有编号的图片 |
| `deleteImage()` | `Future<void>` | 删除指定图片 |
| `updateNumber()` | `void` | 更新图片编号 |
| `setCurrentImageIndex()` | `void` | 切换当前图片 |
| `previousPage()` / `nextPage()` | `void` | 编号列表翻页 |
| `rotateClockwise()` / `rotateCounterClockwise()` | `void` | 旋转图片 90 度 |
| `resetRotation()` | `void` | 重置旋转角度 |
| `onImageTapped()` | `void` | 用户点击图片，请求打开全屏预览 |
| `clearImagePreviewState()` | `void` | 清除图片预览导航状态 |
| `reset()` | `Future<void>` | 重置页面所有状态 |
| `clearAllImages()` | `Future<void>` | 清空所有图片（删除临时文件并重置页面）|

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
```

### 内部依赖

```
lib/comp_src/services/drawing_service.dart  # 图纸业务逻辑服务（图片选择、AI 识别、数据保存）
```

---

## 数据模型

### ProgressState（进度状态枚举）

```dart
enum ProgressState {
  sending,    // 发送数据中
  scanning,   // AI 扫描中
  completed,  // 扫描完成
}
```

用于控制进度指示器显示不同的状态。

---

## 状态管理

### 主要状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `_selectedImages` | `List<File>` | 已选择的图片文件列表 |
| `_currentImageIndex` | `int` | 当前查看/编辑的图片索引 |
| `_recognizedNumbers` | `List<String>` | AI 识别的编号列表（与图片一一对应）|
| `_numberControllers` | `List<TextEditingController>` | 编号输入框控制器（支持手动编辑）|
| `_recognitionFailedList` | `List<bool>` | 每张图片的识别失败状态（与图片一一对应）|
| `_numberPage` | `int` | 编号列表当前页码（每页 5 项）|
| `_isAnalyzing` | `bool` | 是否正在分析（AI 识别中）|
| `_analyzingIndex` | `int` | 当前正在识别的图片索引（-1 表示无）|
| `_isSaving` | `bool` | 是否正在保存到数据库 |
| `_progressState` | `ProgressState?` | 进度状态（控制进度指示器显示）|
| `_aiRecognitionFailed` | `bool` | AI 识别是否失败（网络或 API 错误）|
| `_currentRotation` | `int` | 当前旋转角度（0/90/180/270）|
| `_shouldOpenImagePreview` | `bool` | 是否需要打开全屏图片预览（导航状态）|
| `_previewImageIndex` | `int` | 要预览的图片索引 |

---

## 使用示例

### 示例1：在页面中提供 ViewModel

```dart
class DrawingScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DrawingScannerViewModel(
        drawingService: context.read<DrawingService>(),
      ),
      child: _DrawingScannerContent(),
    );
  }
}

class _DrawingScannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DrawingScannerViewModel>();

    return Scaffold(
      body: Column(
        children: [
          if (viewModel.isAnalyzing)
            _buildProgressIndicator(viewModel.progressState),
          ActionCard(
            onCameraTap: () => viewModel.pickImage(),
            onGalleryTap: () async {
              await viewModel.pickMultipleImages();
            },
            numberItems: _buildNumberItems(viewModel),
            currentPage: viewModel.numberPage,
            totalPages: viewModel.totalPages,
            onNumberChange: (index) => viewModel.updateNumber(index, ''),
            onDeleteTap: (index) => viewModel.deleteImage(index),
            onPreviousPage: viewModel.numberPage > 0 ? viewModel.previousPage : null,
            onNextPage: viewModel.numberPage < viewModel.totalPages - 1 ? viewModel.nextPage : null,
            onUpload: viewModel.uploadAndRecognizeAll,
            onClearAll: viewModel.clearAllImages,
            onSave: viewModel.saveAllImages,
            isSaving: viewModel.isSaving,
            isAnalyzing: viewModel.isAnalyzing,
          ),
        ],
      ),
    );
  }
}
```

### 示例2：图片预览导航（MVVM 架构）

```dart
// ViewModel 中设置导航状态
viewModel.onImageTapped(2);  // 用户点击第3张图片

// View 中监听导航状态并执行导航
Consumer<DrawingScannerViewModel>(
  builder: (context, viewModel, child) {
    if (viewModel.shouldOpenImagePreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final imagePaths = viewModel.selectedImages
            .map((f) => f.path)
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              imagePaths: imagePaths,
              initialIndex: viewModel.previewImageIndex,
            ),
          ),
        ).then((_) {
          // 预览关闭后清除状态
          viewModel.clearImagePreviewState();
        });
      });
    }

    return ImageDisplayCard(
      images: viewModel.selectedImages,
      currentIndex: viewModel.currentImageIndex,
      onIndexChange: (index) => viewModel.setCurrentImageIndex(index),
      onImageTap: (index) => viewModel.onImageTapped(index),
    );
  },
)
```

### 示例3：上传识别流程

```dart
// 选择图片后手动触发识别
Future<void> _handleUpload() async {
  try {
    // 识别所有未识别的图片
    await viewModel.uploadAndRecognizeAll();
    print('识别完成');
  } catch (e) {
    print('识别失败：$e');
  }
}

// uploadAndRecognizeAll() 的行为：
// 1. 找出所有还没有识别结果的图片（recognizedNumbers[index].isEmpty）
// 2. 如果所有图片都已识别，直接返回（不重复识别）
// 3. 逐个识别未识别的图片，每张图片单独处理异常
// 4. 显示进度：发送数据 → AI扫描中 → 完成
// 5. 如果全部失败，抛出异常提示用户
```

### 示例4：识别失败状态处理

```dart
// 构建编号项列表时传递识别失败状态
List<NumberItem> _buildNumberItems(DrawingScannerViewModel viewModel) {
  return List.generate(viewModel.selectedImages.length, (index) {
    return NumberItem(
      id: 'img_$index',
      image: viewModel.selectedImages[index],
      index: index,
      number: viewModel.recognizedNumbers[index],
      hasAiNumber: viewModel.recognizedNumbers[index].isNotEmpty,
      recognitionFailed: viewModel.recognitionFailedList[index],
    );
  });
}

// ActionCard 会根据 recognitionFailed 显示不同的提示文字：
// - recognitionFailed = true: 显示 "识别失败"
// - recognitionFailed = false: 显示 "输入图纸编号"
```

### 示例5：保存已识别的图片

```dart
// saveAllImages() 只保存有编号的图片
try {
  final count = await viewModel.saveAllImages();
  print('成功保存 $count 张已识别的图片');
  // 保存成功后自动清理临时图片并重置页面
} catch (e) {
  if (e.toString().contains('没有已识别的图片')) {
    print('请先进行识别或手动填写编号');
  } else {
    print('保存失败：$e');
  }
}
```

---

## 核心功能

### 图片选择流程

```dart
// 1. 单张图片（相机）
await viewModel.pickImage();
// → 不会自动触发识别，需要手动调用 uploadAndRecognizeAll()

// 2. 多张图片（相册）
final success = await viewModel.pickMultipleImages();
if (success) {
  print('选择了 ${viewModel.selectedImages.length} 张图片');
  // 不会自动触发识别，需要手动调用 uploadAndRecognizeAll()
}
```

### AI 识别流程

```dart
// 方式 1：上传识别所有未识别的图片（推荐）
await viewModel.uploadAndRecognizeAll();
// - 只识别未识别的图片
// - 跳过已识别的图片
// - 每张图片独立处理异常，失败继续下一张

// 方式 2：识别当前图片
await viewModel.analyzeImage();
// - 识别 _currentImageIndex 对应的图片

// 方式 3：批量识别所有图片（包括已识别的）
await viewModel.analyzeAllImages();
// - 重新识别所有图片（不推荐）
```

### 保存流程

```dart
try {
  final count = await viewModel.saveAllImages();
  print('成功保存 $count 张图片');
  // 保存成功后自动清理临时图片并重置页面
} catch (e) {
  print('保存失败：$e');
}

// saveAllImages() 的行为：
// 1. 找出所有有编号的图片（_numberControllers[index].text.trim().isNotEmpty）
// 2. 只保存有编号的图片（跳过未识别且未手动填写的）
// 3. 如果没有有编号的图片，抛出异常
// 4. 保存成功后清理所有临时图片并重置页面
```

### 旋转控制

```dart
// 顺时针旋转 90 度
viewModel.rotateClockwise();
// 0 → 90 → 180 → 270 → 0

// 逆时针旋转 90 度
viewModel.rotateCounterClockwise();
// 0 → 270 → 180 → 90 → 0

// 重置旋转
viewModel.resetRotation();
// currentRotation = 0
```

### 图片预览导航（MVVM 架构）

```dart
// ViewModel 层：导航决策
void onImageTapped(int index) {
  debugPrint('📸 用户点击了图片 $index，准备打开全屏预览');

  _previewImageIndex = index;
  _shouldOpenImagePreview = true;
  notifyListeners();
}

// View 层：监听状态并执行导航
if (viewModel.shouldOpenImagePreview) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: viewModel.selectedImages.map((f) => f.path).toList(),
          initialIndex: viewModel.previewImageIndex,
        ),
      ),
    ).then((_) {
      viewModel.clearImagePreviewState();
    });
  });
}
```

---

## 修改注意事项

### 识别失败处理机制

```dart
// 第 193-227 行：逐个识别，每张图片独立处理异常
for (int index in pendingIndexes) {
  _analyzingIndex = index;  // 标记正在识别的图片
  notifyListeners();

  try {
    final String number = await drawingService.analyzeImage(_selectedImages[index], shouldCopy: false);
    _recognizedNumbers[index] = number;
    _numberControllers[index].text = number;
    _recognitionFailedList[index] = false;  // 识别成功
    successCount++;
  } catch (e) {
    failureCount++;
    _recognitionFailedList[index] = true;  // 标记识别失败
    // 继续识别下一张图片，不中断流程
    continue;
  }

  notifyListeners();
}
```

**关键点**：
- try-catch 在循环内部，每张图片独立处理
- 识别失败时设置 `_recognitionFailedList[index] = true`
- 使用 `continue` 继续下一张，不中断整个流程
- 如果全部失败，在循环结束后抛出异常

### 保存逻辑变化

```dart
// 第 439-449 行：只保存有编号的图片
final List<int> validIndexes = [];
for (int i = 0; i < _selectedImages.length; i++) {
  if (_numberControllers[i].text.trim().isNotEmpty) {
    validIndexes.add(i);
  }
}

if (validIndexes.isEmpty) {
  throw Exception('没有已识别的图片可保存，请先进行识别或手动填写编号');
}

// 只保存有编号的图片
for (int index in validIndexes) {
  final number = _numberControllers[index].text.trim();
  await drawingService.saveEntry(_selectedImages[index], number);
  successCount++;
}
```

**关键点**：
- 跳过未识别且未手动填写的图片
- 允许用户手动填写编号后保存
- 如果没有任何图片有编号，抛出异常提示用户

### 分页计算逻辑

```dart
// 第 52 行：总页数计算
int get totalPages => (_selectedImages.length / numbersPerPage).ceil();

// 每页显示 5 项（第 49 行）
int get numbersPerPage => 5;

// 当前页码范围检查
void previousPage() {
  if (_numberPage > 0) {
    _numberPage--;
    notifyListeners();
  }
}

void nextPage() {
  if (_numberPage < totalPages - 1) {
    _numberPage++;
    notifyListeners();
  }
}
```

### 图片删除时的页码调整

```dart
// 第 488-508 行：删除图片时自动调整页码和索引
Future<void> deleteImage(int index) async {
  // 先删除临时文件
  await drawingService.deleteTempImage(_selectedImages[index]);

  // 再从列表中移除
  _numberControllers[index].dispose();
  _numberControllers.removeAt(index);
  _selectedImages.removeAt(index);
  _recognizedNumbers.removeAt(index);
  _recognitionFailedList.removeAt(index);

  // 调整当前图片索引
  if (_currentImageIndex >= _selectedImages.length) {
    _currentImageIndex = _selectedImages.length - 1;
  }

  // 调整页码（如果当前页超出范围）
  if (_numberPage > 0 && (_numberPage * numbersPerPage) >= _selectedImages.length) {
    _numberPage--;
  }

  notifyListeners();
}
```

### AI 识别的进度管理

```dart
// 第 176-241 行：上传识别流程的进度管理
_isAnalyzing = true;
notifyListeners();

// 显示进度：发送数据
_progressState = ProgressState.sending;
notifyListeners();
await Future.delayed(const Duration(milliseconds: 500));

// 显示进度：AI扫描中
_progressState = ProgressState.scanning;
notifyListeners();

// 逐个识别...

// 显示进度：完成
_progressState = ProgressState.completed;
_analyzingIndex = -1;  // 清除正在识别的标记
notifyListeners();

// 3秒后恢复到非活跃状态
await Future.delayed(const Duration(seconds: 3));
_progressState = null;
_isAnalyzing = false;
_aiRecognitionFailed = hasApiError;  // 如果有API错误，标记失败
notifyListeners();
```

**注意事项**：
- 必须在每次状态变化后调用 `notifyListeners()`
- 进度状态会在完成后自动清除（3 秒延迟）
- `_analyzingIndex` 用于 UI 显示当前正在识别的图片
- `_aiRecognitionFailed` 用于标记是否有 API 错误

### 导航状态管理（MVVM 架构）

```dart
// 第 517-530 行：图片预览导航相关方法

// ViewModel 决策导航
void onImageTapped(int index) {
  debugPrint('📸 用户点击了图片 $index，准备打开全屏预览');

  _previewImageIndex = index;
  _shouldOpenImagePreview = true;
  notifyListeners();
}

// 清除导航状态
void clearImagePreviewState() {
  _shouldOpenImagePreview = false;
  notifyListeners();
}
```

**MVVM 职责划分**：
- **ViewModel**：决定何时导航（设置 `_shouldOpenImagePreview = true`）
- **View**：执行导航（监听状态并调用 `Navigator.push()`）
- **Widget**：通知用户交互（通过 `onImageTap` 回调）

### 资源释放管理

```dart
// 第 602-609 行：dispose 方法
@override
void dispose() {
  // 清理所有编号输入控制器
  for (var controller in _numberControllers) {
    controller.dispose();
  }
  super.dispose();
}
```

**必须确保**：
- 所有 TextEditingController 在移除前先 dispose
- 页面销毁时调用 ViewModel 的 dispose
- 删除图片时释放对应的 TextEditingController

### 旋转状态重置时机

```dart
// 第 552-557 行：重置旋转角度
void resetRotation() {
  _currentRotation = 0;
  notifyListeners();
}
```

**重置时机**：
- 页面重置时（`reset()` 方法）
- 全屏预览关闭时

**注意**：不再重置 transformationController，因为已移除缩放功能

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/services/drawing_service.dart` | 图纸业务逻辑服务（图片选择、AI 识别、数据保存）|
| `lib/comp_src/pages/drawing_scanner_page.dart` | 使用 ViewModel 的主页面 |
| `lib/comp_src/widgets/action_card.dart` | 操作卡片组件，调用 ViewModel 的各种方法 |
| `lib/comp_src/widgets/image_display_card.dart` | 图片显示卡片，支持点击预览 |
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 全屏预览组件，使用 ViewModel 的图片和旋转状态 |
