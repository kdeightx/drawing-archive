# FullScreenImageViewer 组件指南

## 组件职责

`FullScreenImageViewer` 是全屏图片预览组件，提供专业级的图片查看体验：

- **全屏预览**：黑色背景的全屏图片查看器
- **多图浏览**：支持左右滑动切换图片
- **手势缩放**：双指缩放（0.5x - 4.0x），以手指位置为中心
- **手势旋转**：双指自由旋转图片
- **手势拖动**：双指拖动查看图片不同区域
- **双击放大**：双击以点击位置为中心放大到 2 倍，再次双击恢复
- **按钮旋转**：顶部操作栏支持 90 度增量旋转
- **沉浸式交互**：单击屏幕隐藏/显示 UI 和状态栏
- **智能切换**：缩放时自动禁用滑动切换，防止误操作

---

## 代码位置

```
lib/comp_src/widgets/full_screen_image_viewer.dart
```

---

## 输入与输出

### 输入（构造参数）

无构造参数。通过 `Provider` 获取 `DrawingScannerViewModel`。

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 显示全屏预览 | 打开全屏黑色背景的图片查看器 |
| 单击切换 UI | 单击屏幕隐藏/显示顶部和底部操作栏 |
| 返回上一页 | 点击左上角返回按钮关闭预览 |
| 旋转图片 | 点击旋转按钮或使用双指旋转手势 |
| 缩放图片 | 双击放大或使用双指缩放手势 |
| 切换图片 | 左右滑动切换到上一张/下一张图片 |
| 拖动图片 | 双指拖动查看图片不同区域 |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
```

### 内部依赖

```
lib/comp_src/view_models/drawing_scanner_view_model.dart  # 提供图片数据和旋转状态
```

---

## 状态管理

### 主要状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `_transformationController` | `TransformationController` | 控制图片的缩放和平移变换 |
| `_pageController` | `PageController` | 控制图片左右滑动切换 |
| `_animationController` | `AnimationController` | 控制缩放动画 |
| `_animation` | `Animation<Matrix4>?` | 存储矩阵动画实例 |
| `_transformKey` | `GlobalKey` | 用于双击时的坐标转换 |
| `_initialFocalPoint` | `Offset?` | 手势开始时的焦点位置 |
| `_initialMatrix` | `Matrix4?` | 手势开始时的变换矩阵 |
| `_showControls` | `bool` | 控制 UI 是否显示（沉浸式交互） |

### 控制器

| 控制器 | 用途 |
|--------|------|
| `TransformationController` | 存储 4x4 变换矩阵，控制图片的缩放、旋转、平移 |
| `PageController` | 管理图片的左右滑动切换，初始位置为当前图片索引 |
| `AnimationController` | 驱动缩放动画，持续 300ms，使用 easeInOut 曲线 |

---

## 使用示例

### 示例1：从 ActionCard 打开全屏预览

```dart
// 在 ActionCard 组件中点击缩略图打开全屏预览
void _showFullScreenPreview(BuildContext context, int index) {
  final viewModel = context.read<DrawingScannerViewModel>();
  viewModel.setCurrentImageIndex(index);
  viewModel.resetRotation();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const FullScreenImageViewer(),
      ),
    ),
  );
}
```

### 示例2：使用 Provider 传递状态

```dart
// FullScreenImageViewer 自动从 Provider 获取图片列表和旋转状态
// ViewModel 需要提供：
// - selectedImages: List<File> 图片列表
// - currentImageIndex: int 当前图片索引
// - currentRotation: int 当前旋转角度（0, 90, 180, 270）
// - rotateClockwise(): void 顺时针旋转 90 度
// - rotateCounterClockwise(): void 逆时针旋转 90 度
// - resetRotation(): void 重置旋转和缩放
// - setCurrentImageIndex(int): void 设置当前图片索引

class DrawingScannerViewModel extends ChangeNotifier {
  List<File> selectedImages = [];
  int currentImageIndex = 0;
  int currentRotation = 0;

  void rotateClockwise() {
    currentRotation = (currentRotation + 90) % 360;
    notifyListeners();
  }
}
```

### 示例3：手势交互说明

```dart
// 单击屏幕 → 隐藏/显示顶部和底部操作栏
// 双击屏幕 → 以点击位置为中心放大/恢复
// 双指缩放 → 以手指位置为中心缩放图片
// 双指旋转 → 自由旋转图片
// 双指拖动 → 移动图片查看不同区域
// 左右滑动 → 切换到上一张/下一张图片（缩放 ≤ 1.0 时）
// 点击返回按钮 → 关闭全屏预览
```

---

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| `_buildImageContent` | 95-142行 | 构建图片内容区域，包含 PageView 和手势检测 |
| `_buildRotatedImage` | 224-239行 | 构建可旋转的图片容器，使用 RotatedBox 实现 90 度旋转 |
| `_buildGestureImage` | 241-326行 | 构建带手势的图片，支持双指缩放、旋转、拖动 |
| `_buildTopAppBar` | 328-404行 | 构建顶部操作栏，包含返回按钮、旋转按钮、图片编号 |
| `_buildBottomIndicator` | 406-457行 | 构建底部圆点指示器，显示当前图片位置 |

---

## 修改注意事项

### 沉浸式交互配置

```dart
// 第 118-129 行：单击切换 UI 显示/隐藏
onTap: () {
  setState(() {
    _showControls = !_showControls;
  });
  // 配合系统沉浸式模式（隐藏/显示顶部状态栏）
  if (_showControls) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
}
```

### 手势优先级处理

```dart
// 第 109-111 行：缩放时禁止滑动切换
physics: _allowPageScroll
    ? const AlwaysScrollableScrollPhysics()
    : const NeverScrollableScrollPhysics(),
```

缩放比例 > 1.01 时，禁用 PageView 的滑动切换，避免误操作。

### 双击放大实现

```dart
// 第 144-163 行：双击放大到点击位置
void _handleDoubleTap(Offset globalFocalPoint) {
  final RenderBox? renderBox = _transformKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  // 关键：将屏幕坐标转换为组件局部坐标
  final Offset localFocalPoint = renderBox.globalToLocal(globalFocalPoint);

  final currentScale = _transformationController.value.getMaxScaleOnAxis();
  if (currentScale > 1.0) {
    _animateToScale(1.0); // 已放大，恢复原状
  } else {
    _animateToScaleAtPoint(2.0, localFocalPoint, renderBox); // 放大到 2 倍
  }
}
```

### 坐标系转换

```dart
// 第 152-154 行：屏幕坐标 → 局部坐标
final Offset localFocalPoint = renderBox.globalToLocal(globalFocalPoint);
```

这一步自动处理了旋转、平移带来的坐标系变化，确保双击放大功能在任何变换状态下都能正常工作。

### 矩阵变换顺序

```dart
// 第 272-293 行：双指手势的矩阵变换
// 步骤 A: 平移
matrix.translate(translationDelta.dx, translationDelta.dy, 0.0);

// 步骤 B: 定点缩放与旋转（"三明治"方法）
// B.1 将坐标原点移动到手指按下的位置
matrix.translate(focalPoint.dx, focalPoint.dy, 0.0);

// B.2 应用旋转和缩放
matrix.rotateZ(rotation);
matrix.scale(scale, scale, scale);

// B.3 将坐标原点恢复回去
matrix.translate(-focalPoint.dx, -focalPoint.dy, 0.0);
```

**变换顺序很重要**：先平移 → 再以焦点为中心缩放旋转 → 最后恢复坐标系。

### GlobalKey 重复使用修复

```dart
// 第 244 行：只为当前页绑定 GlobalKey
key: index == viewModel.currentImageIndex ? _transformKey : null
```

避免在 PageView 的多个页面中使用同一个 GlobalKey 导致的错误。

### 旋转实现方式

```dart
// 第 229-237 行：使用 RotatedBox 实现旋转
RotatedBox(
  quarterTurns: viewModel.currentRotation ~/ 90,
  child: SizedBox(
    width: isRotated ? size.height : size.width,
    height: isRotated ? size.width : size.height,
    child: _buildGestureImage(viewModel, index),
  ),
)
```

使用 `RotatedBox` 而不是 `Transform.rotate`，确保旋转后图片自动适应屏幕布局。

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/view_models/drawing_scanner_view_model.dart` | 提供图片数据和旋转状态管理 |
| `lib/comp_src/widgets/action_card.dart` | 调用 FullScreenImageViewer 的入口组件 |
