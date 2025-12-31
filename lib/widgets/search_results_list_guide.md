# SearchResultsList 组件文档

## 组件职责

搜索结果列表组件 - 显示搜索到的图纸列表，支持加载状态、空状态和结果列表展示。

## 代码位置

`lib/widgets/search_results_list.dart`

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `results` | `List<DrawingEntry>` | 是 | 搜索结果列表 |
| `isLoading` | `bool` | 是 | 是否正在加载 |
| `onResultTap` | `VoidCallback?` | 否 | 结果项点击回调（可选） |

### 输出

- 加载中：显示 `CircularProgressIndicator`
- 空结果：显示"未找到相关图纸"提示
- 有结果：显示可滚动的图纸列表

## 依赖项

### 外部依赖
- `package:flutter/material.dart`

### 内部依赖
- `lib/services/drawing_service.dart` - DrawingEntry 数据模型

## 使用示例

### 示例 1：基础用法

```dart
SearchResultsList(
  results: _searchResults,
  isLoading: _isLoading,
)
```

### 示例 2：带点击回调

```dart
SearchResultsList(
  results: _results,
  isLoading: _isLoading,
  onResultTap: () {
    print('点击了搜索结果');
  },
)
```

### 示例 3：完整集成

```dart
class _MyPageState extends State<MyPage> {
  List<DrawingEntry> _results = [];
  bool _isLoading = false;

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    // 模拟搜索
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _results = [/* 搜索结果 */];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SearchResultsList(
        results: _results,
        isLoading: _isLoading,
        onResultTap: () {
          // 处理结果点击
        },
      ),
    );
  }
}
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_formatDate` | 19 | 格式化日期显示（内部方法） |
| `_ResultCard` | 56-201 | 单个搜索结果卡片组件 |

## 空状态设计

当搜索结果为空时显示：
- 搜索图标（`Icons.search_off_outlined`）
- 提示文字："未找到相关图纸"
- 图标颜色：主题色 50% 透明度
- 文字颜色：`#64748B`

## 结果卡片设计

每个搜索结果卡片包含：
1. **左侧图标区域**（72x72）
   - 主题色背景（10% 透明度）
   - 文档图标（`Icons.description_outlined`）
   - 边框：主题色（20% 透明度）

2. **中间信息区域**
   - 图纸编号
   - 日期（带日历图标）
   - 状态标签（绿色背景）

3. **右侧箭头**
   - 右箭头图标（`Icons.chevron_right_outlined`）

## 边框样式

| 特性 | 值 |
|------|------|
| 边框宽度 | 1.5 像素 |
| 深色模式边框色 | `#475569` |
| 浅色模式边框色 | `#CBD5E1` |
| 深色模式阴影 | elevation 2 |
| 浅色模式阴影 | elevation 4 |
| 圆角 | 16 像素 |
| 卡片间距 | 12 像素（底部） |
| 列表底部间距 | 16 像素 |

## 修改注意事项

1. **状态管理**：
   - `isLoading` 为 true 时忽略 `results` 内容，显示加载指示器
   - `results` 为空且 `isLoading` 为 false 时显示空状态

2. **日期格式**：内部 `_formatDate` 方法格式化为 `YYYY-MM-DD`

3. **本地化**：使用 `AppLocalizations.of(context)` 获取本地化字符串

4. **滚动行为**：使用 `ListView.builder` 支持大量结果的高效渲染

5. **点击交互**：
   - 整个卡片可点击
   - 点击后触发 `onResultTap` 回调（如果提供）

## 相关文件

- `lib/pages/drawing_search_page.dart` - 使用该组件的搜索页面
- `lib/widgets/search_input_card_guide.md` - 搜索输入框组件文档
- `lib/services/drawing_service.dart` - DrawingEntry 数据模型
