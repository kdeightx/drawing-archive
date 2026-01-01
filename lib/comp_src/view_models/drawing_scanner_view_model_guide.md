# DrawingScannerViewModel 组件指南

## 组件职责

`DrawingScannerViewModel` 是图纸扫描页面的状态管理和业务逻辑层，使用 Provider 模式管理页面的所有状态：

- **图片管理**：支持单张/多张图片选择、删除、切换
- **AI 识别**：自动调用 AI 服务识别图纸编号
- **进度管理**：展示识别进度（发送数据、扫描中、完成）
- **编号管理**：管理编号输入、分页显示、AI 识别结果
- **旋转控制**：支持图片 90 度旋转（顺时针/逆时针）
- **缩放控制**：管理图片缩放和平移状态
- **数据持久化**：保存识别结果到本地存储
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
| `numberPage` | `int` | 编号列表当前页码 |
| `totalPages` | `int` | 编号列表总页数（计算属性）|
| `isAnalyzing` | `bool` | 是否正在分析（AI 识别中）|
| `isSaving` | `bool` | 是否正在保存 |
| `progressState` | `ProgressState?` | 当前进度状态（sending/scanning/completed）|
| `currentRotation` | `int` | 当前旋转角度（0/90/180/270）|
| `pickImage()` | `Future<void>` | 选择单张图片（相机）|
| `pickMultipleImages()` | `Future<bool>` | 选择多张图片（相册）|
| `analyzeImage()` | `Future<void>` | 分析单张图片 |
| `analyzeAllImages()` | `Future<void>` | 批量分析所有图片 |
| `saveAllImages()` | `Future<int>` | 保存所有图片 |
| `deleteImage()` | `Future<void>` | 删除指定图片 |
| `updateNumber()` | `void` | 更新图片编号 |
| `setCurrentImageIndex()` | `void` | 切换当前图片 |
| `previousPage()` / `nextPage()` | `void` | 编号列表翻页 |
| `rotateClockwise()` / `rotateCounterClockwise()` | `void` | 旋转图片 90 度 |
| `resetRotation()` | `void` | 重置旋转和缩放 |
| `reset()` | `Future<void>` | 重置页面所有状态 |

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
| `_numberPage` | `int` | 编号列表当前页码（每页 5 项）|
| `_isAnalyzing` | `bool` | 是否正在分析（AI 识别中）|
| `_isSaving` | `bool` | 是否正在保存到数据库 |
| `_progressState` | `ProgressState?` | 进度状态（控制进度指示器显示）|
| `_currentRotation` | `int` | 当前旋转角度（0/90/180/270）|

### 控制器

| 控制器 | 用途 |
|--------|------|
| `transformationController` | `TransformationController` - 控制图片缩放和平移（4x4 矩阵）|
| `pageController` | `PageController` - 控制全屏预览时图片左右滑动切换 |
| `scrollController` | `ScrollController` - 控制主页面滚动 |
| `actionCardKey` | `GlobalKey` - 操作区域的 GlobalKey，用于删除后滚动到视野内 |

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
            onCameraTap: viewModel.pickImage,
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

### 示例2：使用 ViewModel 控制全屏预览

```dart
// FullScreenImageViewer 使用 ViewModel 管理图片和旋转状态
class FullScreenImageViewer extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DrawingScannerViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // 显示当前图片
              Image.file(viewModel.selectedImages[viewModel.currentImageIndex]),
              // 顶部操作栏
              _buildTopAppBar(
                currentIndex: viewModel.currentImageIndex,
                totalCount: viewModel.selectedImages.length,
                onRotateLeft: viewModel.rotateCounterClockwise,
                onRotateRight: viewModel.rotateClockwise,
              ),
            ],
          );
        },
      ),
    );
  }
}

// 切换图片时调用
void _onPageChanged(int index) {
  viewModel.setCurrentImageIndex(index); // 重置旋转和缩放
  viewModel.resetRotation();
}
```

### 示例3：监听进度状态显示 UI

```dart
Widget _buildProgressIndicator(ProgressState? state) {
  if (state == null) return const SizedBox.shrink();

  String message;
  IconData icon;

  switch (state) {
    case ProgressState.sending:
      message = '正在发送数据...';
      icon = Icons.cloud_upload;
      break;
    case ProgressState.scanning:
      message = 'AI 正在识别...';
      icon = Icons.psychology;
      break;
    case ProgressState.completed:
      message = '识别完成！';
      icon = Icons.check_circle;
      break;
  }

  return SmartProcessStepper(
    currentStep: state == ProgressState.sending ? 0 : 1,
    steps: [
      Step(title: Text('发送数据'), icon: Icon(Icons.cloud_upload)),
      Step(title: Text('AI 识别'), icon: Icon(Icons.psychology)),
    ],
  );
}
```

---

## 核心功能

### 图片选择流程

```dart
// 1. 单张图片（相机）
await viewModel.pickImage();
// → 自动触发 AI 识别

// 2. 多张图片（相册）
final success = await viewModel.pickMultipleImages();
// → 自动批量识别所有图片
if (success) {
  print('选择了 ${viewModel.selectedImages.length} 张图片');
}
```

### AI 识别流程

```dart
// 单张图片识别
await viewModel.analyzeImage();
// 进度变化：sending → scanning → completed → null

// 批量识别（相册多选时自动调用）
await viewModel.analyzeAllImages();
// 依次识别每张图片，每张识别完成后更新 UI
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
```

### 旋转控制

```dart
// 顺时针旋转 90 度
viewModel.rotateClockwise();
// 0 → 90 → 180 → 270 → 0

// 逆时针旋转 90 度
viewModel.rotateCounterClockwise();
// 0 → 270 → 180 → 90 → 0

// 重置旋转和缩放
viewModel.resetRotation();
// currentRotation = 0, transformationController = identity
```

---

## 修改注意事项

### 分页计算逻辑

```dart
// 第 48 行：总页数计算
int get totalPages => (_selectedImages.length / numbersPerPage).ceil();

// 每页显示 5 项（第 45 行）
int get numbersPerPage => 5;

// 当前页码范围检查（第 291-304 行）
void previousPage() {
  if (_numberPage > 0) {  // 确保不小于 0
    _numberPage--;
    notifyListeners();
  }
}

void nextPage() {
  if (_numberPage < totalPages - 1) {  // 确保不超出最大页
    _numberPage++;
    notifyListeners();
  }
}
```

### 图片删除时的页码调整

```dart
// 第 260-275 行：删除图片时自动调整页码
Future<void> deleteImage(int index) async {
  _numberControllers[index].dispose();  // 先释放控制器
  _numberControllers.removeAt(index);
  _selectedImages.removeAt(index);
  _recognizedNumbers.removeAt(index);

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
// 第 143-179 行：分析单张图片
Future<void> analyzeImage() async {
  // 1. 设置进度为"发送数据"
  _progressState = ProgressState.sending;
  notifyListeners();
  await Future.delayed(const Duration(milliseconds: 500));  // 模拟延迟

  // 2. 设置进度为"扫描中"
  _progressState = ProgressState.scanning;
  notifyListeners();

  // 3. 调用 AI 服务
  final String number = await drawingService.analyzeImage(currentImage);

  // 4. 设置进度为"完成"
  _progressState = ProgressState.completed;
  _recognizedNumbers[_currentImageIndex] = number;
  _numberControllers[_currentImageIndex].text = number;
  notifyListeners();

  // 5. 延迟 3 秒后隐藏进度
  await Future.delayed(const Duration(seconds: 3));
  _progressState = null;
  _isAnalyzing = false;
  notifyListeners();
}
```

**注意事项**：
- 必须在每次状态变化后调用 `notifyListeners()`
- 进度状态会在完成后自动清除（3 秒延迟）
- 识别结果会同时更新 `_recognizedNumbers` 和 `_numberControllers[index].text`

### 资源释放管理

```dart
// 第 346-357 行：dispose 方法
@override
void dispose() {
  // 清理所有编号输入控制器
  for (var controller in _numberControllers) {
    controller.dispose();
  }
  // 清理其他控制器
  transformationController.dispose();
  pageController.dispose();
  scrollController.dispose();
  super.dispose();
}
```

**必须确保**：
- 所有 TextEditingController 在移除前先 dispose
- 页面销毁时调用 ViewModel 的 dispose
- 删除图片时释放对应的 TextEditingController

### 旋转状态重置时机

```dart
// 第 283-288 行：切换图片时重置旋转
void setCurrentImageIndex(int index) {
  _currentImageIndex = index;
  transformationController.value = Matrix4.identity();  // 重置缩放和平移
  notifyListeners();
}
```

**重置时机**：
- 切换图片时
- 页面重置时（`reset()` 方法）
- 全屏预览关闭时

### 保存前的验证

```dart
// 第 220-230 行：保存前检查所有编号
if (_selectedImages.isEmpty) {
  throw Exception('请先选择图片');
}

// 检查所有编号是否都已填写
for (int i = 0; i < _numberControllers.length; i++) {
  if (_numberControllers[i].text.trim().isEmpty) {
    throw Exception('请填写第 ${i + 1} 张图片的编号');
  }
}
```

**验证规则**：
- 必须至少选择一张图片
- 所有图片的编号都不能为空（trim() 后判断）

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/services/drawing_service.dart` | 图纸业务逻辑服务（图片选择、AI 识别、数据保存）|
| `lib/comp_src/pages/drawing_scanner_page.dart` | 使用 ViewModel 的主页面 |
| `lib/comp_src/widgets/action_card.dart` | 操作卡片组件，调用 ViewModel 的各种方法 |
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 全屏预览组件，使用 ViewModel 的图片和旋转状态 |
| `lib/comp_src/widgets/image_display_card.dart` | 图片展示卡片，显示进度状态 |
