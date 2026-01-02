# DrawingSearchPage 组件指南

## 组件职责

`DrawingSearchPage` 是图纸搜索页面，负责搜索和展示已归档的图纸记录：

- **关键词搜索**：根据图纸编号关键词搜索
- **日期筛选**：按日期范围筛选（当前未实现）
- **排序切换**：支持升序/降序切换
- **结果展示**：列表展示搜索结果，显示编号、日期、状态
- **图片预览**：点击搜索结果打开全屏图片查看器
- **日期清除**：清除已设置的日期筛选条件

---

## 代码位置

```
lib/comp_src/pages/drawing_search_page.dart
```

---

## 输入与输出

### 输入（构造参数）

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `drawingService` | `DrawingService` | 是 | 核心业务逻辑服务实例 |

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 返回上一页 | 点击左上角返回按钮 |
| 显示 SnackBar | 搜索完成时显示提示 |
| 日期清除对话框 | 有日期筛选时点击日期按钮弹出 |
| 打开全屏图片查看器 | 点击搜索结果卡片时打开 |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter: sdk: flutter
```

### 内部依赖

```
lib/comp_src/services/drawing_service.dart       # 业务逻辑服务
lib/l10n/app_localizations.dart                  # 国际化
lib/comp_src/widgets/search_input_card.dart      # 搜索输入框组件
lib/comp_src/widgets/search_results_list.dart    # 搜索结果列表组件
lib/comp_src/widgets/full_screen_image_viewer.dart  # 全屏图片查看器
```

---

## 状态管理

### 主要状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `_searchController` | `TextEditingController` | 搜索输入控制器 |
| `_isAscending` | `bool` | 是否升序排序 |
| `_startDate` | `DateTime?` | 开始日期筛选 |
| `_endDate` | `DateTime?` | 结束日期筛选 |
| `_results` | `List<DrawingEntry>` | 搜索结果列表 |
| `_isLoading` | `bool` | 是否正在加载 |

---

## 使用示例

### 示例1：从扫描页跳转

```dart
// 在 DrawingScannerPage 中
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DrawingSearchPage(
    drawingService: widget.drawingService,
  )),
);
```

### 示例2：执行搜索

```dart
// 通过 SearchInputCard 组件触发
SearchInputCard(
  controller: _searchController,
  hintText: l10n.searchPlaceholder,
  onSearch: _performSearch,
  onSubmitted: (_) => _performSearch(),
);
```

### 示例3：点击搜索结果查看图片

```dart
// 处理搜索结果点击，打开全屏图片查看器
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
        enableRotation: false, // 搜索结果不需要旋转功能
      ),
    ),
  );
}
```

### 示例4：切换排序方式

```dart
// 点击排序按钮切换升序/降序
Widget _buildOrderToggle(AppLocalizations l10n) {
  return InkWell(
    onTap: () {
      setState(() {
        _isAscending = !_isAscending;
      });
      _loadResults();  // 重新加载数据
    },
    // ...
  );
}
```

---

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| `_buildAppBar` | 182-195 | 顶部导航栏（带返回按钮） |
| `_buildGridBackground` | 197-203 | 网格背景容器 |
| `SearchInputCard` | 152-158 | 搜索输入框和搜索按钮（独立组件） |
| `_buildFilterSection` | 160-216 | 筛选区域容器（日期+排序） |
| `_buildDateRangeButton` | 219-275 | 日期范围筛选按钮（功能未实现） |
| `_buildOrderToggle` | 358-399 | 升序/降序切换按钮 |
| `SearchResultsList` | 164-173 | 搜索结果列表（独立组件） |
| `_showDateRangeClearDialog` | 291-356 | 日期清除对话框 |
| `_GridPainter` | 403-428 | 网格背景绘制 |
| `_handleResultTap` | 105-135 | 处理搜索结果点击 |

---

## 修改注意事项

### 🔴 未实现功能

| 功能 | 行号 | 状态 |
|------|------|------|
| 日期范围选择器 | 84-93 | 显示"当前功能未实现"提示 |

### 搜索逻辑

搜索在 `DrawingService.searchDrawings()` 中执行，返回真实已归档的图纸数据。

### 日期格式化

```dart
// 第58-61行：日期格式化函数
String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

### 日期筛选清除

```dart
// 第96-102行：清除日期筛选并重新加载
void _clearDateFilter() {
  setState(() {
    _startDate = null;
    _endDate = null;
  });
  _loadResults();
}
```

### 组件化改进

**重构后**（当前）：
- 使用独立的 `SearchInputCard` 组件（第 152-158 行）
- 使用独立的 `SearchResultsList` 组件（第 164-173 行）
- 代码更简洁、可复用性更强

### 图片查看功能

点击搜索结果卡片会打开全屏图片查看器（`FullScreenImageViewer`）：
- 验证文件存在性
- 支持多图滑动切换
- 显示图纸编号作为标题
- 禁用旋转功能（搜索结果不需要编辑）

### 边框样式增强

筛选按钮的边框样式（第 233-237 行）：
- 未激活时：1.5-2px，深色 `#94A3B8`，浅色 `#CBD5E1`
- 激活时：2px，主题色

### 网格背景

页面使用 `_GridPainter` 绘制网格背景（第 403-428 行）。

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/comp_src/pages/drawing_search_page.dart` | 页面代码 |
| `lib/comp_src/services/drawing_service.dart` | 提供搜索功能 |
| `lib/comp_src/widgets/search_input_card.dart` | 搜索输入框组件 |
| `lib/comp_src/widgets/search_results_list.dart` | 搜索结果列表组件 |
| `lib/comp_src/widgets/full_screen_image_viewer.dart` | 全屏图片查看器 |
| `lib/l10n/app_localizations.dart` | 国际化文本 |
