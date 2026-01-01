# SearchInputCard 组件文档

## 组件职责

搜索输入框卡片组件 - 包含搜索输入框和搜索按钮，用于用户输入搜索关键词并触发搜索操作。

## 代码位置

```
demo/lib/comp_src/widgets/search_input_card.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `controller` | `TextEditingController` | 是 | 搜索框文本控制器 |
| `hintText` | `String` | 是 | 输入框提示文字 |
| `onSearch` | `VoidCallback` | 是 | 搜索按钮点击回调 |
| `onSubmitted` | `ValueChanged<String>?` | 否 | 输入框提交回调（可选） |

### 输出

- 渲染一个固定高度的搜索输入框卡片
- 左侧为文本输入区域
- 右侧为圆形搜索按钮
- 支持提交时触发搜索（回车键）

## 依赖项

### 外部依赖
- `package:flutter/material.dart`

## 使用示例

### 示例 1：基础用法

```dart
final _searchController = TextEditingController();

SearchInputCard(
  controller: _searchController,
  hintText: '搜索图纸编号',
  onSearch: () {
    print('搜索: ${_searchController.text}');
  },
)
```

### 示例 2：带提交回调

```dart
SearchInputCard(
  controller: _searchController,
  hintText: '请输入关键词',
  onSearch: _performSearch,
  onSubmitted: (value) {
    // 用户按回车时触发
    _performSearch();
  },
)
```

### 示例 3：完整集成

```dart
class _MyPageState extends State<MyPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text;
    // 执行搜索逻辑
    print('搜索: $query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SearchInputCard(
          controller: _searchController,
          hintText: AppLocalizations.of(context)!.searchPlaceholder,
          onSearch: _performSearch,
          onSubmitted: (_) => _performSearch(),
        ),
      ),
    );
  }
}
```

## UI 特性

| 特性 | 说明 |
|------|------|
| 边框宽度 | 1.5 像素 |
| 深色模式边框色 | `#475569` |
| 浅色模式边框色 | `#CBD5E1` |
| 深色模式阴影 | elevation 2 |
| 浅色模式阴影 | elevation 4 |
| 圆角 | 16 像素 |
| 搜索按钮颜色 | 主题色 |
| 搜索按钮圆角 | 10 像素 |

## 修改注意事项

1. **控制器管理**：`controller` 需要在组件外部创建和销毁

2. **样式定制**：
   - 输入框无边框（`border: InputBorder.none`）
   - 提示文字颜色固定为 `#94A3B8`
   - 输入文字颜色固定为黑色，字重 500

3. **交互行为**：
   - 点击搜索按钮触发 `onSearch`
   - 输入框按回车触发 `onSubmitted`（如果提供）或 `onSearch`（默认）

4. **布局**：使用 Row 布局，输入框占据剩余空间，搜索按钮固定大小

## 相关文件

- ```
demo/lib/comp_src/widgets/search_input_card.dart
``` - 使用该组件的搜索页面
- ```
demo/lib/comp_src/widgets/search_input_card.dart
``` - 搜索结果列表组件文档
