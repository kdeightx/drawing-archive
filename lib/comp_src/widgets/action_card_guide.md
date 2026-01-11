# ActionCard 组件文档

## 组件职责

操作卡片组件 - 包含图片选择（相机/相册）、搜索已归档、编号输入、分页、上传识别、清空列表、保存等功能，支持多图片管理和批量操作。

## 代码位置

```
lib/comp_src/widgets/action_card.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `onCameraTap` | `VoidCallback` | 是 | - | 相机按钮回调 |
| `onGalleryTap` | `VoidCallback` | 是 | - | 相册按钮回调 |
| `onSearchTap` | `VoidCallback` | 是 | - | 搜索按钮回调 |
| `numberItems` | `List<NumberItem>` | 是 | - | 编号项列表 |
| `currentPage` | `int` | 是 | - | 当前页码 |
| `totalPages` | `int` | 是 | - | 总页数 |
| `itemsPerPage` | `int` | 否 | 5 | 每页显示数量 |
| `onNumberChange` | `ValueChanged<int>` | 是 | - | 编号变化回调（参数为项索引） |
| `onDeleteTap` | `ValueChanged<int>` | 是 | - | 删除图片回调（参数为项索引） |
| `onPreviousPage` | `VoidCallback?` | 否 | - | 上一页回调（null 则禁用） |
| `onNextPage` | `VoidCallback?` | 否 | - | 下一页回调（null 则禁用） |
| `onSave` | `VoidCallback` | 是 | - | 保存回调 |
| `onUpload` | `VoidCallback?` | 否 | - | 上传识别回调（null 则不显示按钮） |
| `onClearAll` | `VoidCallback?` | 否 | - | 清空列表回调（null 则不显示按钮） |
| `isSaving` | `bool` | 否 | false | 是否正在保存 |
| `isAnalyzing` | `bool` | 否 | false | 是否正在分析 |

### 输出

- 渲染一个包含以下内容的卡片：
  - 第一行：相机和相册按钮（并排）
  - 搜索按钮（渐变样式）
  - 编号区域（有图片时显示）：
    - 标题行（图标 + 文字 + 页码 + 数量）
    - 编号列表（图片缩略图 + 序号 + 输入框 + AI标识 + 删除按钮）
    - 分页按钮（超过5张时）
  - 操作按钮行（使用 ActionButtons 组件：清空 + 上传识别 + 保存）
- **点击缩略图**：打开 FullScreenImageViewer 全屏预览，支持手势缩放、旋转、滑动切换

## 依赖项

### 外部依赖
- `dart:io` - File 类型
- `package:flutter/material.dart`
- `package:provider/provider.dart` - 状态管理

### 内部依赖
- `../view_models/drawing_scanner_view_model.dart` - 图片数据和旋转状态管理
- `action_buttons.dart` - 操作按钮组件（清空、上传识别、保存）
- `full_screen_image_viewer.dart` - 全屏图片预览组件（点击缩略图时使用）

### 数据模型

#### NumberItem
```dart
class NumberItem {
  final String id;          // 唯一标识
  final File image;         // 图片文件
  final int index;          // 显示序号
  String number;            // 编号值（可变）
  bool hasAiNumber;         // 是否有AI识别的编号（可变）
  bool recognitionFailed;   // 是否识别失败
}
```

## 使用示例

### 示例 1：基础用法

```dart
ActionCard(
  onCameraTap: () => print('打开相机'),
  onGalleryTap: () => print('打开相册'),
  onSearchTap: () => print('搜索'),
  numberItems: [],
  currentPage: 0,
  totalPages: 1,
  onNumberChange: (index) => print('编号变化: $index'),
  onDeleteTap: (index) => print('删除: $index'),
  onSave: () => print('保存'),
)
```

### 示例 2：带编号项的完整用法

```dart
class _MyPageState extends State<MyPage> {
  List<NumberItem> _numberItems = [];
  int _currentPage = 0;
  bool _isSaving = false;

  // 创建编号项列表
  List<NumberItem> createNumberItems(List<File> images) {
    return List.generate(images.length, (index) {
      return NumberItem(
        id: 'item_$index',
        image: images[index],
        index: index,
        number: '',
        hasAiNumber: false,
        recognitionFailed: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      onCameraTap: _handleCamera,
      onGalleryTap: _handleGallery,
      onSearchTap: _handleSearch,
      numberItems: _numberItems,
      currentPage: _currentPage,
      totalPages: (_numberItems.length / 5).ceil(),
      onNumberChange: (index) {
        setState(() {
          // 处理编号变化
        });
      },
      onDeleteTap: (index) {
        setState(() {
          // 处理删除图片
        });
      },
      onPreviousPage: _currentPage > 0 ? () {
        setState(() {
          _currentPage--;
        });
      } : null,
      onNextPage: _currentPage < totalPages - 1 ? () {
        setState(() {
          _currentPage++;
        });
      } : null,
      onSave: _handleSave,
      onUpload: _handleUpload,
      onClearAll: _handleClearAll,
      isSaving: _isSaving,
      isAnalyzing: false,
    );
  }
}
```

### 示例 3：在全屏预览中查看图片

```dart
// ActionCard 内置了全屏预览功能
// 点击缩略图 → 打开 FullScreenImageViewer

// 全屏预览功能：
// - 支持多图滑动切换
// - 支持双击缩放（以点击位置为中心放大到 2.5x 或还原）
// - 支持双指缩放（从 0.01x 到无限大）
// - 支持手势拖动（缩放后无边界自由拖动）
// - 沉浸式交互（单击隐藏/显示 UI）
// - 智能手势路由（缩放前滑动翻页，缩放后锁定翻页）

// 预览数据来源：
// - imagePaths: 从 ViewModel 的 selectedImages 获取
// - initialIndex: 点击的缩略图索引
```

### 示例 4：点击缩略图打开全屏预览

```dart
// ActionCard 内置了全屏预览功能
// 点击缩略图 → 打开 FullScreenImageViewer 全屏预览

/// 显示全屏预览
void _showFullScreenPreview(BuildContext context, int index) {
  final viewModel = context.read<DrawingScannerViewModel>();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => FullScreenImageViewer(
        imagePaths: viewModel.selectedImages.map((file) => file.path).toList(),
        initialIndex: index,
      ),
    ),
  );
}
```

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| `_buildActionButton` | 142-195 | 操作按钮（相机/相册） |
| `_buildSearchButton` | 198-230 | 搜索按钮（渐变样式） |
| `_buildNumberSection` | 233-288 | 编号区域容器 |
| `_buildNumberHeader` | 291-336 | 编号标题行 |
| `_buildNumberItem` | 339-496 | 单个编号输入项 |
| `_buildPaginationButtons` | 499-561 | 分页按钮 |
| `_showFullScreenPreview` | 564-577 | 显示全屏预览（导航到 FullScreenImageViewer） |

## 架构说明

### 依赖关系

```
DrawingScannerPage (页面)
    └── Provider<DrawingScannerViewModel>
            └── ActionCard (组件)
                    ├── context.read<DrawingScannerViewModel>() ← 隐式依赖
                    └── FullScreenImageViewer (组件) ← 显式依赖
```

**注意**：ActionCard 通过 `context.read<DrawingScannerViewModel>()` 访问 ViewModel，这是一种隐式依赖。

### 组件独立性

- **ActionCard**: 依赖于 DrawingScannerViewModel（通过 Provider）
- **FullScreenImageViewer**: 完全独立，通过构造函数参数传递数据

### 高内聚低耦合

1. **高内聚**：ActionCard 负责图纸编号输入的整个流程
2. **低耦合**：
   - ActionCard 与 FullScreenImageViewer 之间通过构造函数参数传递数据
   - FullScreenImageViewer 不依赖 ViewModel
   - ActionCard 可以在其他场景中复用

## 功能说明

### 1. 图片选择功能（第 104-127 行）

- **相机按钮**：调用 `onCameraTap` 回调
- **相册按钮**：调用 `onGalleryTap` 回调
- **状态**：分析中时禁用（`isEnabled: !isAnalyzing`）

### 2. 搜索按钮（第 198-230 行）

- 渐变样式（主题色渐变）
- 始终可点击（不受 `isAnalyzing` 影响）
- 点击触发 `onSearchTap` 回调

### 3. 编号输入功能（第 339-496 行）

**单个编号项包含**：
- 删除按钮（分析中时禁用）
- 图片缩略图（48x48，可点击打开全屏预览）
- 序号标签（例如 #1, #2）
- 编号输入框（支持手动输入和 AI 识别）
- AI 标识（识别成功时显示）

**输入框状态**：
- **启用**：可以手动输入编号
- **禁用**：上传识别流程中禁用（`isEnabled: !viewModel.isAnalyzing`）

**键盘避让**（第 478-484 行）：
```dart
onTap: () {
  // 输入框获得焦点时，确保在可见区域
  Scrollable.ensureVisible(
    context,
    alignment: 0.5, // 滚动到输入框居中位置
  );
}
```
- 用户点击输入框时，自动滚动使输入框居中显示
- `alignment: 0.5` 将输入框滚动到可视区域中心
- 与页面的动态 padding 配合，确保输入框始终在键盘上方可见

**删除按钮状态**：
- **启用**：可以删除图片
- **禁用**：上传识别流程中禁用（`canDelete: !viewModel.isAnalyzing`）

### 4. 分页功能（第 499-561 行）

- **显示条件**：`numberItems.length > itemsPerPage`（默认超过 5 张）
- **上一页**：`onPreviousPage` 为 null 时禁用
- **下一页**：`onNextPage` 为 null 时禁用

### 5. 操作按钮（第 278-285 行）

使用独立的 `ActionButtons` 组件：
- **清空**：调用 `onClearAll` 回调
- **上传识别**：调用 `onUpload` 回调
- **保存**：调用 `onSave` 回调

### 6. 全屏预览功能（第 564-577 行）

点击缩略图打开全屏图片查看器：
- 从 ViewModel 获取图片路径和标题
- 支持多图滑动切换
- 启用旋转功能（`enableRotation: true`）
- 支持手势缩放、旋转、拖动

## 修改注意事项

### 上传识别流程中的状态控制

在上传识别流程中（从 `isAnalyzing` 开始到识别完成）：
- ❌ 相机/相册按钮：禁用
- ✅ 搜索按钮：启用
- ❌ 编号输入框：禁用
- ❌ 删除按钮：禁用
- ✅ 分页按钮：启用（不依赖 `isAnalyzing`）
- ❌ 操作按钮：禁用（上传识别按钮禁用，清空/保存按钮启用但列表为空时清空禁用）

### ViewModel 依赖

ActionCard 通过 `context.read<DrawingScannerViewModel>()` 访问 ViewModel：
- 获取 `selectedImages` 和 `recognizedNumbers` 用于全屏预览
- 获取 `isAnalyzing` 状态控制 UI 禁用

这种设计是**高耦合**的，如果要让 ActionCard 完全独立，应该通过构造函数参数传递这些状态。

### 组件引用组件

ActionCard 引用 FullScreenImageViewer 是**合理的设计**：
- ✅ 职责分离清晰（ActionCard 负责业务，FullScreenImageViewer 负责 UI）
- ✅ 高内聚（点击缩略图查看全屏是 ActionCard 的内部功能）
- ✅ 低耦合（通过构造函数参数传递数据，不共享状态）
- ✅ 可复用（FullScreenImageViewer 可以在任何地方使用）

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/widgets/action_card.dart` | 组件代码 |
| `lib/comp_src/widgets/action_buttons.dart` | 操作按钮组件 |
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 全屏图片预览组件 |
| `lib/comp_src/view_models/drawing_scanner_view_model.dart` | 图片数据和旋转状态管理 |
