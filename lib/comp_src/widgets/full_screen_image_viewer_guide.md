# FullScreenImageViewer 组件指南

## 组件职责

`FullScreenImageViewer` 是全屏图片预览组件，使用自定义手势系统实现系统相册级的图片查看体验：

- **全屏预览**：黑色背景的全屏图片查看器
- **多图浏览**：使用 PageView 支持左右滑动切换图片
- **双指旋转**：支持双指旋转手势，任意角度旋转图片
- **双指缩放**：双指捏合缩放，支持从 0.01x 到无限大
- **双击缩放**：双击任意位置放大/还原（以点击位置为中心）
- **无限拖动**：缩放/旋转后支持无边界自由拖拽
- **沉浸式交互**：单击屏幕隐藏/显示 UI 和状态栏
- **智能手势路由**：缩放前滑动翻页，缩放后锁定翻页、自由拖动
- **差分算法**：解决单指/双指切换时的图片跳动问题
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
| 双指旋转 | 双指旋转，支持任意角度 |
| 拖动图片 | 缩放/旋转状态下无边界自由拖动 |
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

### 父组件状态变量（FullScreenImageViewer）

| 变量 | 类型 | 说明 |
|------|------|------|
| `_pageController` | `PageController` | 控制 PageView 图片左右滑动 |
| `_currentIndex` | `int` | 当前页面索引（用于显示页码） |
| `_showControls` | `bool` | 控制 UI 是否显示（沉浸式交互） |
| `_enablePageScroll` | `bool` | 控制 PageView 是否可翻页（缩放时锁定） |
| `_uiAnimController` | `AnimationController` | UI 显示/隐藏动画控制器 |
| `_uiOpacityAnim` | `Animation<double>` | UI 透明度动画 |

### 子组件状态变量（_GestureImageItem）

| 变量 | 类型 | 说明 |
|------|------|------|
| `_transformController` | `TransformationController` | 控制图片的变换矩阵（缩放/旋转/平移） |
| `_animController` | `AnimationController` | 双击归位动画控制器 |
| `_lastFocalPoint` | `Offset?` | 上一帧的手指中心点（差分算法） |
| `_lastScale` | `double` | 上一帧的缩放值（差分算法） |
| `_lastRotation` | `double` | 上一帧的旋转值（差分算法） |
| `_lastPointerCount` | `int` | 上一帧的手指数量（用于检测手指切换） |
| `_doubleTapDetails` | `TapDownDetails?` | 双击位置信息 |
| `_singleTapTimer` | `Timer?` | 单击防抖定时器 |

---

## 核心实现

### 1. 动态物理控制（第 92-97 行）

**核心逻辑**：根据变换状态动态切换 PageView 的物理特性

```dart
physics: _enablePageScroll
    ? const BouncingScrollPhysics()
    : const NeverScrollableScrollPhysics(),
```

- **未变换时** (`_enablePageScroll = true`)：使用 `BouncingScrollPhysics`，允许翻页
- **已变换时** (`_enablePageScroll = false`)：使用 `NeverScrollableScrollPhysics`，锁定翻页

### 2. 变换状态检测（第 240-247 行）

**三维检测**：同时检测缩放、旋转、平移状态

```dart
void _checkState() {
  final Matrix4 m = _transformController.value;
  final double scale = m.getMaxScaleOnAxis();
  final bool hasRotation = m.entry(0, 1).abs() > 0.01;
  final bool hasScale = scale < 0.99 || scale > 1.01;
  final bool isTransformed = hasRotation || hasScale;
  widget.onStateChanged(!isTransformed);
}
```

### 3. 差分/增量算法（第 249-291 行）

**防跳动核心**：使用帧间差值计算，解决手指数量切换时的图片瞬移问题

```dart
void _onScaleUpdate(ScaleUpdateDetails details) {
  // 1. 手指数量变化检测
  if (details.pointerCount != _lastPointerCount) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = details.scale;
    _lastRotation = details.rotation;
    _lastPointerCount = details.pointerCount;
    return;  // 跳过这一帧，防止跳动
  }

  // 2. 计算增量
  final double scaleDelta = details.scale / _lastScale;
  final double rotationDelta = details.rotation - _lastRotation;

  // 3. 构建增量矩阵
  final Matrix4 deltaMatrix = Matrix4.identity()
    ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
    ..rotateZ(rotationDelta)
    ..scale(scaleDelta)
    ..translate(-_lastFocalPoint!.dx, -_lastFocalPoint!.dy);

  // 4. 应用增量（左乘：基于屏幕坐标系）
  _transformController.value = deltaMatrix * _transformController.value;

  // 5. 更新状态
  _lastFocalPoint = details.localFocalPoint;
  _lastScale = details.scale;
  _lastRotation = details.rotation;
}
```

### 4. 自定义手势识别器（第 389-423 行）

**智能路由**：在 1.0x 状态下主动忽略单指移动事件，让 PageView 处理翻页

```dart
class _CheckScaleGestureRecognizer extends ScaleGestureRecognizer {
  final bool isPageScrollEnabled;
  int _pointerCount = 0;

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerCount--;
    }

    // 关键逻辑：1.0x + 单指 + 移动 → 忽略，让 PageView 翻页
    if (isPageScrollEnabled && _pointerCount < 2 && event is PointerMoveEvent) {
      return;
    }

    super.handleEvent(event);
  }
}
```

### 5. AnimatedBuilder 实时更新（第 363-380 行）

**响应式 UI**：监听矩阵变化并触发界面重绘

```dart
child: AnimatedBuilder(
  animation: _transformController,
  builder: (context, child) {
    return Transform(
      transform: _transformController.value,
      alignment: Alignment.topLeft,
      child: child,
    );
  },
  child: ExtendedImage.file(
    File(widget.imagePath),
    fit: BoxFit.contain,
    mode: ExtendedImageMode.none,
    enableLoadState: true,
  ),
)
```

### 6. 全状态双击归位（第 293-318 行）

**智能归位**：从任意变换状态（缩放/旋转）双击都能还原

```dart
void _handleDoubleTap() {
  final Matrix4 current = _transformController.value;
  final double scale = current.getMaxScaleOnAxis();
  final bool hasRotation = current.entry(0, 1).abs() > 0.01;

  Matrix4 target;
  if (scale < 0.99 || scale > 1.01 || hasRotation) {
    // 已变换：还原到单位矩阵
    target = Matrix4.identity();
  } else {
    // 未变换：放大到 2.5 倍
    final Offset tapPos = _doubleTapDetails?.localPosition ?? Offset.zero;
    final double s = 2.5;
    final double dx = tapPos.dx * (1 - s);
    final double dy = tapPos.dy * (1 - s);
    target = Matrix4.identity()..translate(dx, dy)..scale(s);
  }

  _animation = Matrix4Tween(begin: current, end: target).animate(
    CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuad),
  );
  _animation!.addListener(() {
    _transformController.value = _animation!.value;
  });
  _animController.forward(from: 0);
}
```

### 7. 空列表保护（建议在 build 方法开始添加）

```dart
if (widget.imagePaths.isEmpty) {
  return const Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Text(
        '暂无图片',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );
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
    │   └── _GestureImageItem (单个可变换图片)
    │       ├── RawGestureDetector (自定义手势识别器)
    │       │   ├── _CheckScaleGestureRecognizer (缩放/旋转/平移)
    │       │   ├── DoubleTapGestureRecognizer (双击)
    │       │   └── TapGestureRecognizer (单击)
    │       └── AnimatedBuilder (响应式更新)
    │           └── Transform (矩阵变换)
    │               └── ExtendedImage.file (图片加载)
    ├── _buildTopBar (顶部工具栏)
    └── _buildBottomIndicator (底部提示)
```

### 状态提升（State Lifting）

子组件 `_GestureImageItem` 通过回调通知父组件变换状态变化：

```dart
// 父组件定义回调
void _onStateChanged(bool isReset) {
  if (_enablePageScroll != isReset) {
    setState(() {
      _enablePageScroll = isReset;
    });
  }
}

// 子组件调用回调
widget.onStateChanged(!isTransformed);
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
        └── _GestureImageItem (每个图片)
            └── RawGestureDetector (手势处理)
                └── Transform (矩阵变换)
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

### 场景 3：双指旋转

```
1. 双指放在图片上
2. 旋转手势 → 图片跟随旋转
3. 松开手指 → 保持旋转角度
4. 再次双击 → 还原到 1.0x（包括旋转）
```

### 场景 4：双指缩放

```
1. 双指捏合 → 缩小到 0.5x
2. 继续捏合 → 缩小到 0.1x
3. 双指张开 → 放大到 5x
4. 继续张开 → 放大到 50x（无限放大）
```

### 场景 5：手势路由切换

```
1. 初始状态 (1.0x, 无旋转)
   - 左右滑动 → 翻页
   - 单指移动 → 被忽略，PageView 处理

2. 双击放大 (2.5x)
   - PageView 锁定 → 无法翻页
   - 拖动生效 → 自由移动图片
   - 滑到边缘 → 不会翻页

3. 双指旋转 45°
   - PageView 锁定 → 无法翻页
   - 旋转生效 → 图片保持旋转

4. 双击还原 (1.0x, 无旋转)
   - PageView 解锁 → 恢复翻页
   - 单指移动 → 被忽略，恢复翻页
```

### 场景 6：差分算法防跳动

```
1. 单指滑动 → 正常翻页
2. 第二根手指按下 → _CheckScaleGestureRecognizer 检测到手指数量变化
   → 重置锚点，跳过当前帧
   → 图片不会瞬移
3. 双指缩放/旋转 → 基于新锚点平滑变换
4. 松开一根手指 → 再次检测到手指数量变化
   → 重置锚点，跳过当前帧
   → 图片不会瞬移
5. 单指滑动 → 恢复翻页
```

---

## 技术亮点

### 1. 自定义手势系统

不使用 `InteractiveViewer`（不支持旋转），而是使用 `RawGestureDetector` + 自定义手势识别器，实现：
- 双指旋转（`rotateZ`）
- 双指缩放（`scale`）
- 双指平移（`translate`）
- 无限拖拽（无边界限制）

### 2. 差分/增量算法

解决传统绝对计算方法的问题：
- **问题**：从单指切换到双指时，`localFocalPoint` 会突变，导致图片瞬移
- **解决**：使用帧间差值计算，手指数量变化时重置锚点并跳过当前帧
- **效果**：平滑的手指切换体验，无跳动

### 3. 智能手势路由

通过自定义 `_CheckScaleGestureRecognizer` 实现：
- **1.0x + 单指**：主动忽略移动事件，让 PageView 的 HorizontalDragGestureRecognizer 赢得手势竞技场
- **已变换 + 双指**：正常处理缩放/旋转/平移，PageView 锁定

### 4. 响应式 UI 更新

使用 `AnimatedBuilder` 监听 `_transformController` 变化：
- 矩阵变化 → 触发动画监听器 → 重建 Transform → 实时更新 UI
- 解决了 `Transform` 静态不更新的问题

### 5. 矩阵变换原理

使用 `Matrix4` 进行 2D 变换：
- **平移**：`translate(dx, dy)`
- **旋转**：`rotateZ(angle)`（绕 Z 轴旋转）
- **缩放**：`scale(sx, sy)`
- **组合**：`deltaMatrix * currentMatrix`（左乘，基于屏幕坐标系）

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 组件代码（单文件） |
| `lib/comp_src/widgets/action_card.dart` | 使用此组件（主页面） |
| `lib/comp_src/pages/drawing_search_page.dart` | 使用此组件（搜索页面） |
| `pubspec.yaml` | extended_image 依赖配置 |
| `integration_test/image_preview_test.dart` | 集成测试（包含手势健壮性测试） |
