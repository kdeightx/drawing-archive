# ActionButtons 组件文档

## 组件职责

操作按钮组件 - 显示三个主要操作按钮（清空、上传识别、保存），使用 Flex 布局，比例为 1:2:2，支持禁用状态和加载指示器。

## 代码位置

```
demo/lib/comp_src/widgets/action_buttons.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `onClearAll` | `VoidCallback?` | 是 | - | 清空列表回调（null 则不显示按钮）|
| `onUpload` | `VoidCallback?` | 是 | - | 上传识别回调（null 则不显示按钮）|
| `onSave` | `VoidCallback?` | 是 | - | 保存回调 |
| `isAnalyzing` | `bool` | 是 | - | 是否正在分析（AI 识别中）|
| `isSaving` | `bool` | 是 | - | 是否正在保存 |
| `isListEmpty` | `bool` | 是 | - | 列表是否为空 |

### 输出

- 渲染一行三个按钮：
  - **清空按钮**：OutlinedButton，红色（深色 #EF4444，浅色 #DC2626），icon-only，flex 1
  - **上传识别按钮**：OutlinedButton，主题色，flex 2，识别中显示加载指示器
  - **保存按钮**：ElevatedButton，主题色，flex 2，保存中显示加载指示器

## 依赖项

### 外部依赖
- `package:flutter/material.dart`

### 内部依赖
- 无（独立组件）

## 使用示例

### 示例 1：基础用法

```dart
ActionButtons(
  onClearAll: () => print('清空列表'),
  onUpload: () => print('上传识别'),
  onSave: () => print('保存'),
  isAnalyzing: false,
  isSaving: false,
  isListEmpty: false,
)
```

### 示例 2：禁用状态

```dart
// 列表为空时，清空和上传按钮禁用
ActionButtons(
  onClearAll: _handleClear,
  onUpload: _handleUpload,
  onSave: _handleSave,
  isAnalyzing: false,
  isSaving: false,
  isListEmpty: true,  // 列表为空
)

// 正在识别时，所有按钮禁用
ActionButtons(
  onClearAll: _handleClear,
  onUpload: _handleUpload,
  onSave: _handleSave,
  isAnalyzing: true,  // 正在识别
  isSaving: false,
  isListEmpty: false,
)

// 正在保存时，所有按钮禁用
ActionButtons(
  onClearAll: _handleClear,
  onUpload: _handleUpload,
  onSave: _handleSave,
  isAnalyzing: false,
  isSaving: true,  // 正在保存
  isListEmpty: false,
)
```

### 示例 3：在 ActionCard 中使用

```dart
// ActionCard 内部使用 ActionButtons
class ActionCard extends StatelessWidget {
  final VoidCallback? onClearAll;
  final VoidCallback? onUpload;
  final VoidCallback onSave;
  final bool isAnalyzing;
  final bool isSaving;
  final List<NumberItem> numberItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 其他内容...

        // 操作按钮行
        ActionButtons(
          onClearAll: onClearAll,
          onUpload: onUpload,
          onSave: onSave,
          isAnalyzing: isAnalyzing,
          isSaving: isSaving,
          isListEmpty: numberItems.isEmpty,
        ),
      ],
    );
  }
}
```

### 示例 4：可选按钮

```dart
// onClearAll 为 null 时不显示清空按钮
ActionButtons(
  onClearAll: null,  // 不显示清空按钮
  onUpload: _handleUpload,
  onSave: _handleSave,
  isAnalyzing: false,
  isSaving: false,
  isListEmpty: false,
)
```

## UI 结构

```
Row
  ├── Expanded (flex: 1)
  │   └── OutlinedButton (清空按钮，红色)
  ├── SizedBox (width: 8)
  ├── Expanded (flex: 2)
  │   └── OutlinedButton (上传识别按钮，主题色)
  ├── SizedBox (width: 8)
  └── Expanded (flex: 2)
      └── ElevatedButton (保存按钮，主题色)
```

## 禁用逻辑

| 按钮 | 禁用条件 |
|------|----------|
| 清空 | `isAnalyzing \|\| isSaving \|\| isListEmpty` |
| 上传识别 | `isAnalyzing \|\| isSaving \|\| isListEmpty \|\| onUpload == null` |
| 保存 | `isAnalyzing \|\| isSaving` |

## 样式规范

### 按钮尺寸
- 高度：48px（固定）
- 图标大小：18px
- 文字大小：14px
- 间距：8px（按钮之间）
- 图标文字间距：6px

### 颜色规范

#### 清空按钮（红色警告）
- **前景色**：
  - 深色模式：`#EF4444`
  - 浅色模式：`#DC2626`
- **边框颜色**：
  - 启用：同前景色，宽度 1.5
  - 禁用：深色 `#475569`，浅色 `#E2E8F0`

#### 上传识别按钮（主题色）
- **前景色**：
  - 启用：`Theme.of(context).colorScheme.primary`
  - 禁用：深色 `#475569`，浅色 `#E2E8F0`
- **边框颜色**：
  - 启用：主题色，宽度 1.5
  - 禁用：深色 `#475569`，浅色 `#E2E8F0`

#### 保存按钮（主题色）
- **背景色**：
  - 启用：`Theme.of(context).colorScheme.primary`
  - 禁用：深色 `#475569`，浅色 `#E2E8F0`
- **前景色**：白色（启用）

### 圆角和形状
- 所有按钮：`BorderRadius.circular(12)`
- 形状：`RoundedRectangleBorder`

### 优化
- 使用 `tapTargetSize: MaterialTapTargetSize.shrinkWrap` 减小触摸目标尺寸
- 避免小屏幕布局溢出

## 加载状态

### 上传识别按钮加载指示器
```dart
if (isAnalyzing) {
  return CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(
      isDark ? Color(0xFF475569) : Color(0xFFE2E8F0),
    ),
  );
}
```

### 保存按钮加载指示器
```dart
if (isSaving) {
  return CircularProgressIndicator(
    strokeWidth: 2,
    color: Colors.white,
  );
}
```

## 修改注意事项

1. **按钮布局比例**：固定为 1:2:2，不建议修改，以保持视觉平衡

2. **禁用状态优先级**：
   - `isAnalyzing` > `isSaving` > `isListEmpty`
   - 任何禁用条件为 true 时，按钮都会禁用

3. **主题适配**：上传识别和保存按钮使用 `Theme.of(context).colorScheme.primary`，自动适配深色/浅色主题

4. **加载指示器颜色**：
   - 上传按钮：禁用状态的灰色（深色 `#475569`，浅色 `#E2E8F0`）
   - 保存按钮：白色（在主题色背景上）

5. **按钮文本**：
   - 上传识别：固定显示"上传识别"
   - 保存：固定显示"保存图片"
   - 清空：仅显示图标，无文本

6. **Null 处理**：
   - `onClearAll` 和 `onUpload` 为 null 时不显示对应按钮
   - `onSave` 必须提供（不能为 null）

7. **组件定位**：
   - 专用于 ActionCard 组件
   - 不建议在其他地方复用（除非需要完全相同的按钮布局）

## 相关文件

- `lib/comp_src/widgets/action_card.dart` - 使用该组件的主组件
- `lib/comp_src/widgets/action_card_guide.md` - ActionCard 组件文档
- `lib/comp_src/pages/drawing_scanner_page.dart` - 使用 ActionCard 的页面
