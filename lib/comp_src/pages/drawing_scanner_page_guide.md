# DrawingScannerPage 组件文档

## 组件职责

图纸扫描入库页面 - 应用主页面，负责图纸的扫描、识别和归档流程：

- **图片选择**：支持相机拍照（单张）和相册多选
- **图片预览**：支持缩放、滑动切换、点击查看全屏预览
- **AI识别**：调用 DrawingService 分析图片识别图纸编号
- **进度显示**：三阶段进度指示器（发送中 → AI扫描中 → 已完成）
- **编号编辑**：手动编辑/修正 AI 识别的编号，支持分页显示
- **批量保存**：将所有图片及其编号批量保存
- **导航入口**：跳转到搜索页面和设置页面

**架构设计**：
- **MVVM 模式**：View（本页面）+ ViewModel（DrawingScannerViewModel）
- **组件化**：页面拆分为多个可复用子组件
- **状态管理**：使用 Provider 的 ChangeNotifier
- **导航分离**：ViewModel 决策导航，View 执行导航

## 代码位置

```
lib/comp_src/pages/drawing_scanner_page.dart
```

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
| 全屏预览 | 点击图片打开全屏预览（ViewModel 决策，View 执行导航）|
| 显示 SnackBar | 操作成功/失败时显示提示信息 |
| 进度指示 | 显示三阶段进度条（带颜色区分） |
| 状态重置 | 完成状态3秒后恢复非活跃状态 |

## 依赖项

### 外部依赖
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `dart:io` - File 类型

### 内部依赖
```
../services/drawing_service.dart         # 业务逻辑服务
../view_models/drawing_scanner_view_model.dart  # ViewModel 状态管理
../widgets/action_card.dart              # 操作卡片组件
../widgets/full_screen_image_viewer.dart # 全屏图片预览组件
../widgets/image_display_card.dart       # 图片显示卡片组件
../widgets/smart_process_stepper.dart    # 进度指示器组件
../../l10n/app_localizations.dart        # 国际化
drawing_search_page.dart                # 搜索页面
drawing_settings_page.dart               # 设置页面
```

## 状态管理

### 页面结构

```
DrawingScannerPage (StatelessWidget)
└── ChangeNotifierProvider
    └── _DrawingScannerView (StatefulWidget)
        └── ScrollController (本地管理)
```

**外层**：`DrawingScannerPage` (StatelessWidget)
- 负责创建 Provider
- 传入 DrawingService

**内层**：`_DrawingScannerView` (StatefulWidget)
- 实际的 UI 实现
- 管理本地 ScrollController
- 通过 Consumer 订阅 ViewModel 状态变化
- 监听导航状态并执行导航

### 控制器

**本页面**：
本页面无控制器（采用弹性布局，不需要滚动控制）

**其他控制器**：
- `PageController` - 由 ImageDisplayCard 自管理
- `TransformationController` - 由 ImageDisplayCard 自管理
- `TextEditingController` - 由 ViewModel 管理（每个图片一个）

### ViewModel 状态

完整的状态管理说明请参考：`drawing_scanner_view_model_guide.md`

**主要状态**：
- `selectedImages` - 选中的图片列表
- `currentImageIndex` - 当前查看的图片索引
- `recognizedNumbers` - AI 识别结果
- `numberControllers` - 编号输入控制器列表
- `progressState` - 当前进度状态
- `shouldOpenImagePreview` - 是否需要打开全屏预览（导航状态）
- `previewImageIndex` - 要预览的图片索引

### MVVM 导航架构

```dart
// View 层：监听导航状态并执行导航
Consumer<DrawingScannerViewModel>(
  builder: (context, viewModel, child) {
    // 监听导航状态
    if (viewModel.shouldOpenImagePreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final imagePaths = viewModel.selectedImages
            .map((f) => f.path)
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              imagePaths: imagePaths,
              initialIndex: viewModel.previewImageIndex,
            ),
          ),
        ).then((_) {
          // 预览关闭后清除状态
          viewModel.clearImagePreviewState();
        });
      });
    }

    return SingleChildScrollView(...);
  },
)

// Widget 层：通知用户交互
ImageDisplayCard(
  onImageTap: (index) => viewModel.onImageTapped(index),
)

// ViewModel 层：决策导航
void onImageTapped(int index) {
  _previewImageIndex = index;
  _shouldOpenImagePreview = true;
  notifyListeners();
}
```

**职责划分**：
- **ViewModel**：决定何时导航（设置状态）
- **View**：执行导航（监听状态并调用 Navigator）
- **Widget**：通知用户交互（通过回调）

## 使用示例

### 示例 1：在路由中启动页面

```dart
MaterialPageRoute(
  builder: (context) => DrawingScannerPage(
    drawingService: DrawingService(),
  ),
)
```

### 示例 2：结合全局服务实例

```dart
class MyApp extends StatelessWidget {
  final DrawingService _drawingService = DrawingService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => HomePage(),
        '/scan': (context) => DrawingScannerPage(
          drawingService: _drawingService,
        ),
      },
    );
  }
}
```

### 示例 3：作为 BottomNavigationBarItem

```dart
class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final DrawingService _drawingService = DrawingService();
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SizedBox(), // 占位
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DrawingScannerPage(drawingService: _drawingService),
          // 其他页面...
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.scanner),
            label: '扫描',
          ),
          // 其他导航项...
        ],
      ),
    );
  }
}
```

## UI 子组件

| 组件 | 文件 | 说明 |
|------|------|------|
| `ActionCard` | `../widgets/action_card.dart` | 操作卡片（相机、相册、搜索按钮 + 编号编辑列表） |
| `ImageDisplayCard` | `../widgets/image_display_card.dart` | 图片显示卡片（滑动、缩放、点击预览、页码指示器） |
| `SmartProcessStepper` | `../widgets/smart_process_stepper.dart` | 进度指示器（三阶段步骤条） |
| `FullScreenImageViewer` | `../widgets/full_screen_image_viewer.dart` | 全屏图片预览组件 |

### 主要 build 方法

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildAppBar()` | 84-103 | 构建 AppBar（包含设置按钮） |
| `_buildGridBackground()` | 106-113 | 构建网格背景（CustomPainter） |
| `_buildHeader()` | 115-231 | 构建进度卡片（状态文字 + 进度指示器） |
| `_buildImageCard()` | 233-248 | 构建图片卡片（ImageDisplayCard，包含导航回调） |
| `_buildActionCard()` | 250-327 | 构建操作卡片（ActionCard） |
| `_showSnackBar()` | 329-372 | 显示提示信息 |

### 辅助类

#### _GridPainter (CustomPainter)
- 绘制 32px 网格背景
- 根据主题调整颜色深浅

## 修改注意事项

### MVVM 分离原则
- **View（本页面）**：纯 UI 渲染，不包含业务逻辑，执行导航
- **ViewModel**：状态管理和业务逻辑，决策导航
- **Service**：数据持久化和 API 调用

### 导航状态管理（MVVM 架构）
- **使用 addPostFrameCallback**：在下一帧执行导航，避免在 build 期间调用 Navigator
- **状态驱动导航**：ViewModel 设置 `shouldOpenImagePreview = true`，View 监听并执行导航
- **预览关闭清除状态**：Navigator.then() 中调用 `clearImagePreviewState()`

### 弹性布局设计
页面采用**自适应弹性布局**，解决小屏幕适配问题：

**布局结构**：
```dart
Column(
  children: [
    Padding(
      child: _buildHeader(), // 顶部：进度卡片（固定高度）
    ),
    Expanded(
      child: _buildImageCard(), // 中间：图片卡片（弹性占据剩余空间）
    ),
    Padding(
      child: _buildActionCard(), // 底部：操作卡片（固定在底部）
    ),
  ],
)
```

**优势**：
- ✅ 小屏设备（如 iPhone SE）：图片区域自动变小
- ✅ 大屏设备：图片区域自动变大
- ✅ 操作按钮永远固定在底部可见
- ✅ 避免溢出错误（Overflow Error）

**为什么不用滚动**：
- 操作按钮是最常用的交互，应该始终可见
- 图片区域可以适当缩小以适应屏幕
- 用户体验优于需要手动滚动才能看到按钮

### 组件自治
- **UI 控制器**：由各自的组件自行管理
  - PageController - ImageDisplayCard 内部
  - TransformationController - ImageDisplayCard 内部
- **ViewModel 不管理 UI 控制器**：保持架构清晰

### 状态同步
- 使用 `Consumer<DrawingScannerViewModel>` 订阅状态变化
- ViewModel 调用 `notifyListeners()` 时自动重建 UI
- 避免在 build 方法中直接修改状态

### SnackBar 位置计算
- 使用 `MediaQuery.of(context).padding.top` 获取安全区域高度
- `kToolbarHeight` 是 AppBar 的固定高度（56px）
- 计算 `topPosition` 让 SnackBar 显示在 AppBar 下方

### 网格背景性能
- `shouldRepaint` 返回 `false`（背景不变）
- 避免不必要的重绘

## 相关文件

| 文件 | 说明 |
|------|------|
| `drawing_scanner_view_model.dart` | ViewModel 状态管理 |
| `drawing_service.dart` | 业务逻辑服务 |
| `drawing_search_page.dart` | 搜索页面（可跳转） |
| `drawing_settings_page.dart` | 设置页面（可跳转） |
| `full_screen_image_viewer.dart` | 全屏预览组件 |
