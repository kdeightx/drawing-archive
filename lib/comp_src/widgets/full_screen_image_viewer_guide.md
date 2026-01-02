# FullScreenImageViewer 组件指南

## 组件职责

`FullScreenImageViewer` 是全屏图片预览组件，提供专业级的图片查看体验：

- **全屏预览**：黑色背景的全屏图片查看器
- **多图浏览**：支持左右滑动切换图片
- **手势缩放**：双指缩放，以手指位置为中心
- **手势旋转**：双指自由旋转图片
- **手势拖动**：双指拖动查看图片不同区域
- **双击放大**：双击以点击位置为中心放大到 2 倍，再次双击恢复
- **按钮旋转**：顶部操作栏支持 90 度增量旋转
- **沉浸式交互**：单击屏幕隐藏/显示 UI 和状态栏
- **智能切换**：缩放时自动禁用滑动切换，防止误操作
- **完全独立**：不依赖 ViewModel，通过构造函数参数传递数据

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
| `imageTitles` | `List<String>?` | 否 | null | 图片标题列表（可选，用于显示在顶部） |
| `initialIndex` | `int` | 否 | 0 | 初始显示的图片索引 |
| `enableRotation` | `bool` | 否 | true | 是否启用旋转功能 |

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 显示全屏预览 | 打开全屏黑色背景的图片查看器 |
| 单击切换 UI | 单击屏幕隐藏/显示顶部和底部操作栏 |
| 返回上一页 | 点击左上角返回按钮关闭预览 |
| 旋转图片 | 点击旋转按钮或使用双指旋转手势（如果启用） |
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
```

### 内部依赖

无（完全独立组件）

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
| `_currentRotation` | `int` | 当前旋转角度（0, 90, 180, 270） |
| `_currentIndex` | `int` | 当前页面索引（本地状态） |
| `_initialFocalPoint` | `Offset?` | 手势开始时的焦点位置 |
| `_initialMatrix` | `Matrix4?` | 手势开始时的变换矩阵 |
| `_showControls` | `bool` | 控制 UI 是否显示（沉浸式交互） |

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
        imagePaths: viewModel.selectedImages.map((file) => file.path).toList(),
        imageTitles: viewModel.recognizedNumbers,
        initialIndex: index,
        enableRotation: true,  // 主页面启用旋转
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
        imageTitles: _results.map((e) => e.number).toList(),
        initialIndex: index,
        enableRotation: false,  // 搜索结果禁用旋转
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
      enableRotation: true,
    ),
  ),
);
```

### 示例 4：不显示标题

```dart
// 打开图片预览但不显示标题
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FullScreenImageViewer(
      imagePaths: imagePaths,
      initialIndex: 0,
      enableRotation: true,
      // 不传递 imageTitles 参数，则不显示标题
    ),
  ),
);
```

---

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| `_buildImageContent` | 111-149 | PageView 图片内容区域 |
| `_buildRotatedImage` | 232-246 | 可旋转的图片容器 |
| `_buildGestureImage` | 254-334 | 带手势的图片（双指缩放+旋转+移动） |
| `_buildTopAppBar` | 342-421 | 顶部操作栏（返回+旋转+页码） |
| `_buildBottomIndicator` | 428-476 | 底部指示器（当前页指示器） |

---

## 功能说明

### 1. 双击缩放功能（第 152-170 行）

双击图片时：
- 当前缩放比例 ≤ 1.0：放大到 2 倍（以点击位置为中心）
- 当前缩放比例 > 1.0：恢复到 1 倍

**实现细节**：
- 使用 `_transformKey` 和 `RenderBox` 进行坐标转换
- `globalToLocal()` 将屏幕坐标转换为组件局部坐标
- `_animateToScaleAtPoint()` 实现以点击位置为中心的缩放

### 2. 手势缩放和旋转（第 261-315 行）

**支持的手势**：
- 双指缩放：`details.scale`
- 双指旋转：`details.rotation`
- 双指拖动：`details.localFocalPoint - _initialFocalPoint`

**实现细节**：
- 定点缩放与旋转（Focal Zoom & Rotate）
- 逻辑三明治：移到锚点 → 变换 → 移回锚点
- 手势结束时自动回弹到 1.0 倍（如果缩放过小）

### 3. 页面切换控制（第 62-65 行）

**智能切换逻辑**：
```dart
bool get _allowPageScroll {
  final scale = _transformationController.value.getMaxScaleOnAxis();
  return scale <= 1.01; // 缩放 > 1.01 时禁止滑动
}
```

- 缩放比例 ≤ 1.01：可以左右滑动切换图片
- 缩放比例 > 1.01：禁止滑动，防止误操作

### 4. 沉浸式交互（第 126-136 行）

单击屏幕时：
- 隐藏 UI：`SystemUiMode.immersive`（隐藏状态栏）
- 显示 UI：`SystemUiMode.edgeToEdge`（显示状态栏）
- `_showControls` 控制顶部和底部操作栏的显示/隐藏

### 5. 旋转功能（第 341-421 行）

**按钮旋转**（如果 `enableRotation: true`）：
- 逆时针旋转：每次 -90 度
- 顺时针旋转：每次 +90 度
- 页面切换时重置旋转角度

**旋转角度范围**：0°, 90°, 180°, 270°

### 6. 页面索引跟踪（第 61-62, 78, 124 行）

**本地状态管理**：
```dart
int _currentIndex = 0;  // 本地状态，避免在 PageView 构建前访问 PageController.page

@override
void initState() {
  super.initState();
  _currentIndex = widget.initialIndex;  // 初始化为初始索引
  // ...
}

onPageChanged: (index) {
  setState(() {
    _currentIndex = index;  // 更新当前索引
    _currentRotation = 0;   // 页面切换时重置旋转
  });
},
```

**原因**：避免在 PageView 构建前访问 `PageController.page` 导致错误。

---

## 架构说明

### 组件独立性

```
FullScreenImageViewer (完全独立)
    ├── 通过构造函数参数接收数据
    ├── 不依赖 ViewModel
    ├── 不依赖 Provider
    └── 可在任何地方使用
```

**优点**：
- ✅ 完全独立，可在任何页面或组件中使用
- ✅ 通过构造函数参数传递数据，清晰明确
- ✅ 本地状态管理，不依赖外部状态
- ✅ 可独立测试
- ✅ 可复用性强

### 数据流向

```
调用者（ActionCard / DrawingSearchPage）
    ↓ 提供数据
Navigator.push(context, MaterialPageRoute(...))
    ↓ 传递参数
FullScreenImageViewer
    ├── imagePaths: List<String>
    ├── imageTitles: List<String>?
    ├── initialIndex: int
    └── enableRotation: bool
```

### 与旧版本对比

| 特性 | 旧版本 | 当前版本 |
|------|--------|----------|
| ViewModel 依赖 | ✅ 依赖 Provider | ❌ 完全独立 |
| 数据获取 | `context.read<ViewModel>()` | 构造函数参数 |
| 状态管理 | ViewModel 状态 + 本地状态 | 仅本地状态 |
| 可复用性 | 仅在特定 Provider 作用域内 | 任何地方 |
| 测试难度 | 需要 Provider 环境 | 独立测试 |

---

## 修改注意事项

### 关键设计决策

#### 1. 使用本地状态跟踪页面索引

**问题**：在 `build()` 方法中访问 `PageController.page` 会在 PageView 构建前导致错误。

**解决方案**：使用本地状态 `_currentIndex` 跟踪当前页面索引。

```dart
// ❌ 错误做法
Widget _buildTopAppBar() {
  final currentIndex = _pageController.page?.round() ?? 0;  // 会报错！
  // ...
}

// ✅ 正确做法
int _currentIndex = 0;  // 本地状态

@override
void initState() {
  super.initState();
  _currentIndex = widget.initialIndex;  // 初始化
}

onPageChanged: (index) {
  setState(() {
    _currentIndex = index;  // 更新
  });
},
```

#### 2. 为每个页面创建独立的 TransformationController

**问题**：如果所有页面共享同一个 `TransformationController`，缩放状态会混乱。

**解决方案**：每个 `_ImageViewerPage` 有自己的 `TransformationController`。

#### 3. 坐标转换的精确性

双击缩放需要精确的坐标转换：
```dart
// 将屏幕绝对坐标转换为组件局部坐标
final Offset localFocalPoint = renderBox.globalToLocal(globalFocalPoint);
```

#### 4. 旋转功能的控制

通过 `enableRotation` 参数控制是否启用旋转：
- 主页面（扫描时）：`enableRotation: true`（可能需要旋转图片）
- 搜索页面：`enableRotation: false`（只查看已归档的图纸）

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 组件代码 |
| `lib/comp_src/widgets/action_card.dart` | 使用此组件（主页面） |
| `lib/comp_src/pages/drawing_search_page.dart` | 使用此组件（搜索页面） |
