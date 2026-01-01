# ImageDisplayCard 组件文档

## 组件职责

图片显示卡片组件 - 支持多图片查看、缩放、滑动切换，包含空状态占位符和页码指示器。

## 代码位置

```
demo/lib/comp_src/widgets/image_display_card.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `images` | `List<File>` | 是 | 图片文件列表 |
| `currentIndex` | `int` | 是 | 当前查看的图片索引 |
| `pageController` | `PageController` | 是 | PageController 用于滑动切换 |
| `transformationController` | `TransformationController` | 是 | TransformationController 用于缩放平移 |
| `onIndexChange` | `ValueChanged<int>` | 是 | 索引变化回调 |

### 输出

- 渲染一个固定高度（400px）的卡片
- 空状态时显示占位符（扫描图标 + 提示文字）
- 有图片时显示可滑动、可缩放的图片查看器
- 多张图片时显示底部页码指示器

## 依赖项

### 外部依赖
- `dart:io` - File 类型
- `package:flutter/material.dart`

## 使用示例

### 示例 1：基础用法

```dart
// 在 StatefulWidget 中创建控制器
class _MyPageState extends State<MyPage> {
  final PageController _pageController = PageController();
  final TransformationController _transformationController = TransformationController();
  int _currentIndex = 0;
  List<File> _images = [];

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImageDisplayCard(
      images: _images,
      currentIndex: _currentIndex,
      pageController: _pageController,
      transformationController: _transformationController,
      onIndexChange: (index) {
        setState(() {
          _currentIndex = index;
          _transformationController.value = Matrix4.identity();
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
  final PageController _pageController = PageController();
  final TransformationController _transformationController = TransformationController();

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages = images.map((e) => File(e.path)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _pickImages, child: Text('选择图片')),
        ImageDisplayCard(
          images: _selectedImages,
          currentIndex: _currentImageIndex,
          pageController: _pageController,
          transformationController: _transformationController,
          onIndexChange: (index) {
            setState(() {
              _currentImageIndex = index;
              _transformationController.value = Matrix4.identity();
            });
          },
        ),
      ],
    );
  }
}
```

### 示例 3：在 Card 中使用

```dart
Card(
  margin: EdgeInsets.zero,
  child: ImageDisplayCard(
    images: _images,
    currentIndex: _currentIndex,
    pageController: _pageController,
    transformationController: _transformationController,
    onIndexChange: (index) {
      setState(() => _currentIndex = index);
    },
  ),
)
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildPlaceholder` | 55-94 | 空状态占位符（扫描图标 + 提示文字） |
| `_buildImageViewer` | 97-136 | 图片查看器（PageView + InteractiveViewer） |
| `_buildPageIndicator` | 139-163 | 页码指示器（底部圆点） |

## 修改注意事项

1. **控制器生命周期**：`pageController` 和 `transformationController` 需要在组件外部创建和销毁

2. **缩放范围**：InteractiveViewer 的缩放范围为 0.5x - 4.0x

3. **固定高度**：组件高度固定为 400px，不可调整

4. **页码指示器**：仅在图片数量 > 1 时显示

5. **索引变化处理**：切换图片时建议重置 `transformationController`（`Matrix4.identity()`）

6. **图片加载失败**：使用 `errorBuilder` 显示错误图标和文字

7. **边框样式**（第 30-39 行）：
   - elevation: 深色模式 2，浅色模式 4
   - 边框宽度：1.5 像素
   - 边框颜色：深色模式 `#475569`，浅色模式 `#CBD5E1`
   - 圆角：16 像素

## 相关文件

- ```
demo/lib/comp_src/widgets/image_display_card.dart
``` - 使用该组件的主页面
- ```
demo/lib/comp_src/widgets/image_display_card.dart
``` - 进度指示器组件文档
- ```
demo/lib/comp_src/widgets/image_display_card.dart
``` - 操作卡片组件文档
