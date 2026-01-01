# SmartProcessStepper 组件文档

## 组件职责

智能进度条组件 - 数据驱动、可复用的多步骤进度指示器，支持任意数量的步骤显示，具有多层立体状态球设计。

## 代码位置

```
demo/lib/comp_src/widgets/smart_process_stepper.dart
```

## 输入与输出

### 构造参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `steps` | `List<StepData>` | 是 | 步骤数据列表 |
| `activeColor` | `Color` | 是 | 进度条激活颜色 |
| `backgroundColor` | `Color` | 是 | 背景颜色 |
| `isDark` | `bool` | 是 | 是否为深色模式 |
| `pulseController` | `AnimationController?` | 否 | 脉冲动画控制器 |

### 输出

- 渲染一个多步骤进度指示器，包含：
  - 圆环轨道连接线
  - 多层立体状态球
  - 步骤文字标签
  - 活跃状态指示点

## 依赖项

### 外部依赖
- `package:flutter/material.dart`

### 数据模型

#### StepData
```dart
class StepData {
  final String label;        // 步骤标签
  final bool isCompleted;    // 是否已完成
  final bool isActive;       // 是否活跃
  final Color? color;        // 自定义颜色（可选）
}
```

## 使用示例

### 示例 1：基础三步骤进度条

```dart
SmartProcessStepper(
  steps: [
    StepData(label: '发送中', isActive: true),
    StepData(label: '处理中'),
    StepData(label: '已完成'),
  ],
  activeColor: Colors.blue,
  backgroundColor: Colors.white,
  isDark: false,
)
```

### 示例 2：带自定义颜色的进度条

```dart
SmartProcessStepper(
  steps: [
    StepData(label: '发送中', isActive: true, color: Color(0xFF3B82F6)),
    StepData(label: '扫描中', color: Color(0xFFF59E0B)),
    StepData(label: '已完成', color: Color(0xFF10B981)),
  ],
  activeColor: Colors.blue,
  backgroundColor: Colors.white,
  isDark: false,
)
```

### 示例 3：带脉冲动画的进度条

```dart
// 在 State 类中创建 AnimationController
class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartProcessStepper(
      steps: [
        StepData(label: '步骤1', isActive: true),
        StepData(label: '步骤2', isCompleted: true),
        StepData(label: '步骤3'),
      ],
      activeColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).cardColor,
      isDark: Theme.of(context).brightness == Brightness.dark,
      pulseController: _pulseController,
    );
  }
}
```

## UI 子组件

| 方法 | 行号 | 说明 |
|------|------|------|
| `_buildNodeWidget` | 173-208 | 构建多层立体状态球 |
| `_buildBreathingGlow` | 211-228 | 呼吸光晕效果 |
| `_buildMainBall` | 230-300 | 主体球层（渐变/圆环） |
| `_buildHighlight` | 302-316 | 高光反射层 |
| `_buildActiveNodeContent` | 318-361 | 活跃节点脉冲核心 |
| `_buildCompletedNodeContent` | 363-383 | 已完成节点勾选图标 |

## 修改注意事项

1. **颜色逻辑**：步骤的自定义颜色 (`StepData.color`) 只在活跃或完成状态时生效，空闲状态使用全局 `activeColor`

2. **进度计算**：进度自动根据步骤的 `isCompleted` 和 `isActive` 状态计算，无需手动指定

3. **动画控制器**：`pulseController` 需要在组件外部创建和销毁，记得在 `dispose()` 中释放

4. **圆环参数**（`_SmartStepperPainter`）：
   - 外圆半径：13.0
   - 内圆半径：10.5
   - 连接线高度：2.5

5. **组件高度**：固定 32px（图形区）+ 5px（间距）+ 30px（文字区）= 67px

## 相关文件

- ```
demo/lib/comp_src/widgets/smart_process_stepper.dart
``` - 使用该组件的主页面
- ```
demo/lib/comp_src/widgets/smart_process_stepper.dart
``` - 图片显示卡片组件
- ```
demo/lib/comp_src/widgets/smart_process_stepper.dart
``` - 操作卡片组件
