import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据同步状态
enum SyncStatus {
  idle,          // 空闲
  discoverable,  // 可被发现模式（等待连接）
  scanning,      // 扫描设备中
  connecting,    // 连接中（等待对方确认）
  pendingApproval, // 等待我确认（有人请求连接）
  syncing,       // 同步中
  completed,     // 完成
  failed,        // 失败
}

/// 附近的设备信息
class NearByDevice {
  final String id;
  final String name;
  final String type; // 'android', 'ios'

  NearByDevice({
    required this.id,
    required this.name,
    required this.type,
  });
}

/// 单个文件的传输状态
class FileTransferItem {
  final String name;
  final int sizeBytes;
  final TransferStatus status;
  final double progress; // 0.0 - 1.0

  FileTransferItem({
    required this.name,
    required this.sizeBytes,
    required this.status,
    this.progress = 0.0,
  });

  String get sizeText {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  FileTransferItem copyWith({
    String? name,
    int? sizeBytes,
    TransferStatus? status,
    double? progress,
  }) {
    return FileTransferItem(
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

/// 文件传输状态
enum TransferStatus {
  pending,    // 等待传输
  transferring, // 传输中
  completed,  // 已完成
  failed,     // 失败
}

/// 同步历史记录
class SyncHistory {
  final String deviceName;
  final DateTime time;
  final int fileCount;
  final int totalBytes;
  final bool isSuccess;

  SyncHistory({
    required this.deviceName,
    required this.time,
    required this.fileCount,
    required this.totalBytes,
    required this.isSuccess,
  });

  String get sizeText {
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get timeText {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 数据同步视图模型 - MVVM 架构的业务逻辑层
///
/// 负责：
/// - WiFi Direct 设备发现和连接
/// - 增量同步逻辑（查缺补漏）
/// - 同步进度和状态管理
class DataSyncViewModel extends ChangeNotifier {
  // ===== 状态变量 =====

  SyncStatus _status = SyncStatus.idle;
  List<NearByDevice> _nearbyDevices = [];
  String? _currentDeviceId;
  NearByDevice? _pendingDevice; // 请求连接的设备
  double _syncProgress = 0.0;
  String? _errorMessage;

  // 统计信息
  int _totalFiles = 0;
  int _syncedFiles = 0;
  int _failedFiles = 0;

  // 文件传输列表
  List<FileTransferItem> _fileTransferItems = [];

  // 同步历史记录
  List<SyncHistory> _syncHistory = [];

  // 传输速度（模拟）
  double _transferSpeed = 0.0; // MB/s

  // 设备名称
  String _deviceName = '我的设备'; // 默认设备名称

  // ===== Getters =====

  /// 当前同步状态
  SyncStatus get status => _status;

  /// 附近的设备列表
  List<NearByDevice> get nearbyDevices => _nearbyDevices;

  /// 当前连接的设备 ID
  String? get currentDeviceId => _currentDeviceId;

  /// 请求连接的设备（等待我确认）
  NearByDevice? get pendingDevice => _pendingDevice;

  /// 同步进度（0.0 - 1.0）
  double get syncProgress => _syncProgress;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 总文件数
  int get totalFiles => _totalFiles;

  /// 已同步文件数
  int get syncedFiles => _syncedFiles;

  /// 失败文件数
  int get failedFiles => _failedFiles;

  /// 文件传输列表
  List<FileTransferItem> get fileTransferItems => _fileTransferItems;

  /// 同步历史记录
  List<SyncHistory> get syncHistory => _syncHistory;

  /// 传输速度（MB/s）
  double get transferSpeed => _transferSpeed;

  /// 本机设备名称
  String get deviceName => _deviceName;

  /// 剩余时间估算（秒）
  int get remainingSeconds {
    if (_transferSpeed <= 0 || _syncProgress >= 1.0) return 0;
    final remainingBytes = (_totalFiles - _syncedFiles) * 1024 * 1024; // 假设平均每个文件 1MB
    final remainingMB = remainingBytes / (1024 * 1024);
    return (remainingMB / _transferSpeed).round();
  }

  /// 是否正在扫描
  bool get isScanning => _status == SyncStatus.scanning;

  /// 是否处于可被发现模式
  bool get isDiscoverable => _status == SyncStatus.discoverable;

  /// 是否正在同步
  bool get isSyncing => _status == SyncStatus.syncing;

  /// 是否正在连接
  bool get isConnecting => _status == SyncStatus.connecting;

  /// 是否有错误
  bool get hasError => _errorMessage != null;

  // ===== 公共方法 =====

  /// 初始化 ViewModel
  Future<void> init() async {
    debugPrint('🔄 DataSyncViewModel: 初始化中...');
    // TODO: 初始化 WiFi Direct

    // 加载设备名称
    await _loadDeviceName();

    // 模拟同步历史记录
    _syncHistory = [
      SyncHistory(
        deviceName: '张工的设备',
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        fileCount: 23,
        totalBytes: 23 * 1024 * 1024, // 23 MB
        isSuccess: true,
      ),
      SyncHistory(
        deviceName: '李工的设备',
        time: DateTime.now().subtract(const Duration(hours: 5)),
        fileCount: 15,
        totalBytes: 15 * 1024 * 1024, // 15 MB
        isSuccess: true,
      ),
      SyncHistory(
        deviceName: '王工的设备',
        time: DateTime.now().subtract(const Duration(days: 1)),
        fileCount: 8,
        totalBytes: 8 * 1024 * 1024, // 8 MB
        isSuccess: false,
      ),
    ];

    debugPrint('✅ DataSyncViewModel: 初始化完成');
  }

  /// 开始扫描附近设备
  ///
  /// 使用 WiFi Direct 或 mDNS 扫描附近安装了本应用的设备
  /// 扫描会持续进行，直到连接成功或手动停止
  Future<void> startScanning() async {
    debugPrint('🔍 DataSyncViewModel: 开始持续扫描设备...');

    _setStatus(SyncStatus.scanning);
    _clearError();
    _nearbyDevices.clear();
    notifyListeners();

    try {
      // TODO: 实现真实的持续扫描逻辑
      // 真实场景：启动 WiFi Direct 扫描，设备回调会持续更新 _nearbyDevices

      // Debug 模式：模拟持续发现设备
      if (kDebugMode) {
        // 立即显示第一批设备
        await Future.delayed(const Duration(milliseconds: 500));
        if (_status == SyncStatus.scanning) {
          _nearbyDevices = [
            NearByDevice(
              id: 'device_001',
              name: '张工的设备',
              type: 'android',
            ),
            NearByDevice(
              id: 'device_002',
              name: '李工的设备',
              type: 'android',
            ),
          ];
          debugPrint('✅ 发现 ${_nearbyDevices.length} 个设备');
          notifyListeners();
        }

        // 模拟 3 秒后发现新设备
        Future.delayed(const Duration(seconds: 3), () {
          if (_status == SyncStatus.scanning) {
            _nearbyDevices = [
              ..._nearbyDevices,
              NearByDevice(
                id: 'device_003',
                name: '王工的设备',
                type: 'ios',
              ),
            ];
            debugPrint('✅ 发现新设备，共 ${_nearbyDevices.length} 个设备');
            notifyListeners();
          }
        });

        // 模拟 6 秥后发现另一个新设备
        Future.delayed(const Duration(seconds: 6), () {
          if (_status == SyncStatus.scanning) {
            _nearbyDevices = [
              ..._nearbyDevices,
              NearByDevice(
                id: 'device_004',
                name: '赵工的设备',
                type: 'android',
              ),
            ];
            debugPrint('✅ 发现新设备，共 ${_nearbyDevices.length} 个设备');
            notifyListeners();
          }
        });
      }

      // 【关键】不设置 setStatus(idle)，保持持续扫描状态
      // 扫描会在以下情况停止：
      // 1. 用户点击设备 → connectToDevice() 会改变状态
      // 2. 用户点击取消 → stopScanning()
      // 3. 发生错误 → catch 块中处理

    } catch (e) {
      debugPrint('❌ 扫描设备失败: $e');
      _setError('扫描设备失败: $e');
      _setStatus(SyncStatus.failed);
      rethrow;
    }
  }

  /// 停止扫描
  void stopScanning() {
    debugPrint('⏹️ DataSyncViewModel: 停止扫描');
    _setStatus(SyncStatus.idle);
    _nearbyDevices.clear();
    notifyListeners();
  }

  /// 开启可被发现模式（等待连接）
  ///
  /// 其他设备扫描时可以看到此设备
  Future<void> startDiscoverable() async {
    debugPrint('📡 DataSyncViewModel: 开启可被发现模式...');

    _setStatus(SyncStatus.discoverable);
    _clearError();
    notifyListeners();

    try {
      // TODO: 实现真实的可被发现模式
      // 启动 WiFi Direct 服务或 mDNS 广播
      debugPrint('✅ 已进入可被发现模式');
    } catch (e) {
      debugPrint('❌ 开启可被发现模式失败: $e');
      _setError('开启失败: $e');
      _setStatus(SyncStatus.failed);
      notifyListeners();
    }
  }

  /// 停止可被发现模式
  void stopDiscoverable() {
    debugPrint('📡 DataSyncViewModel: 停止可被发现模式');
    _setStatus(SyncStatus.idle);
    notifyListeners();
  }

  /// 模拟接收连接请求（仅用于测试）
  ///
  /// 实际开发时，这个方法会被真实的 WiFi Direct 回调替代
  void simulateIncomingConnection() {
    if (_status != SyncStatus.discoverable) return;

    debugPrint('📲 DataSyncViewModel: 模拟收到连接请求');

    // 模拟一个请求连接的设备
    _pendingDevice = NearByDevice(
      id: 'device_incoming',
      name: '张工的设备',
      type: 'android',
    );

    _setStatus(SyncStatus.pendingApproval);
    notifyListeners();
  }

  /// 连接到指定设备
  ///
  /// [deviceId] 设备 ID
  Future<bool> connectToDevice(String deviceId) async {
    debugPrint('🔗 DataSyncViewModel: 请求连接到设备 $deviceId');

    _setStatus(SyncStatus.connecting);
    _clearError();
    _currentDeviceId = deviceId;
    notifyListeners();

    try {
      // TODO: 实现真实的连接逻辑
      // 1. 发送连接请求
      // 2. 等待对方接受（通过 simulateAcceptConnection 触发）
      // 3. 建立连接

      // Debug 模式下，不自动完成连接，等待手动触发
      // 在生产环境中，这里会等待真实的网络回调
      if (kDebugMode) {
        debugPrint('⏳ 等待对方接受连接（Debug模式：请点击"模拟对方接受连接"按钮）');
      }
      // 注意：不再自动设置连接成功，需要等待 simulateAcceptConnection 被调用
      return true;
    } catch (e) {
      debugPrint('❌ 连接设备失败: $e');
      _setError('连接失败: $e');
      _setStatus(SyncStatus.failed);
      _currentDeviceId = null;
      notifyListeners();
      return false;
    }
  }

  /// 模拟对方接受连接（仅用于 Debug 测试）
  ///
  /// 在扫描方点击设备后，等待方"接受"连接时调用
  /// 此方法模拟对方设备接受了连接请求
  void simulateAcceptConnection() {
    if (_status != SyncStatus.connecting) {
      debugPrint('⚠️ 当前不是连接中状态，无法模拟接受连接');
      return;
    }

    debugPrint('✅ 模拟对方接受了连接');
    _setStatus(SyncStatus.idle); // 连接成功，回到 idle 状态
    notifyListeners();
  }

  /// 接受连接请求（等待方调用）
  ///
  /// 当扫描方请求连接时，等待方调用此方法接受连接
  Future<void> acceptConnection(String deviceId) async {
    debugPrint('✅ DataSyncViewModel: 接受来自 $deviceId 的连接');

    _currentDeviceId = deviceId;
    _pendingDevice = null; // 清空待确认设备
    _setStatus(SyncStatus.idle); // 改为 idle，表示连接成功
    notifyListeners();

    // TODO: 发送接受连接的确认给扫描方
  }

  /// 拒绝连接请求
  void rejectConnection() {
    debugPrint('❌ DataSyncViewModel: 拒绝连接');
    _currentDeviceId = null;
    _setStatus(SyncStatus.discoverable); // 回到可被发现状态
    notifyListeners();
  }

  /// 断开当前连接
  void disconnect() {
    debugPrint('🔌 DataSyncViewModel: 断开连接');
    _currentDeviceId = null;
    _pendingDevice = null;
    _nearbyDevices.clear(); // 清空设备列表
    _resetSyncStats();
    _setStatus(SyncStatus.idle);
    notifyListeners();
  }

  /// 开始同步数据
  ///
  /// 流程：
  /// 1. 交换元数据（图纸编号、修改时间、文件哈希）
  /// 2. 对比差异，找出需要同步的文件
  /// 3. 增量传输（只传输对方没有的文件）
  /// 4. 验证完成
  Future<void> startSync() async {
    if (_currentDeviceId == null) {
      _setError('未连接到任何设备');
      return;
    }

    debugPrint('🔄 DataSyncViewModel: 开始同步数据...');

    _setStatus(SyncStatus.syncing);
    _clearError();
    _resetSyncStats();
    notifyListeners();

    try {
      // TODO: 实现真实的同步逻辑

      // 模拟文件列表
      _totalFiles = 23;
      _fileTransferItems = List.generate(_totalFiles, (index) {
        return FileTransferItem(
          name: '图纸-${(index + 1).toString().padLeft(3, '0')}.dwg',
          sizeBytes: 500000 + (index * 100000), // 0.5MB - 2.7MB
          status: index == 0 ? TransferStatus.transferring : TransferStatus.pending,
          progress: 0.0,
        );
      });
      notifyListeners();

      // 模拟同步进度和文件传输
      _transferSpeed = 2.3; // MB/s

      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 200));

        _syncProgress = i / 100;

        // 更新文件传输状态
        final currentFileIndex = (i * _totalFiles / 100).floor();
        for (int j = 0; j < _fileTransferItems.length; j++) {
          if (j < currentFileIndex) {
            _fileTransferItems[j] = _fileTransferItems[j].copyWith(
              status: TransferStatus.completed,
              progress: 1.0,
            );
            _syncedFiles++;
          } else if (j == currentFileIndex) {
            final progressInFile = (i * _totalFiles / 100) - currentFileIndex;
            _fileTransferItems[j] = _fileTransferItems[j].copyWith(
              status: TransferStatus.transferring,
              progress: progressInFile,
            );
          }
        }

        notifyListeners();
      }

      // 确保所有文件都标记为完成
      for (int j = 0; j < _fileTransferItems.length; j++) {
        _fileTransferItems[j] = _fileTransferItems[j].copyWith(
          status: TransferStatus.completed,
          progress: 1.0,
        );
      }
      _syncedFiles = _totalFiles;
      _syncProgress = 1.0;
      _transferSpeed = 0.0;

      // 添加到同步历史
      final device = _nearbyDevices.firstWhere(
        (d) => d.id == _currentDeviceId,
        orElse: () => NearByDevice(id: 'unknown', name: '未知设备', type: 'android'),
      );
      _syncHistory.insert(0, SyncHistory(
        deviceName: device.name,
        time: DateTime.now(),
        fileCount: _totalFiles,
        totalBytes: _fileTransferItems.fold(0, (sum, item) => sum + item.sizeBytes),
        isSuccess: true,
      ));

      _setStatus(SyncStatus.completed);

      debugPrint('✅ 同步完成！');
      debugPrint('  总文件数: $_totalFiles');
      debugPrint('  成功: $_syncedFiles');
      debugPrint('  失败: $_failedFiles');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ 同步失败: $e');
      _setError('同步失败: $e');
      _setStatus(SyncStatus.failed);
      _transferSpeed = 0.0;
      notifyListeners();
      rethrow;
    }
  }

  /// 取消同步
  void cancelSync() {
    debugPrint('⏹️ DataSyncViewModel: 取消同步');
    _setStatus(SyncStatus.idle);
    _resetSyncStats();
    notifyListeners();
  }

  // ===== 私有辅助方法 =====

  void _setStatus(SyncStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _resetSyncStats() {
    _syncProgress = 0.0;
    _totalFiles = 0;
    _syncedFiles = 0;
    _failedFiles = 0;
  }

  /// 加载设备名称
  Future<void> _loadDeviceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('device_name');
      if (savedName != null && savedName.isNotEmpty) {
        _deviceName = savedName;
        debugPrint('✅ 已加载设备名称: $_deviceName');
      } else {
        // 首次使用，生成默认名称
        _deviceName = _generateDefaultDeviceName();
        await prefs.setString('device_name', _deviceName);
        debugPrint('✅ 生成默认设备名称: $_deviceName');
      }
    } catch (e) {
      debugPrint('⚠️ 加载设备名称失败: $e，使用默认名称');
      _deviceName = _generateDefaultDeviceName();
    }
  }

  /// 生成默认设备名称
  String _generateDefaultDeviceName() {
    // 获取当前时间戳的后4位作为随机标识
    final randomSuffix = DateTime.now().millisecond % 10000;
    return '设备_$randomSuffix';
  }

  /// 更新设备名称
  Future<void> updateDeviceName(String newName) async {
    if (newName.trim().isEmpty) {
      debugPrint('⚠️ 设备名称不能为空');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_name', newName.trim());
      _deviceName = newName.trim();
      notifyListeners();
      debugPrint('✅ 设备名称已更新: $_deviceName');
    } catch (e) {
      debugPrint('❌ 更新设备名称失败: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ DataSyncViewModel: dispose');
    // TODO: 清理 WiFi Direct 资源
    super.dispose();
  }
}
