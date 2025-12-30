# DrawingSearchPage 组件指南

## 组件职责

`DrawingSearchPage` 是图纸搜索页面，负责搜索和展示已归档的图纸记录：

- **关键词搜索**：根据图纸编号关键词搜索
- **日期筛选**：按日期范围筛选（当前未实现）
- **排序切换**：支持升序/降序切换
- **结果展示**：列表展示搜索结果，显示编号、日期、状态

---

## 代码位置

```
lib/pages/drawing_search_page.dart
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

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter: sdk: flutter
```

### 内部依赖

```
lib/services/drawing_service.dart  # 业务逻辑服务
lib/l10n/app_localizations.dart    # 国际化
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
// 用户在输入框输入关键词后按回车
TextField(
  controller: _searchController,
  onSubmitted: (_) => _performSearch(),
);

// 或点击搜索按钮
InkWell(
  onTap: _performSearch,
  child: Icon(Icons.search),
);
```

### 示例3：切换排序方式

```dart
// 点击排序按钮切换升序/降序
setState(() {
  _isAscending = !_isAscending;
});
_loadResults();  // 重新加载数据
```

---

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| SearchCard | 155-197行 | 搜索输入框和搜索按钮 |
| DateRangeButton | 213-269行 | 日期范围筛选按钮（功能未实现） |
| OrderToggle | 351-392行 | 升序/降序切换按钮 |
| ResultsList | 394-411行 | 搜索结果列表 |
| ResultCard | 413-493行 | 单个搜索结果卡片 |
| GridPainter | 496-515行 | 网格背景绘制 |

---

## 修改注意事项

### 🔴 未实现功能

| 功能 | 行号 | 状态 |
|------|------|------|
| 日期范围选择器 | 80-89 | 显示"当前功能未实现"提示 |

### 搜索逻辑

搜索在 `DrawingService.searchDrawings()` 中执行，当前返回模拟数据。

### 日期格式化

```dart
// 第54-57行：日期格式化函数
String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

### 结果卡片点击

```dart
// 第419行：点击结果卡片（当前为空操作）
onTap: () {},
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/services/drawing_service.dart` | 提供搜索功能 |
| `lib/pages/drawing_scanner_page.dart` | 通过搜索按钮从此页跳转 |
| `lib/l10n/app_localizations.dart` | 国际化文本 |
