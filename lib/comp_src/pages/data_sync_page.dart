import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/data_sync_view_model.dart';

/// 数据同步页面 - WiFi Direct 点对点同步
///
/// 使用 MVVM 架构，业务逻辑在 DataSyncViewModel 中
///
/// 功能流程：
/// 1. 扫描附近设备
/// 2. 选择设备并连接
/// 3. 自动对比差异（查缺补漏）
/// 4. 增量同步数据
class DataSyncPage extends StatelessWidget {
  const DataSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataSyncViewModel(),
      child: const _DataSyncView(),
    );
  }
}

class _DataSyncView extends StatefulWidget {
  const _DataSyncView();

  @override
  State<_DataSyncView> createState() => _DataSyncViewState();
}

class _DataSyncViewState extends State<_DataSyncView> {
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 数据同步页面 initState');

    // 在第一帧渲染后异步初始化
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<DataSyncViewModel>();
      await viewModel.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildGridBackground(),
          SafeArea(
            child: Consumer<DataSyncViewModel>(
              builder: (context, viewModel, child) {
                // 使用 AnimatedSwitcher 实现平滑过渡
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  // 根据状态动态决定显示哪个 Widget
                  child: KeyedSubtree(
                    key: ValueKey(viewModel.status), // 关键：用状态作为Key触发动画
                    child: _buildBodyContent(viewModel),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 状态分发器
  Widget _buildBodyContent(DataSyncViewModel viewModel) {
    if (viewModel.isScanning) {
      return _buildScanningView(viewModel);
    } else if (viewModel.isDiscoverable) {
      return _buildDiscoverableView(viewModel);
    } else if (viewModel.isConnecting) {
      return _buildConnectingView(viewModel);
    } else if (viewModel.status == SyncStatus.pendingApproval) {
      return _buildApprovalView(viewModel);
    } else if (viewModel.currentDeviceId != null) {
      return _buildConnectedView(viewModel);
    } else if (viewModel.hasError) {
      return _buildErrorView(viewModel);
    }
    // 默认空闲状态
    return _buildIdleView(viewModel);
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = _isDarkMode;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_outlined),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('数据同步'),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(isDark: _isDarkMode),
    );
  }

  /// 空闲状态视图（优化后）
  Widget _buildIdleView(DataSyncViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 顶部图标
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sync_lock,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // 标题和说明
          Text(
            '数据同步',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '无需流量，局域网极速互传',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 48),

          // 两个大卡片入口
          _buildBigActionCard(
            icon: Icons.radar,
            title: '我要发送',
            subtitle: '扫描附近的设备',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => viewModel.startScanning(),
          ),
          const SizedBox(height: 16),
          _buildBigActionCard(
            icon: Icons.wifi_tethering,
            title: '我要接收',
            subtitle: '等待对方连接',
            color: const Color(0xFF10B981),
            onTap: () => viewModel.startDiscoverable(),
          ),
        ],
      ),
    );
  }

  // 更现代的大卡片样式
  Widget _buildBigActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: _isDarkMode ? 2 : 4,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 扫描中视图
  Widget _buildScanningView(DataSyncViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            '正在扫描附近设备...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请确保两台设备都开启了 WiFi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 32),

          // 取消按钮
          OutlinedButton(
            onPressed: () => viewModel.stopScanning(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('取消扫描'),
          ),

          // 显示找到的设备（如果有）
          if (viewModel.nearbyDevices.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildDeviceList(viewModel),
          ],
        ],
      ),
    );
  }

  /// 等待连接视图（可被发现模式）- 优化后
  Widget _buildDiscoverableView(DataSyncViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // 使用雷达组件
          RadarWaves(color: const Color(0xFF10B981)),
          const SizedBox(height: 32),

          Text(
            '等待连接...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          Text(
            '请让对方设备点击"我要发送"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '本机名称: 我的设备',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),

          // 停止按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => viewModel.stopDiscoverable(),
              icon: const Icon(Icons.close, size: 20),
              label: const Text('取消等待'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 测试按钮（仅 debug 模式）
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => viewModel.simulateIncomingConnection(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('🔧 模拟收到连接请求'),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 连接中视图（等待对方确认）
  Widget _buildConnectingView(DataSyncViewModel viewModel) {
    final device = viewModel.nearbyDevices.firstWhere(
      (d) => d.id == viewModel.currentDeviceId,
      orElse: () => NearByDevice(
        id: 'unknown',
        name: '未知设备',
        type: 'android',
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),

          Text(
            '正在连接...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    device.type == 'android' ? Icons.android : Icons.phone_iphone,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '等待对方确认连接',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            '请在对方设备上确认此连接',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
          ),
          const SizedBox(height: 20),

          OutlinedButton(
            onPressed: () => viewModel.disconnect(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 接受连接视图（有人请求连接）
  Widget _buildApprovalView(DataSyncViewModel viewModel) {
    final device = viewModel.pendingDevice;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add,
              color: Color(0xFFF59E0B),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            '连接请求',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          if (device != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          device.type == 'android' ? Icons.android : Icons.phone_iphone,
                          color: const Color(0xFFF59E0B),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '请求与您同步数据',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => viewModel.rejectConnection(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('拒绝'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (device != null) {
                      viewModel.acceptConnection(device.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('接受'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 已连接视图 - 优化后（使用环形进度条）
  Widget _buildConnectedView(DataSyncViewModel viewModel) {
    final device = viewModel.nearbyDevices.firstWhere(
      (d) => d.id == viewModel.currentDeviceId,
      orElse: () => NearByDevice(
        id: 'unknown',
        name: '未知设备',
        type: 'android',
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 顶部连接对象卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '已连接: ${device.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 核心区域：巨大的进度展示
          if (viewModel.isSyncing) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: viewModel.syncProgress,
                    strokeWidth: 12,
                    backgroundColor: _isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(viewModel.syncProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${viewModel.syncedFiles} / ${viewModel.totalFiles}',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              '正在同步数据...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ] else if (viewModel.status == SyncStatus.completed) ...[
            // 完成状态
            const Icon(
              Icons.task_alt,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              '同步完成',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '共传输 ${viewModel.syncedFiles} 个文件',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ] else ...[
            // 准备就绪状态
            Icon(
              Icons.swap_horiz,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '连接成功',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '准备开始同步',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => viewModel.startSync(),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('开始同步'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          const Spacer(),

          // 底部断开按钮
          TextButton.icon(
            onPressed: () => viewModel.disconnect(),
            icon: const Icon(Icons.link_off),
            label: const Text('断开连接'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 设备列表
  Widget _buildDeviceList(DataSyncViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '找到 ${viewModel.nearbyDevices.length} 个设备',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...viewModel.nearbyDevices.map((device) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDeviceCard(device, viewModel),
          );
        }),
      ],
    );
  }

  /// 单个设备卡片
  Widget _buildDeviceCard(NearByDevice device, DataSyncViewModel viewModel) {
    final isConnecting = viewModel.isConnecting &&
        viewModel.currentDeviceId == device.id;

    return InkWell(
      onTap: isConnecting
          ? null
          : () => viewModel.connectToDevice(device.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDarkMode
                ? const Color(0xFF94A3B8)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                device.type == 'android'
                    ? Icons.android
                    : Icons.phone_iphone,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.type.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: _isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFFCBD5E1),
              ),
          ],
        ),
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(DataSyncViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '出错了',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            viewModel.errorMessage ?? '未知错误',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () {
              viewModel.disconnect();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

/// 网格背景绘制器
class _GridPainter extends CustomPainter {
  final bool isDark;

  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF64748B).withValues(alpha: 0.25)
          : const Color(0xFF94A3B8).withValues(alpha: 0.25)
      ..strokeWidth = 1;

    const gridSize = 32.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 雷达波纹动画组件
class RadarWaves extends StatefulWidget {
  final Color color;
  const RadarWaves({super.key, required this.color});

  @override
  State<RadarWaves> createState() => _RadarWavesState();
}

class _RadarWavesState extends State<RadarWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: 160,
      child: CustomPaint(
        painter: _RadarPainter(_controller.value, color: widget.color),
        child: Center(
          child: Icon(
            Icons.wifi_tethering,
            size: 48,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// 雷达波纹绘制器
class _RadarPainter extends CustomPainter {
  final double value;
  final Color color;

  _RadarPainter(this.value, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - value) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 画三个扩散圈
    for (int i = 0; i < 3; i++) {
      final currentVal = (value + i / 3) % 1.0;
      canvas.drawCircle(center, maxRadius * currentVal, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
