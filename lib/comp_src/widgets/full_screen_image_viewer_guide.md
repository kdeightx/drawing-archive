# FullScreenImageViewer 组件指南

## 组件职责

`FullScreenImageViewer` 是全屏图片预览组件，使用 Flutter 内置的 `InteractiveViewer` 实现系统相册级的图片查看体验：

- **全屏预览**：黑色背景的全屏图片查看器
- **多图浏览**：使用 PageView 支持左右滑动切换图片
- **手势缩放**：双指缩放，以手指位置为中心
- **双击缩放**：双击任意位置放大/还原（以点击位置为中心）
- **无边界拖动**：缩放后支持无边界自由拖拽
- **沉浸式交互**：单击屏幕隐藏/显示 UI 和状态栏
- **智能手势路由**：缩放前滑动翻页，缩放后锁定翻页、自由拖动
- **无限缩放**：支持从 0.01x 到无限大的缩放范围
- **空列表保护**：处理空图片列表，显示友好提示

---

## 代码位置

```
lib/comp_src/widgets/full_screen_image_viewer.dart
```

---

## 输入与输出

### 输入（构造参数）

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `imagePaths` | `List<String>` | 是 | - | 图片文件路径列表 |
| `initialIndex` | `int` | 否 | 0 | 初始显示的图片索引 |

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 显示全屏预览 | 打开全屏黑色背景的图片查看器 |
| 单击切换 UI | 单击屏幕隐藏/显示顶部和底部操作栏 |
| 返回上一页 | 点击左上角返回按钮关闭预览 |
| 双击缩放 | 双击任意位置放大到 2.5x 或还原到 1.0x |
| 双指缩放 | 双指捏合缩放，支持从 0.01x 到无限大 |
| 拖动图片 | 缩放状态下无边界自由拖动 |
| 切换图片 | 未缩放时左右滑动切换上一张/下一张 |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  extended_image: ^8.2.1  # 仅用于图片加载，不处理手势
```

### 内部依赖

无（极简架构，所有逻辑在单文件内）

---

## 状态管理

### 主要状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `_pageController` | `PageController` | 控制 PageView 图片左右滑动 |
| `_currentIndex` | `int` | 当前页面索引（用于显示页码） |
| `_showControls` | `bool` | 控制 UI 是否显示（沉浸式交互） |
| `_enablePageScroll` | `bool` | 控制 PageView 是否可翻页（缩放时锁定） |

### 子组件状态变量（_ZoomableImageItem）

| 变量 | 类型 | 说明 |
|------|------|------|
| `_transformController` | `TransformationController` | 控制 InteractiveViewer 的变换矩阵 |
| `_isZoomed` | `bool` | 当前是否处于缩放状态 |
| `_doubleTapDetails` | `TapDownDetails?` | 双击位置信息 |
| `_singleTapTimer` | `Timer?` | 单击防抖定时器 |

---

## 核心实现

### 1. 动态物理控制（第 126-131 行）

**核心逻辑**：根据缩放状态动态切换 PageView 的物理特性

```dart
physics: _enablePageScroll
    ? const BouncingScrollPhysics()
    : const NeverScrollableScrollPhysics(),
```

- **未缩放时** (`_enablePageScroll = true`)：使用 `BouncingScrollPhysics`，允许翻页
- **缩放时** (`_enablePageScroll = false`)：使用 `NeverScrollableScrollPhysics`，锁定翻页

### 2. 缩放状态检测（第 289-303 行）

**双状态检测**：同时检测放大和缩小状态

```dart
void _onTransformationChange() {
  final double scale = _transformController.value.getMaxScaleOnAxis();
  // 设置容差范围：scale < 0.99 或 scale > 1.01 都认为是缩放状态
  final bool isZoomedNow = scale < 0.99 || scale > 1.01;

  if (_isZoomed != isZoomedNow) {
    setState(() {
      _isZoomed = isZoomedNow;
    });
    // 通知父组件更新 PageView 的物理锁
    widget.onZoomStatusChanged(isZoomedNow);
  }
}
```

### 3. 全状态双击归位（第 305-343 行）

**智能归位**：从任意缩放状态（放大或缩小）双击都能还原到 1.0x

```dart
void _handleDoubleTap() {
  final double currentScale = _transformController.value.getMaxScaleOnAxis();
  final Offset tapPosition = _doubleTapDetails!.localPosition;

  Matrix4 endMatrix;
  // 如果不在 1.0 的容差范围内（即已放大或已缩小），还原到 1.0
  if (currentScale < 0.99 || currentScale > 1.01) {
    endMatrix = Matrix4.identity();
  } else {
    // 如果是 1.0 状态，放大到 2.5 倍（以点击位置为中心）
    final double targetScale = _doubleTapScale;
    final double dx = -tapPosition.dx * (targetScale - 1);
    final double dy = -tapPosition.dy * (targetScale - 1);

    endMatrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(targetScale);
  }
  // ... 启动动画
}
```

### 4. InteractiveViewer 配置（第 360-376 行）

**手势路由控制**：通过 `panEnabled` 控制手势路由

```dart
InteractiveViewer(
  transformationController: _transformController,
  minScale: 0.01,           // 允许缩小到很小
  maxScale: double.infinity, // 允许无限放大
  boundaryMargin: const EdgeInsets.all(double.infinity), // 始终无限边界
  panEnabled: _isZoomed,     // 只有缩放时才响应平移
  scaleEnabled: true,        // 始终允许缩放
  child: ExtendedImage.file(
    File(widget.imagePath),
    fit: BoxFit.contain,
    mode: ExtendedImageMode.none,  // 禁用 extended_image 的手势
    enableLoadState: true,
  ),
)
```

**手势路由逻辑**：
- **1.0x 时**：`panEnabled = false` → InteractiveViewer 不处理平移 → 手势穿透给 PageView → 翻页
- **缩放时**：`panEnabled = true` → InteractiveViewer 处理平移 → 自由拖动 → PageView 锁定

### 5. 空列表保护（第 115-122 行）

```dart
if (widget.imagePaths.isEmpty) {
  return const Center(
    child: Text(
      '暂无图片',
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  );
}
```

### 6. 沉浸式交互（第 73-84 行）

```dart
void _toggleControls() {
  setState(() {
    _showControls = !_showControls;
    if (_showControls) {
      _animationController.forward();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      _animationController.reverse();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  });
}
```

---

## 使用示例

### 示例 1：从 ActionCard 打开全屏预览

```dart
// 在 ActionCard 组件中点击缩略图打开全屏预览
void _showFullScreenPreview(BuildContext context, int index) {
  final viewModel = context.read<DrawingScannerViewModel>();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => FullScreenImageViewer(
        imagePaths: viewModel.selectedImages
            .map((file) => file.path)
            .toList(),
        initialIndex: index,
      ),
    ),
  );
}
```

### 示例 2：从 DrawingSearchPage 打开全屏预览

```dart
// 在搜索页面点击搜索结果卡片打开全屏预览
void _handleResultTap(int index) {
  final entry = _results[index];
  final imagePath = entry.filePath;

  // 验证文件是否存在
  final file = io.File(imagePath);
  if (!file.existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('文件不存在: $imagePath')),
    );
    return;
  }

  // 打开全屏图片查看器
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullScreenImageViewer(
        imagePaths: _results.map((e) => e.filePath).toList(),
        initialIndex: index,
      ),
    ),
  );
}
```

### 示例 3：仅显示单张图片

```dart
// 打开单张图片的预览
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FullScreenImageViewer(
      imagePaths: ['/path/to/image.jpg'],
      initialIndex: 0,
    ),
  ),
);
```

---

## 架构说明

### 组件结构

```
FullScreenImageViewer (父组件)
    ├── PageView.builder (多图滑动)
    │   └── _ZoomableImageItem (单个可缩放图片)
    │       ├── GestureDetector (双击/单击检测)
    │       └── InteractiveViewer (缩放/平移)
    │           └── ExtendedImage.file (图片加载)
    ├── _buildTopBar (顶部工具栏)
    └── _buildBottomIndicator (底部提示)
```

### 状态提升（State Lifting）

子组件 `_ZoomableImageItem` 通过回调通知父组件缩放状态变化：

```dart
// 父组件定义回调
void _onZoomStatusChanged(bool isZoomed) {
  if (_enablePageScroll == !isZoomed) {
    setState(() {
      _enablePageScroll = !isZoomed;
    });
  }
}

// 子组件调用回调
widget.onZoomStatusChanged(isZoomedNow);
```

### 数据流向

```
调用者（ActionCard / DrawingSearchPage）
    ↓ 提供数据
Navigator.push(context, MaterialPageRoute(...))
    ↓ 传递参数
FullScreenImageViewer
    ├── imagePaths: List<String>
    └── initialIndex: int
        ↓ 渲染
    PageView.builder
        └── _ZoomableImageItem (每个图片)
            └── InteractiveViewer (手势处理)
```

---

## 交互流程

### 场景 1：查看多张图片

```
1. 打开图片查看器
2. 左右滑动 → 切换图片（未缩放时）
3. 单击屏幕 → 隐藏/显示 UI
4. 点击返回按钮 → 关闭查看器
```

### 场景 2：缩放查看细节

```
1. 双击图片 → 放大到 2.5x（以点击位置为中心）
2. 拖动图片 → 查看不同区域
3. 再次双击 → 还原到 1.0x
```

### 场景 3：双指缩放

```
1. 双指捏合 → 缩小到 0.5x
2. 继续捏合 → 缩小到 0.1x
3. 双指张开 → 放大到 5x
4. 继续张开 → 放大到 50x（无限放大）
```

### 场景 4：手势路由切换

```
1. 初始状态 (1.0x)
   - 左右滑动 → 翻页
   - 拖动无效 → 不触发平移

2. 双击放大 (2.5x)
   - PageView 锁定 → 无法翻页
   - 拖动生效 → 自由移动图片
   - 滑到边缘 → 不会翻页

3. 双击还原 (1.0x)
   - PageView 解锁 → 恢复翻页
   - 拖动无效 → 恢复翻页
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 组件代码（单文件） |
| `lib/comp_src/widgets/action_card.dart` | 使用此组件（主页面） |
| `lib/comp_src/pages/drawing_search_page.dart` | 使用此组件（搜索页面） |
| `pubspec.yaml` | extended_image 依赖配置 |
| `integration_test/image_preview_test.dart` | 集成测试 |
