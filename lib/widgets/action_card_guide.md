# ActionCard 组件文档

## 组件职责

操作卡片组件 - 包含图片选择（相机/相册）、搜索已归档、编号输入、分页、保存等功能，支持多图片管理和批量操作。

## 代码位置

`lib/widgets/action_card.dart`

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
    - 保存按钮

## 依赖项

### 外部依赖
- `dart:io` - File 类型
- `package:flutter/material.dart`

### 数据模型

#### NumberItem
```dart
class NumberItem {
  final String id;          // 唯一标识
  final File image;         // 图片文件
  final int index;          // 显示序号
  String number;            // 编号值（可变）
  bool hasAiNumber;         // 是否有AI识别的编号（可变）
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
  List<NumberItem> _buildNumberItems() {
    return List.generate(_images.length, (index) {
      return NumberItem(
        id: 'img_$index',
        image: _images[index],
        index: index,
        number: _controllers[index].text,
        hasAiNumber: _recognizedNumbers[index].isNotEmpty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNumberItems();
    final totalPages = (items.length / 5).ceil();

    return ActionCard(
      onCameraTap: _handleCamera,
      onGalleryTap: _handleGallery,
      onSearchTap: () => Navigator.push(...),
      numberItems: items,
      currentPage: _currentPage,
      totalPages: totalPages,
      onNumberChange: (index) {
        // 更新编号
        _controllers[index].text = items[index].number;
      },
      onDeleteTap: (index) {
        setState(() {
          _images.removeAt(index);
          // 更新页码等
        });
      },
      onPreviousPage: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
      onNextPage: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
      onSave: _handleSave,
      isSaving: _isSaving,
      isAnalyzing: _isAnalyzing,
    );
  }
}
```

### 示例 3：自定义每页显示数量

```dart
ActionCard(
  onCameraTap: () {},
  onGalleryTap: () {},
  onSearchTap: () {},
  numberItems: items,
  currentPage: 0,
  totalPages: (items.length / 10).ceil(),
  itemsPerPage: 10,  // 自定义每页显示10项
  onNumberChange: (index) {},
  onDeleteTap: (index) {},
  onSave: () {},
)
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildActionButton` | 127-162 | 操作按钮（相机/相册） |
| `_buildSearchButton` | 165-197 | 搜索按钮（渐变样式） |
| `_buildNumberSection` | 200-274 | 编号区域容器 |
| `_buildNumberHeader` | 277-322 | 编号区域标题行 |
| `_buildNumberItem` | 325-449 | 单个编号输入项 |
| `_buildPaginationButtons` | 452-514 | 分页按钮（带禁用状态样式） |

## 修改注意事项

1. **NumberItem 数据同步**：`number` 和 `hasAiNumber` 是可变字段，需要在外部维护同步

2. **编号输入处理**：`onNumberChange` 回调参数是项的索引（不是数组索引），需要通过 `item.index` 获取实际索引

3. **分页计算**：`totalPages` 需要在外部计算，公式为 `(items.length / itemsPerPage).ceil()`

4. **分页按钮状态**：`onPreviousPage` 和 `onNextPage` 为 `null` 时按钮自动禁用

5. **保存按钮状态**：当 `isAnalyzing` 或 `isSaving` 为 `true` 时保存按钮禁用

6. **图片缩略图**：使用 48x48 固定尺寸，`BoxFit.cover` 裁剪

7. **AI 识别标识**：仅当 `NumberItem.hasAiNumber` 为 `true` 时显示星星图标

8. **边框增强样式**（第78-84行）：
   - Card 组件增加了 `side` 边框属性
   - 深色模式：边框颜色 `#475569`，宽度 1.5
   - 浅色模式：边框颜色 `#CBD5E1`，宽度 1.5

9. **分页按钮禁用样式**（第452-514行）：
   - 禁用状态边框颜色：深色 `#334155`，浅色 `#E2E8F0`
   - 禁用状态文字颜色：深色 `#475569`，浅色 `#94A3B8`
   - 启用状态边框颜色：主题色带 30% 透明度
   - 启用状态文字颜色：主题色

10. **保存按钮禁用样式**（第252行）：
    - 禁用背景颜色：深色 `#475569`，浅色 `#E2E8F0`

## 相关文件

- `lib/pages/drawing_scanner_page.dart` - 使用该组件的主页面
- `lib/widgets/smart_process_stepper_guide.md` - 进度指示器组件文档
- `lib/widgets/image_display_card_guide.md` - 图片显示卡片组件文档
