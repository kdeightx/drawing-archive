# DrawingScannerPage 组件文档

## 组件职责

图纸扫描入库页面 - 应用主页面，负责图纸的扫描、识别和归档流程：

- **图片选择**：支持相机拍照（单张）和相册多选
- **图片预览**：支持缩放、滑动切换查看多张图片
- **AI识别**：调用 DrawingService 分析图片识别图纸编号
- **进度显示**：三阶段进度指示器（发送中 → AI扫描中 → 已完成）
- **编号编辑**：手动编辑/修正 AI 识别的编号，支持分页显示
- **批量保存**：将所有图片及其编号批量保存
- **导航入口**：跳转到搜索页面和设置页面

## 代码位置

`lib/pages/drawing_scanner_page.dart`

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `drawingService` | `DrawingService` | 是 | 核心业务逻辑服务实例 |

### 输出（行为/副作用）

| 行为 | 说明 |
|------|------|
| 跳转搜索页 | 点击"搜索已归档"按钮，跳转到 DrawingSearchPage |
| 跳转设置页 | 点击右上角设置图标，跳转到 DrawingSettingsPage |
| 显示 SnackBar | 操作成功/失败时显示提示信息 |
| 进度指示 | 显示三阶段进度条（带颜色区分） |
| 状态重置 | 完成状态3秒后恢复非活跃状态 |

## 依赖项

### 外部依赖
- `package:flutter/material.dart`
- `dart:io` - File 类型

### 内部依赖
```
../services/drawing_service.dart         # 业务逻辑服务
../widgets/action_card.dart               # 操作卡片组件（重构后）
../widgets/image_display_card.dart       # 图片显示卡片组件（重构后）
../widgets/smart_process_stepper.dart     # 进度指示器组件（重构后）
../l10n/app_localizations.dart           # 国际化
drawing_search_page.dart               # 搜索页面
drawing_settings_page.dart              # 设置页面
```

## 状态管理

### 状态变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `_selectedImages` | `List<File>` | 选中的图片列表 |
| `_currentImageIndex` | `int` | 当前查看的图片索引 |
| `_recognizedNumbers` | `List<String>` | 每张图片的 AI 识别结果 |
| `_numberControllers` | `List<TextEditingController>` | 每张图片的编号输入控制器 |
| `_numberPage` | `int` | 编号列表当前页码 |
| `_isAnalyzing` | `bool` | 是否正在分析图片 |
| `_isSaving` | `bool` | 是否正在保存 |
| `_progressState` | `ProgressState?` | 当前进度状态（null=空闲） |
| `_numbersPerPage` | `int` | 每页显示的编号数量（常量=5） |

### 控制器

| 控制器 | 用途 |
|--------|------|
| `_transformationController` | 图片缩放变换控制 |
| `_pageController` | 图片滑动切换控制 |
| `_scrollController` | 页面滚动控制 |
| `_pulseController` | 状态球脉冲动画（1500ms，反向重复） |

### 枚举类型

#### ProgressState（进度状态）

```dart
enum ProgressState {
  sending,    // 发送数据中
  scanning,   // AI扫描中
  completed,  // 扫描完成
}
```

## 使用示例

### 示例 1：在路由中启动页面

```dart
MaterialPageRoute(
  builder: (context) => DrawingScannerPage(
    drawingService: DrawingService(),
  ),
)
```

### 示例 2：触发进度状态变化

```dart
// 开始发送数据
setState(() => _progressState = ProgressState.sending);
await Future.delayed(const Duration(milliseconds: 500));

// AI 扫描中
setState(() => _progressState = ProgressState.scanning);

// 扫描完成
setState(() => _progressState = ProgressState.completed);

// 延迟3秒后回归空闲
await Future.delayed(const Duration(seconds: 3));
setState(() => _progressState = null);
```

### 示例 3：构建 NumberItem 列表

```dart
final numberItems = List.generate(_selectedImages.length, (index) {
  return NumberItem(
    id: 'img_$index',
    image: _selectedImages[index],
    index: index,
    number: _numberControllers[index].text,
    hasAiNumber: _recognizedNumbers[index].isNotEmpty,
  );
});
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildAppBar` | 396-414 | 顶部导航栏 |
| `_buildGridBackground` | 416-421 | 网格背景绘制器 |
| `_buildHeader` | 423-538 | 进度头部（使用 SmartProcessStepper） |
| `_buildImageCard` | 540-553 | 图片显示卡片（使用 ImageDisplayCard） |
| `_buildActionCard` | 556-652 | 操作卡片（使用 ActionCard） |
| `_showConfirmDialog` | 146-153 | 显示多选确认对话框 |
| `_ConfirmImageDialog` | 656-827 | 图片选择确认对话框组件 |
| `_GridPainter` | 829-848 | 网格背景绘制器 |

## 修改注意事项

### 组件重构（已完成）

页面已重构为使用独立组件：
- `ImageDisplayCard` - 图片显示功能
- `ActionCard` - 操作按钮和编号输入功能
- `SmartProcessStepper` - 进度指示功能

如需修改这些功能，请参考对应的组件文档：
- `lib/widgets/image_display_card_guide.md`
- `lib/widgets/action_card_guide.md`
- `lib/widgets/smart_process_stepper_guide.md`

### 分页设置

```dart
// 第46行：每页显示的编号数量
static const int _numbersPerPage = 5;
```

### 进度状态颜色

| 状态 | 颜色 |
|------|------|
| `sending` | 蓝色 (#3B82F6) |
| `scanning` | 橙色 (#F59E0B) |
| `completed` | 绿色 (#10B981) |
| `null` | 灰色（非活跃） |

### 完成状态时长

完成状态（`completed`）停留 3 秒后自动回归空闲状态（`null`）。

### 脉冲动画

```dart
// 第63-66行：脉冲动画控制器
_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);
```

### 确认对话框

多选图片时显示确认对话框，位于文件末尾的 `_ConfirmImageDialog` 类（第656-827行）。

### SnackBar 显示位置

SnackBar 显示在页面顶部（AppBar 下方），通过计算边距实现（第335-360行）。

### 批量分析

相册多选图片后，会批量分析所有图片（第199-244行）。

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/services/drawing_service.dart` | 提供图片选择、识别、保存功能 |
| `lib/widgets/smart_process_stepper_guide.md` | 进度指示器组件文档 |
| `lib/widgets/image_display_card_guide.md` | 图片显示卡片组件文档 |
| `lib/widgets/action_card_guide.md` | 操作卡片组件文档 |
| `lib/pages/drawing_search_page.dart` | 搜索页面 |
| `lib/pages/drawing_settings_page.dart` | 设置页面 |
