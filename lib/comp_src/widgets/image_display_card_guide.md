# ImageDisplayCard 组件文档

## 组件职责

图片显示卡片组件 - 支持多图片查看、缩放、滑动切换、全屏预览，包含空状态占位符和页码指示器。

**核心功能**：
- **图片展示**：弹性高度，自动填充父组件的 Expanded 空间
- **滑动切换**：PageView 支持左右滑动切换图片
- **缩放操作**：InteractiveViewer 支持双指缩放（0.5x - 4.0x）
- **点击预览**：支持点击图片打开全屏预览（通过回调）
- **页码指示器**：底部显示当前页码指示点
- **空状态**：未选择图片时显示占位符（图标 + 提示文字）
- **自适应布局**：根据屏幕大小自动调整显示区域

**组件类型**：StatefulWidget（自管理控制器）

**架构设计**：
- **组件自治**：内部管理 PageController 和 TransformationController
- **回调驱动**：通过回调通知父组件状态变化和用户交互
- **向后兼容**：onImageTap 可选，未提供时使用默认导航行为

## 代码位置

```
lib/comp_src/widgets/image_display_card.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `images` | `List<File>` | 是 | 图片文件列表 |
| `currentIndex` | `int` | 是 | 当前查看的图片索引 |
| `onIndexChange` | `ValueChanged<int>` | 是 | 索引变化回调函数 |
| `onImageTap` | `ValueChanged<int>?` | 否 | 图片点击回调（可选，用于导航到全屏预览）|

### 输出

- 渲染弹性高度的卡片，填充父组件的 Expanded 空间
- 空状态时显示占位符（扫描图标 + 提示文字）
- 有图片时显示可滑动、可缩放的图片查看器
- 多张图片时显示底部页码指示器
- 自适应不同屏幕尺寸（小屏自动缩小，大屏自动放大）
- 点击图片时触发回调（如果提供了 `onImageTap`）

## 依赖项

### 外部依赖
- `dart:io` - File 类型
- `package:flutter/material.dart`

### 内部依赖
```
full_screen_image_viewer.dart  # 全屏预览组件（默认导航行为使用）
```

## 状态管理

### 控制器

| 控制器 | 类型 | 生命周期 | 说明 |
|--------|------|----------|------|
| `_pageController` | `PageController` | 组件内创建 | 图片滑动切换控制，初始页为 currentIndex |
| `_transformationController` | `TransformationController` | 组件内创建 | 图片缩放平移控制，初始为单位矩阵 |

### 生命周期方法

#### initState()
```dart
@override
void initState() {
  super.initState();
  _pageController = PageController(initialPage: widget.currentIndex);
  _transformationController = TransformationController();
}
```

#### didUpdateWidget()
```dart
@override
void didUpdateWidget(ImageDisplayCard oldWidget) {
  super.didUpdateWidget(oldWidget);
  // 当 currentIndex 变化时，使用 addPostFrameCallback 延迟跳转
  // 避免在 build 期间触发 notifyListeners 导致错误
  if (widget.currentIndex != oldWidget.currentIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(widget.currentIndex);
      }
    });
  }
}
```

**关键设计**：使用 `addPostFrameCallback` 避免在 build 阶段调用 `jumpToPage()` → 触发 `onPageChanged` → 调用 `notifyListeners()`，导致 "setState() called during build" 错误。

#### dispose()
```dart
@override
void dispose() {
  _pageController.dispose();
  _transformationController.dispose();
  super.dispose();
}
```

## 使用示例

### 示例 1：基础用法

```dart
class _MyPageState extends State<MyPage> {
  int _currentIndex = 0;
  List<File> _images = [];

  @override
  Widget build(BuildContext context) {
    return ImageDisplayCard(
      images: _images,
      currentIndex: _currentIndex,
      onIndexChange: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
```

### 示例 2：结合图片选择

```dart
class _MyPageState extends State<MyPage> {
  List<File> _selectedImages = [];
  int _currentImageIndex = 0;

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    setState(() {
      _selectedImages = images.map((xfile) => File(xfile.path)).toList();
      _currentImageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickImages,
          child: Text('选择图片'),
        ),
        ImageDisplayCard(
          images: _selectedImages,
          currentIndex: _currentImageIndex,
          onIndexChange: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
        ),
      ],
    );
  }
}
```

### 示例 3：结合 ViewModel 状态管理

```dart
class _MyPageState extends State<MyPage> {
  final MyViewModel _viewModel = MyViewModel();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<MyViewModel>(
        builder: (context, viewModel, child) {
          return ImageDisplayCard(
            images: viewModel.selectedImages,
            currentIndex: viewModel.currentImageIndex,
            onIndexChange: (index) {
              viewModel.setCurrentImageIndex(index);
            },
          );
        },
      ),
    );
  }
}
```

### 示例 4：带全屏预览（MVVM 架构）

```dart
// ViewModel 中定义导航方法
class MyViewModel extends ChangeNotifier {
  void onImageTapped(int index) {
    debugPrint('用户点击了图片 $index');
    // 设置导航状态，通知 View 执行导航
    _shouldOpenPreview = true;
    _previewIndex = index;
    notifyListeners();
  }

  void clearPreviewState() {
    _shouldOpenPreview = false;
    notifyListeners();
  }
}

// View 中监听导航状态并执行导航
Consumer<MyViewModel>(
  builder: (context, viewModel, child) {
    // 监听导航状态
    if (viewModel.shouldOpenPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final imagePaths = viewModel.selectedImages
            .map((f) => f.path)
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              imagePaths: imagePaths,
              initialIndex: viewModel.previewIndex,
            ),
          ),
        ).then((_) {
          viewModel.clearPreviewState();
        });
      });
    }

    return ImageDisplayCard(
      images: viewModel.selectedImages,
      currentIndex: viewModel.currentImageIndex,
      onIndexChange: (index) => viewModel.setCurrentImageIndex(index),
      onImageTap: (index) => viewModel.onImageTapped(index),  // 回调方式
    );
  },
)
```

### 示例 5：使用默认导航行为

```dart
// 不提供 onImageTap 回调，使用组件内置的默认导航
ImageDisplayCard(
  images: _images,
  currentIndex: _currentIndex,
  onIndexChange: (index) => setState(() => _currentIndex = index),
  // onImageTap 未提供，点击图片时使用默认的 _openFullScreenViewer()
)
```

## UI 结构

```
ImageDisplayCard (Card)
└── SizedBox (动态高度，屏幕可用高度的 45%)
    └── Container
        └── ClipRRect
            ├── if images.isEmpty
            │   └── _buildPlaceholder
            │       └── Center
            │           ├── Container (圆形图标背景)
            │           │   └── Icon(Icons.document_scanner_outlined)
            │           ├── Text('点击上传图片')
            │           └── Text('支持多选图片')
            └── if images.isNotEmpty
                └── _buildImageViewer (Stack)
                    ├── PageView.builder
                    │   └── GestureDetector (onImageTap)
                    │       └── InteractiveViewer
                    │           └── Image.file
                    └── if images.length > 1
                        └── _buildPageIndicator
                        └── Row
                            └── List.generate (AnimatedContainer * n)
```

## 修改注意事项

### 组件自治原则
- **控制器自管理**：组件内部创建和管理自己的 PageController 和 TransformationController
- **不依赖外部传入控制器**：避免 ViewModel 管理 UI 控制器，保持 MVVM 分离

### 回调设计模式
- **onImageTap 可选**：未提供时使用默认导航行为（向后兼容）
- **优先使用回调**：提供回调时优先调用回调，让父组件控制导航
- **MVVM 友好**：回调方式让 ViewModel 决策导航，View 执行导航

### 生命周期陷阱
- **didUpdateWidget 中的更新**：必须使用 `addPostFrameCallback` 延迟执行
- **原因**：直接调用 `_pageController.jumpToPage()` 会触发 `onPageChanged` 回调，如果在 build 期间调用 `notifyListeners()` 会导致错误
- **解决方案**：在下一帧之前执行跳转操作

### 缩放重置
- 切换图片时自动重置缩放比例（每个图片独立的 TransformationController）
- 如需跨图片保持缩放状态，需要调整实现

### 边界情况
- `images.isEmpty`：显示占位符
- `images.length == 1`：不显示页码指示器
- `currentIndex` 超出范围：由调用方保证有效性
- 快速连续点击：可能触发多次导航，由调用方处理防抖

### 导航状态管理

**使用回调的优势**：
1. **解耦**：组件不直接依赖 FullScreenImageViewer
2. **灵活**：父组件可自定义导航行为（添加转场动画、传递参数等）
3. **可测试**：可独立测试回调是否被触发
4. **MVVM 符合**：导航决策在 ViewModel，执行在 View

**默认行为（向后兼容）**：
- 未提供 `onImageTap` 时，组件内置 `_openFullScreenViewer()` 方法
- 直接创建 FullScreenImageViewer 并导航
- 适用于简单场景

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/pages/drawing_scanner_page.dart` | 使用此组件的主页面 |
| `lib/comp_src/view_models/drawing_scanner_view_model.dart` | 管理图片列表和索引的 ViewModel |
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 全屏预览组件（默认导航行为使用）|
