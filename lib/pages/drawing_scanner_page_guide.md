# DrawingScannerPage 组件指南

## 组件职责

`DrawingScannerPage` 是应用的主页面，负责图纸的扫描、识别和归档流程：

- **图片选择**：支持相机拍照（单张）和相册多选
- **图片预览**：支持缩放、滑动切换查看多张图片
- **AI识别**：调用 DrawingService 分析图片识别图纸编号
- **进度显示**：三阶段进度指示器（发送中 → AI扫描中 → 已完成）
- **编号编辑**：手动编辑/修正 AI 识别的编号，支持分页显示
- **批量保存**：将所有图片及其编号批量保存
- **导航入口**：跳转到搜索页面和设置页面

---

## 代码位置

```
lib/pages/drawing_scanner_page.dart
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
| 跳转搜索页 | 点击"搜索已归档图纸"按钮，跳转到 DrawingSearchPage |
| 跳转设置页 | 点击右上角设置图标，跳转到 DrawingSettingsPage |
| 显示 SnackBar | 操作成功/失败时显示提示信息 |
| 进度指示 | 显示三阶段进度条（发送中 → AI扫描中 → 已完成） |
| 返回上一页 | 保存成功后重置页面状态 |

---

## 依赖项

### 外部依赖

```yaml
dependencies:
  flutter: sdk: flutter
```

### 内部依赖

```
lib/services/drawing_service.dart    # 业务逻辑服务
lib/l10n/app_localizations.dart      # 国际化
lib/pages/drawing_search_page.dart   # 搜索页面
lib/pages/drawing_settings_page.dart # 设置页面
```

---

## 状态管理

### 主要状态变量

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

### 控制器

| 控制器 | 用途 |
|--------|------|
| `_transformationController` | 图片缩放变换控制 |
| `_pageController` | 图片滑动切换控制 |
| `_pulseController` | 占位符脉冲动画（1500ms，反向重复） |
| `_rotationController` | 进度节点旋转光环动画（1200ms，持续重复） |

### 枚举类型

#### ProgressState（进度状态）

```dart
enum ProgressState {
  sending,    // 发送数据中
  scanning,   // AI扫描中
  completed,  // 扫描完成
}
```

| 值 | 颜色 | 说明 |
|----|------|------|
| `sending` | 蓝色 (#3B82F6) | 发送数据到 AI |
| `scanning` | 橙色 (#F59E0B) | AI 正在扫描识别 |
| `completed` | 绿色 (#10B981) | 识别完成 |
| `null` | 灰色 (#94A3B8) | 空闲就绪状态 |

---

## 使用示例

### 示例1：在路由中启动页面

```dart
// 在 main.dart 或其他页面中
MaterialPageRoute(
  builder: (context) => DrawingScannerPage(
    drawingService: DrawingService(),
  ),
)
```

### 示例2：从设置页返回后保持状态

```dart
// 页面本身是 StatefulWidget，状态自动保持
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DrawingSettingsPage()),
);
// 返回后图片和编号数据仍然保留
```

### 示例3：触发进度状态变化

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

---

## UI 子组件

| 子组件 | 代码位置 | 说明 |
|--------|----------|------|
| AppBar | 362-380行 | 顶部导航栏，包含设置按钮 |
| ProgressHeader | 389-473行 | 进度头部，显示状态文字和百分比 |
| ProgressIndicator | 475-566行 | 三节点链式进度指示器 |
| ProgressNode | 568-602行 | 单个进度圆球节点 |
| ActiveNodeContent | 604-650行 | 活跃节点内容（旋转光环） |
| CompletedNodeContent | 652-659行 | 已完成节点内容（勾选图标） |
| StageLabel | 661-704行 | 阶段标签（带活跃状态指示点） |
| ImageCard | 706-721行 | 图片显示卡片容器 |
| Placeholder | 723-762行 | 空状态占位符（脉冲动画） |
| ImageViewer | 764-814行 | 支持缩放和滑动的图片查看器 |
| PageIndicator | 816-836行 | 多图页面指示器 |
| ActionCard | 838-875行 | 操作按钮卡片容器 |
| ActionButton | 877-908行 | 单个操作按钮（相机/相册） |
| SearchButton | 910-949行 | 搜索按钮 |
| NumberSection | 951-1066行 | 编号编辑区域（含分页） |
| NumberItem | 1068-1206行 | 单个编号输入项（带缩略图） |
| PaginationButtons | 1208-1321行 | 分页按钮组 |
| ConfirmImageDialog | 1324-1496行 | 多选图片确认对话框 |

### CustomPainter 绘制器

| 绘制器 | 代码位置 | 说明 |
|--------|----------|------|
| `_ConnectorLinePainter` | 1498-1540行 | 进度连接线绘制器 |
| `_ArcPainter` | 1542-1571行 | 270° 旋转弧线绘制器 |
| `_GridPainter` | 1573-1592行 | 网格背景绘制器 |

---

## 修改注意事项

### 分页设置

```dart
// 第43行：每页显示的编号数量
static const int _numbersPerPage = 5;
```

如需调整每页显示数量，修改此常量。

### 图片缩放范围

```dart
// 第781-782行：缩放范围
minScale: 0.5,
maxScale: 4.0,
```

### 进度显示时长

```dart
// 第183行和第227行：完成状态显示时长
await Future.delayed(const Duration(seconds: 3));
```

完成状态显示3秒后自动回归空闲状态。

### 进度节点尺寸

```dart
// 第579行：节点尺寸配置
width: isActive ? 28 : (isCompleted ? 22 : 16),
height: isActive ? 28 : (isCompleted ? 22 : 16),
```

- 活跃节点：28px
- 已完成节点：22px
- 未激活节点：16px

### AI 识别流程

1. 用户选择图片后，**自动触发** AI 识别
2. 先显示"发送中"状态（500ms）
3. 然后显示"AI扫描中"状态，调用 `analyzeImage()`
4. 识别完成后显示"已完成"状态（3秒）
5. 识别结果自动填入编号输入框
6. 用户可手动修改识别结果
7. 保存时检查所有编号是否已填写

### 批量处理逻辑

- **相机拍照**：单张处理，直接识别
- **相册多选**：先显示确认对话框，确认后批量识别
- **保存**：检查所有编号已填写后，循环调用 `saveEntry()` 保存

### 标签容器宽度

```dart
// 第551行：标签容器宽度
width: 56, // 确保最长标签"AI扫描中"单行显示
```

如需修改标签文字，确保容器宽度足够容纳5个中文字符。

### 动画控制器配置

```dart
// 第57-64行：动画控制器初始化
_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);

_rotationController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1200),
)..repeat();
```

- 脉冲动画：1500ms，反向重复
- 旋转动画：1200ms，持续重复

### 权限处理

权限请求已在 `DrawingService` 中处理，页面只需处理返回结果。

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/services/drawing_service.dart` | 提供图片选择、识别、保存功能 |
| `lib/pages/drawing_search_page.dart` | 通过搜索按钮跳转 |
| `lib/pages/drawing_settings_page.dart` | 通过设置按钮跳转 |
| `lib/l10n/app_localizations.dart` | 国际化文本 |
