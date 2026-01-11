import 'package:flutter/foundation.dart';

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
    debugPrint('✅ DataSyncViewModel: 初始化完成');
  }

  /// 开始扫描附近设备
  ///
  /// 使用 WiFi Direct 或 mDNS 扫描附近安装了本应用的设备
  Future<void> startScanning() async {
    debugPrint('🔍 DataSyncViewModel: 开始扫描设备...');

    _setStatus(SyncStatus.scanning);
    _clearError();

    try {
      // TODO: 实现真实的设备扫描逻辑
      // 模拟扫描延迟
      await Future.delayed(const Duration(seconds: 2));

      // 模拟找到的设备（实际开发时删除）
      if (kDebugMode) {
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
        debugPrint('✅ 找到 ${_nearbyDevices.length} 个设备');
      }

      _setStatus(SyncStatus.idle);
      notifyListeners();
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
      // 2. 等待对方接受
      // 3. 建立连接

      // 模拟连接延迟（包含等待对方确认的时间）
      await Future.delayed(const Duration(seconds: 3));

      // TODO: 这里应该等待对方接受连接的确认
      // 模拟对方接受了连接
      debugPrint('✅ 对方接受了连接，连接成功');
      _setStatus(SyncStatus.idle); // 改为 idle，表示已连接
      notifyListeners();
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
      // 模拟同步进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        _syncProgress = i / 100;
        _syncedFiles = (i * 0.5).round();
        notifyListeners();
      }

      _totalFiles = _syncedFiles;
      _syncProgress = 1.0;
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

  @override
  void dispose() {
    debugPrint('🗑️ DataSyncViewModel: dispose');
    // TODO: 清理 WiFi Direct 资源
    super.dispose();
  }
}
