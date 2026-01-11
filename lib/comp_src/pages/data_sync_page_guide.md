# DataSyncPage 组件文档

## 组件职责

数据同步页面，支持 WiFi Direct 点对点增量同步图纸数据。

## 代码位置

`lib/comp_src/pages/data_sync_page.dart`

## 功能概述

本页面实现了基于 WiFi Direct 的点对点数据同步功能，用户可以：
- 扫描附近安装了本应用的设备
- 将设备设置为可被发现模式，等待连接
- 建立点对点连接后进行增量数据同步
- 实时查看同步进度和传输统计

## 技术架构

### MVVM 架构

- **View (DataSyncPage)**：UI 层，使用 `ChangeNotifierProvider` 管理状态
- **ViewModel (DataSyncViewModel)**：业务逻辑层，继承 `ChangeNotifier`
- **Model (NearByDevice)**：设备信息数据模型

### 状态管理

使用 `Provider` + `ChangeNotifier` 模式：
- `DataSyncViewModel` 继承 `ChangeNotifier`
- 页面通过 `Consumer<DataSyncViewModel>` 订阅状态变化
- 使用 `AnimatedSwitcher` 实现平滑的状态切换动画

## 核心功能

### 1. 空闲状态 (Idle)

显示两个入口卡片：
- **我要发送**：扫描附近设备
- **我要接收**：开启可被发现模式

### 2. 扫描设备 (Scanning)

- 显示扫描进度指示器
- 实时展示发现的设备列表
- 支持取消扫描操作

### 3. 可被发现模式 (Discoverable)

- 显示雷达波纹动画（`RadarWaves`）
- 显示本机设备名称
- 等待其他设备发起连接请求

### 4. 连接流程

**主动连接**：
- 扫描到设备后点击设备卡片发起连接
- 进入"连接中"状态，等待对方确认

**被动连接**：
- 收到连接请求后显示确认对话框
- 用户可以选择接受或拒绝连接

### 5. 数据同步

建立连接后：
- 显示"开始同步"按钮
- 同步中显示环形进度条和百分比
- 完成后显示传输统计信息

## 状态流转

```
idle (空闲)
├── startScanning() → scanning (扫描中)
│   └── 找到设备 → 选择设备 → connecting (连接中)
│       └── 对方接受 → connected (已连接)
│
├── startDiscoverable() → discoverable (可被发现)
│   └── 收到连接请求 → pendingApproval (待确认)
│       ├── 接受 → connected (已连接)
│       ┋ 拒绝 → discoverable (可被发现)
│
└── connected → startSync() → syncing (同步中)
    └── 完成 → completed (完成)
```

## UI 组件

### 主视图结构

```
Scaffold
├── AppBar (导航栏)
├── Stack
│   ├── _GridPainter (网格背景)
│   └── SafeArea
│       └── AnimatedSwitcher (状态切换动画)
│           └── _buildBodyContent (根据状态显示不同视图)
└── 底部提示栏
```

### 状态视图

| 状态 | 视图方法 | 说明 |
|------|---------|------|
| `idle` | `_buildIdleView()` | 两个大卡片入口 |
| `scanning` | `_buildScanningView()` | 扫描动画 + 设备列表 |
| `discoverable` | `_buildDiscoverableView()` | 雷达波纹动画 |
| `connecting` | `_buildConnectingView()` | 等待对方确认 |
| `pendingApproval` | `_buildApprovalView()` | 接受/拒绝按钮 |
| `connected` | `_buildConnectedView()` | 同步按钮/进度/结果 |
| `failed` | `_buildErrorView()` | 错误提示 |

### 自定义组件

#### `_GridPainter`

网格背景绘制器，绘制 32x32 的网格线。

#### `RadarWaves`

雷达波纹动画组件：
- 使用 `AnimationController` 控制动画
- 绘制 3 个扩散的圆圈
- 可自定义颜色

#### `_RadarPainter`

雷达波纹绘制器，实现波纹扩散效果。

#### `_BigActionCard`

大卡片组件，用于"我要发送"和"我要接收"入口。

#### `_DeviceCard`

设备卡片组件，显示设备信息。

## 使用示例

### 示例 1：基本使用

```dart
// 导航到数据同步页面
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DataSyncPage(),
  ),
);
```

### 示例 2：带初始数据

```dart
// 如果需要传递初始参数（预留）
DataSyncPage(
  initialMode: SyncMode.send,
);
```

### 示例 3：在 Drawer 中使用

```dart
Drawer(
  child: ListView(
    children: [
      ListTile(
        leading: Icon(Icons.sync),
        title: Text('数据同步'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DataSyncPage(),
            ),
          );
        },
      ),
    ],
  ),
)
```

## 依赖关系

### ViewModel 依赖

```dart
import '../view_models/data_sync_view_model.dart';
```

### Flutter 依赖

```dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
```

## 设计规范

### 颜色方案

| 用途 | 颜色 | 说明 |
|------|------|------|
| 主色调 | `Theme.of(context).colorScheme.primary` | 主操作按钮、图标 |
| 成功色 | `Color(0xFF10B981)` | 可被发现模式、接受按钮 |
| 警告色 | `Color(0xFFF59E0B)` | 连接请求提示 |
| 错误色 | `Color(0xFFEF4444)` | 取消操作、错误提示 |
| 次要文本 | `Color(0xFF64748B)` | 说明文字 |
| 边框色 | `Color(0xFF94A3B8)` | 浅色模式边框 |
| 次要边框 | `Color(0xFFCBD5E1)` | 图标颜色 |

### 圆角规范

- 大卡片：`BorderRadius.circular(20)`
- 普通卡片：`BorderRadius.circular(16)`
- 按钮：`BorderRadius.circular(12)`
- 小卡片：`BorderRadius.circular(14)`

### 间距规范

- 页面边距：`24px`
- 卡片内边距：`16-20px`
- 组件间距：`8-16px`
- 大间距：`32-48px`

## 注意事项

1. **WiFi Direct 权限**：需要在 `AndroidManifest.xml` 中配置相关权限
2. **后端待实现**：当前 ViewModel 中的 WiFi Direct 功能使用模拟数据
3. **状态一致性**：确保 UI 状态与 ViewModel 状态同步
4. **动画性能**：使用 `AnimatedBuilder` 优化变换矩阵渲染性能

## 后续优化

- [ ] 实现真实的 WiFi Direct 连接
- [ ] 添加同步前文件预览
- [ ] 支持同步方向选择（发送/接收/双向）
- [ ] 添加文件冲突处理 UI
- [ ] 实现同步历史记录
- [ ] 支持设备收藏功能
