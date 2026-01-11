# DataSyncViewModel 组件文档

## 组件职责

数据同步页面的状态管理，管理 WiFi Direct 设备扫描、连接、增量同步和进度，以及设备名称持久化。

## 代码位置

`lib/comp_src/view_models/data_sync_view_model.dart`

## 功能概述

本 ViewModel 管理数据同步页面的所有业务逻辑和状态，包括：
- 设备发现和扫描
- WiFi Direct 连接管理
- 增量同步逻辑
- 同步进度和统计信息
- 设备名称的持久化存储和管理

## 技术架构

### 状态管理模式

- 继承 `ChangeNotifier`，使用 `notifyListeners()` 通知 UI 更新
- 所有状态变化通过 Getters 暴露给 UI 层
- 公共方法封装业务逻辑
- 使用 `SharedPreferences` 持久化设备名称

### 数据模型

#### `SyncStatus` 枚举

定义同步流程的所有状态：

```dart
enum SyncStatus {
  idle,           // 空闲
  discoverable,   // 可被发现模式（等待连接）
  scanning,       // 扫描设备中
  connecting,     // 连接中（等待对方确认）
  pendingApproval, // 等待我确认（有人请求连接）
  syncing,        // 同步中
  completed,      // 完成
  failed,         // 失败
}
```

#### `NearByDevice` 类

附近的设备信息：

```dart
class NearByDevice {
  final String id;      // 设备唯一标识
  final String name;    // 设备名称
  final String type;    // 设备类型 ('android', 'ios')
}
```

#### `FileTransferItem` 类

单个文件的传输状态：

```dart
class FileTransferItem {
  final String name;          // 文件名
  final int sizeBytes;        // 文件大小（字节）
  final TransferStatus status; // 传输状态
  final double progress;      // 传输进度 (0.0 - 1.0)
}
```

#### `SyncHistory` 类

同步历史记录：

```dart
class SyncHistory {
  final String deviceName;  // 同步的设备名称
  final DateTime time;      // 同步时间
  final int fileCount;      // 文件数量
  final int totalBytes;     // 总字节数
  final bool isSuccess;     // 是否成功
}
```

## 核心属性

### 状态变量

| 属性 | 类型 | 说明 |
|------|------|------|
| `_status` | `SyncStatus` | 当前同步状态 |
| `_nearbyDevices` | `List<NearByDevice>` | 附近设备列表 |
| `_currentDeviceId` | `String?` | 当前连接的设备 ID |
| `_pendingDevice` | `NearByDevice?` | 请求连接的设备（等待确认） |
| `_syncProgress` | `double` | 同步进度 (0.0 - 1.0) |
| `_errorMessage` | `String?` | 错误信息 |
| `_deviceName` | `String` | 本机设备名称 |

### 统计信息

| 属性 | 类型 | 说明 |
|------|------|------|
| `_totalFiles` | `int` | 总文件数 |
| `_syncedFiles` | `int` | 已同步文件数 |
| `_failedFiles` | `int` | 失败文件数 |
| `_transferSpeed` | `double` | 传输速度 (MB/s) |

## 公共方法

### 初始化

#### `init()`

初始化 ViewModel，加载设备名称和同步历史记录。

```dart
Future<void> init() async
```

**流程**：
1. 加载持久化的设备名称
2. 初始化模拟的同步历史记录
3. TODO: 初始化 WiFi Direct

### 设备扫描

#### `startScanning()`

开始持续扫描附近设备。

```dart
Future<void> startScanning() async
```

**流程**：
1. 设置状态为 `scanning`
2. 启动 WiFi Direct 扫描（TODO）
3. 持续更新发现的设备列表
4. 保持扫描状态直到手动停止或连接成功

**特性**：设备会随时间陆续出现，模拟真实的 WiFi Direct 设备发现行为。

#### `stopScanning()`

停止扫描设备。

```dart
void stopScanning()
```

**效果**：清空设备列表，恢复 `idle` 状态。

### 可被发现模式

#### `startDiscoverable()`

开启可被发现模式，等待其他设备连接。

```dart
Future<void> startDiscoverable() async
```

**流程**：
1. 设置状态为 `discoverable`
2. 启动 WiFi Direct 服务（TODO）
3. 等待连接请求

#### `stopDiscoverable()`

停止可被发现模式。

```dart
void stopDiscoverable()
```

#### `simulateIncomingConnection()`

模拟接收连接请求（仅用于 Debug 测试）。

```dart
void simulateIncomingConnection()
```

### 连接管理

#### `connectToDevice(String deviceId)`

主动连接到指定设备。

```dart
Future<bool> connectToDevice(String deviceId) async
```

**返回值**：连接请求已发送返回 `true`，失败返回 `false`

**流程**：
1. 设置状态为 `connecting`
2. 发送连接请求（TODO）
3. 等待对方确认
4. 通过 `simulateAcceptConnection()` 模拟对方接受

#### `simulateAcceptConnection()`

模拟对方接受连接（仅用于 Debug 测试）。

```dart
void simulateAcceptConnection()
```

#### `acceptConnection(String deviceId)`

接受连接请求（等待方调用）。

```dart
Future<void> acceptConnection(String deviceId) async
```

**触发时机**：当扫描方请求连接时，等待方调用此方法。

#### `rejectConnection()`

拒绝连接请求。

```dart
void rejectConnection()
```

**效果**：恢复到 `discoverable` 状态。

#### `disconnect()`

断开当前连接。

```dart
void disconnect()
```

**效果**：清空所有连接状态和统计数据，恢复 `idle` 状态。

### 数据同步

#### `startSync()`

开始同步数据。

```dart
Future<void> startSync() async
```

**流程**：
1. 检查是否已连接
2. 设置状态为 `syncing`
3. 交换元数据（TODO）
4. 对比差异，找出需要同步的文件（TODO）
5. 增量传输文件（TODO）
6. 更新进度和统计
7. 完成后设置状态为 `completed`

#### `cancelSync()`

取消同步。

```dart
void cancelSync()
```

**效果**：恢复 `idle` 状态，重置统计信息。

### 设备名称管理

#### `updateDeviceName(String newName)`

更新本机设备名称并持久化。

```dart
Future<void> updateDeviceName(String newName) async
```

**特性**：
- 自动去除首尾空格
- 验证非空
- 保存到 SharedPreferences
- 触发 UI 更新

## Getters

### 状态查询

| Getter | 返回类型 | 说明 |
|--------|---------|------|
| `status` | `SyncStatus` | 当前同步状态 |
| `nearbyDevices` | `List<NearByDevice>` | 附近设备列表 |
| `currentDeviceId` | `String?` | 当前连接的设备 ID |
| `pendingDevice` | `NearByDevice?` | 请求连接的设备 |
| `syncProgress` | `double` | 同步进度 (0.0 - 1.0) |
| `errorMessage` | `String?` | 错误信息 |
| `totalFiles` | `int` | 总文件数 |
| `syncedFiles` | `int` | 已同步文件数 |
| `failedFiles` | `int` | 失败文件数 |
| `fileTransferItems` | `List<FileTransferItem>` | 文件传输列表 |
| `syncHistory` | `List<SyncHistory>` | 同步历史记录 |
| `transferSpeed` | `double` | 传输速度 (MB/s) |
| `deviceName` | `String` | 本机设备名称 |
| `remainingSeconds` | `int` | 剩余时间估算（秒） |

### 便捷状态

| Getter | 返回类型 | 说明 |
|--------|---------|------|
| `isScanning` | `bool` | 是否正在扫描 |
| `isDiscoverable` | `bool` | 是否处于可被发现模式 |
| `isSyncing` | `bool` | 是否正在同步 |
| `isConnecting` | `bool` | 是否正在连接 |
| `hasError` | `bool` | 是否有错误 |

## 私有方法

### `_loadDeviceName()`

从 SharedPreferences 加载设备名称，首次使用时生成默认名称。

```dart
Future<void> _loadDeviceName() async
```

### `_generateDefaultDeviceName()`

生成默认设备名称（格式：`设备_XXXX`）。

```dart
String _generateDefaultDeviceName()
```

### `_setStatus()`

设置状态并通知监听器。

```dart
void _setStatus(SyncStatus status)
```

### `_setError()`

设置错误信息。

```dart
void _setError(String error)
```

### `_clearError()`

清除错误信息。

```dart
void _clearError()
```

### `_resetSyncStats()`

重置同步统计信息。

```dart
void _resetSyncStats()
```

## 使用示例

### 示例 1：基本使用（在 UI 中）

```dart
class DataSyncPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataSyncViewModel()..init(),
      child: Consumer<DataSyncViewModel>(
        builder: (context, viewModel, child) {
          // 根据 viewModel.status 显示不同 UI
          if (viewModel.isScanning) {
            return ScanningView();
          } else if (viewModel.isDiscoverable) {
            return DiscoverableView();
          }
          // ...
        },
      ),
    );
  }
}
```

### 示例 2：扫描设备

```dart
final viewModel = context.read<DataSyncViewModel>();

// 开始扫描（设备会陆续出现）
await viewModel.startScanning();

// 获取设备列表
final devices = viewModel.nearbyDevices;
print('找到 ${devices.length} 个设备');

// 停止扫描
viewModel.stopScanning();
```

### 示例 3：建立连接

```dart
// 主动连接
final success = await viewModel.connectToDevice(deviceId);
if (success) {
  print('连接请求已发送');
} else {
  print('连接失败');
}

// 模拟对方接受（Debug 模式）
viewModel.simulateAcceptConnection();

// 接受连接（等待方）
await viewModel.acceptConnection(deviceId);
```

### 示例 4：设备名称管理

```dart
final viewModel = context.read<DataSyncViewModel>();

// 获取当前设备名称
print('本机名称: ${viewModel.deviceName}');

// 更新设备名称
await viewModel.updateDeviceName('张工的 iPhone');

// 名称会自动持久化，下次启动应用时自动加载
```

### 示例 5：同步数据

```dart
// 开始同步
await viewModel.startSync();

// 监听进度
final progress = viewModel.syncProgress; // 0.0 - 1.0
final synced = viewModel.syncedFiles;
final total = viewModel.totalFiles;
final speed = viewModel.transferSpeed;

print('进度: ${(progress * 100).toInt()}%');
print('已同步: $synced / $total');
print('速度: ${speed} MB/s');
print('剩余时间: ${viewModel.remainingSeconds} 秒');
```

## 待实现功能

### WiFi Direct 集成

```dart
// 初始化 WiFi Direct
@override
Future<void> init() async {
  // TODO: 初始化 WiFi Direct
  // WiFiDirectService.initialize();
}
```

### 设备发现

```dart
Future<void> startScanning() async {
  // TODO: 实现真实的持续扫描逻辑
  // final devices = await WiFiDirectService.discoverDevices();
  // _nearbyDevices = devices;
}
```

### 连接建立

```dart
Future<bool> connectToDevice(String deviceId) async {
  // TODO: 实现真实的连接逻辑
  // 1. 发送连接请求
  // 2. 等待对方接受
  // 3. 建立连接
}
```

### 数据同步

```dart
Future<void> startSync() async {
  // TODO: 实现真实的同步逻辑
  // 1. 交换元数据（图纸编号、修改时间、文件哈希）
  // 2. 对比差异，找出需要同步的文件
  // 3. 增量传输（只传输对方没有的文件）
  // 4. 验证完成
}
```

## 注意事项

1. **后端依赖**：当前所有 WiFi Direct 相关功能使用模拟数据
2. **Debug 测试**：`simulateIncomingConnection()` 和 `simulateAcceptConnection()` 仅用于测试，生产环境需移除
3. **状态一致性**：确保状态转换逻辑正确，避免状态混乱
4. **资源清理**：在 `dispose()` 中清理 WiFi Direct 资源（待实现）
5. **错误处理**：所有异步操作都包含 try-catch 错误处理
6. **设备名称持久化**：使用 SharedPreferences 存储设备名称，确保跨会话保持

## 依赖关系

### 导入

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

### 被依赖

```dart
// 在 DataSyncPage 中
import '../view_models/data_sync_view_model.dart';
```

## 调试技巧

### 查看状态变化

```dart
viewModel.addListener(() {
  debugPrint('状态变化: ${viewModel.status}');
  debugPrint('设备数: ${viewModel.nearbyDevices.length}');
  debugPrint('进度: ${viewModel.syncProgress}');
});
```

### 模拟连接请求

```dart
if (kDebugMode) {
  // 在可被发现模式下测试连接请求
  viewModel.simulateIncomingConnection();

  // 在连接中状态下测试接受连接
  viewModel.simulateAcceptConnection();
}
```

### 监听同步进度

```dart
while (viewModel.isSyncing) {
  await Future.delayed(Duration(seconds: 1));
  print('进度: ${(viewModel.syncProgress * 100).toInt()}%');
  print('速度: ${viewModel.transferSpeed} MB/s');
}
```

### 测试设备名称

```dart
// 测试默认名称生成
print(viewModel.deviceName); // 设备_XXXX

// 测试更新和持久化
await viewModel.updateDeviceName('测试设备');
print(viewModel.deviceName); // 测试设备

// 重启应用验证持久化
// viewModel.deviceName 应该仍然是 '测试设备'
```
