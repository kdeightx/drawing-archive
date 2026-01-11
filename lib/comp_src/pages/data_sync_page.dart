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

  // 设备名称编辑控制器
  final TextEditingController _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 数据同步页面 initState');

    // 在第一帧渲染后异步初始化
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<DataSyncViewModel>();
      await viewModel.init();

      // 初始化设备名称输入框
      _deviceNameController.text = viewModel.deviceName;
    });
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildGridBackground(),
          // 使用 Positioned.fill 强制内容层撑满全屏
          Positioned.fill(
            child: SafeArea(
              child: Consumer<DataSyncViewModel>(
                builder: (context, viewModel, child) {
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
                    child: KeyedSubtree(
                      key: ValueKey(viewModel.status),
                      child: _buildBodyContent(viewModel),
                    ),
                  );
                },
              ),
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
    final isDark = _isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 标题和说明
          Text(
            '数据同步',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '无需流量，局域网极速互传',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 24),

          // 设备名称编辑卡片
          _buildDeviceNameCard(viewModel, isDark),
          const SizedBox(height: 16),

          // 两个大卡片入口
          Row(
            children: [
              Expanded(
                child: _buildBigActionCard(
                  icon: Icons.radar,
                  title: '我要发送',
                  subtitle: '扫描附近的设备',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => viewModel.startScanning(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBigActionCard(
                  icon: Icons.wifi_tethering,
                  title: '我要接收',
                  subtitle: '等待对方连接',
                  color: const Color(0xFF10B981),
                  onTap: () => viewModel.startDiscoverable(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 同步历史卡片
          _buildSyncHistoryCard(viewModel, isDark),
        ],
      ),
    );
  }

  /// 设备名称编辑卡片
  Widget _buildDeviceNameCard(DataSyncViewModel viewModel, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF10B981).withValues(alpha: 0.08),
                  const Color(0xFF10B981).withValues(alpha: 0.02),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF0FDF4),
                ],
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFF10B981).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smartphone_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '设备名称',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 输入框和保存按钮
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deviceNameController,
                    decoration: InputDecoration(
                      hintText: '输入设备名称',
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLength: 20,
                    buildCounter: (
                      BuildContext context, {
                      required int currentLength,
                      required int? maxLength,
                      required bool isFocused,
                    }) {
                      return null; // 隐藏字符计数器
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // 保存按钮
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final newName = _deviceNameController.text.trim();
                      if (newName.isNotEmpty) {
                        await viewModel.updateDeviceName(newName);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ 设备名称已更新'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ 设备名称不能为空'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    splashColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    highlightColor: const Color(0xFF10B981).withValues(alpha: 0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '保存',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 提示文字
            const SizedBox(height: 10),
            Text(
              '其他设备将通过此名称识别你的设备',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 大卡片样式（两列布局使用）- 重新设计版本
  Widget _buildBigActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ]
              : [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ],
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.4 : 0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 优化后的图标容器 - 渐变背景 + 光晕效果
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.25),
                        color.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 12,
                        letterSpacing: 0.1,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 同步历史卡片 - 重新设计版本
  Widget _buildSyncHistoryCard(DataSyncViewModel viewModel, bool isDark) {
    if (viewModel.syncHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  primaryColor.withValues(alpha: 0.08),
                  primaryColor.withValues(alpha: 0.02),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF8FAFC),
                ],
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: isDark
              ? const Color(0xFF94A3B8).withValues(alpha: 0.3)
              : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 优化后的标题行 - 添加背景和分隔线
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isDark
                    ? [
                        primaryColor.withValues(alpha: 0.12),
                        primaryColor.withValues(alpha: 0.04),
                      ]
                    : [
                        const Color(0xFFF1F5F9),
                        const Color(0xFFF8FAFC),
                      ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '同步历史',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: 查看全部历史
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '查看全部',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 优化后的分隔线
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isDark
                    ? [
                        Colors.transparent,
                        const Color(0xFF475569).withValues(alpha: 0.5),
                        Colors.transparent,
                      ]
                    : [
                        Colors.transparent,
                        const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
          // 历史记录列表
          ...viewModel.syncHistory.take(3).map((history) {
            return _buildHistoryItem(history, isDark);
          }),
        ],
      ),
    );
  }

  /// 单条历史记录 - 重新设计版本
  Widget _buildHistoryItem(SyncHistory history, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final statusColor = history.isSuccess
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final statusIcon = history.isSuccess
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: 显示历史详情
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: primaryColor.withValues(alpha: 0.08),
        highlightColor: primaryColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // 添加悬停边框效果
            border: Border(
              left: BorderSide(
                color: statusColor.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // 优化后的设备图标容器
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF475569),
                            const Color(0xFF334155),
                          ]
                        : [
                            const Color(0xFFF1F5F9),
                            const Color(0xFFE2E8F0),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Icon(
                Icons.smartphone_rounded,
                size: 22,
                color: const Color(0xFF64748B),
              ),
            ),
              const SizedBox(width: 14),
              // 设备名称和信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.deviceName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${history.timeText} · ${history.fileCount} 个文件 · ${history.sizeText}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              // 优化后的状态图标 - 带背景容器
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  size: 20,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 扫描中视图
  Widget _buildScanningView(DataSyncViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              '本机名称: ${viewModel.deviceName}',
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

          // 测试按钮（仅 debug 模式）
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => viewModel.simulateAcceptConnection(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('🔧 模拟对方接受连接'),
            ),
          ],
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

  /// 已连接视图 - 优化后（使用环形进度条 + 文件列表）
  Widget _buildConnectedView(DataSyncViewModel viewModel) {
    final device = viewModel.nearbyDevices.firstWhere(
      (d) => d.id == viewModel.currentDeviceId,
      orElse: () => NearByDevice(
        id: 'unknown',
        name: '未知设备',
        type: 'android',
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 顶部连接对象卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '已连接: ${device.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 核心区域：进度展示
          if (viewModel.isSyncing) ...[
            // 环形进度条
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: viewModel.syncProgress,
                    strokeWidth: 10,
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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${viewModel.syncedFiles}/${viewModel.totalFiles}',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 速度和剩余时间卡片
            if (viewModel.transferSpeed > 0)
              _buildSpeedIndicator(viewModel),
            const SizedBox(height: 16),

            // 文件传输列表
            _buildFileTransferList(viewModel),
          ] else if (viewModel.status == SyncStatus.completed) ...[
            // 完成状态
            const Icon(
              Icons.task_alt,
              size: 80,
              color: Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
            Text(
              '同步完成',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '共传输 ${viewModel.syncedFiles} 个文件',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ] else ...[
            // 准备就绪状态
            Icon(
              Icons.swap_horiz,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '连接成功',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
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

          const SizedBox(height: 20),

          // 底部断开按钮
          OutlinedButton.icon(
            onPressed: () => viewModel.disconnect(),
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text('断开连接'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 传输速度指示器
  Widget _buildSpeedIndicator(DataSyncViewModel viewModel) {
    final isDark = _isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSpeedItem(
            icon: Icons.speed,
            label: '传输速度',
            value: '${viewModel.transferSpeed.toStringAsFixed(1)} MB/s',
          ),
          Container(
            width: 1,
            height: 24,
            color: isDark
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0),
          ),
          _buildSpeedItem(
            icon: Icons.access_time,
            label: '剩余时间',
            value: _formatDuration(viewModel.remainingSeconds),
          ),
        ],
      ),
    );
  }

  /// 速度信息单项
  Widget _buildSpeedItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    if (seconds < 3600) return '${(seconds / 60).toInt()} 分钟';
    return '${(seconds / 3600).toInt()} 小时';
  }

  /// 文件传输列表
  Widget _buildFileTransferList(DataSyncViewModel viewModel) {
    final isDark = _isDarkMode;

    return Card(
      margin: EdgeInsets.zero,
      elevation: isDark ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
          width: isDark ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '文件传输列表',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),
          ),
          // 显示前 5 个文件
          ...viewModel.fileTransferItems.take(5).map((item) {
            return _buildFileTransferItem(item, isDark);
          }),
          // 文件数量提示
          if (viewModel.fileTransferItems.length > 5)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '还有 ${viewModel.fileTransferItems.length - 5} 个文件...',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 单个文件传输状态
  Widget _buildFileTransferItem(FileTransferItem item, bool isDark) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (item.status) {
      case TransferStatus.pending:
        statusIcon = Icons.schedule;
        statusColor = const Color(0xFF64748B);
        statusText = '等待中';
        break;
      case TransferStatus.transferring:
        statusIcon = Icons.downloading;
        statusColor = Theme.of(context).colorScheme.primary;
        statusText = '${(item.progress * 100).toInt()}%';
        break;
      case TransferStatus.completed:
        statusIcon = Icons.check_circle;
        statusColor = const Color(0xFF10B981);
        statusText = '已完成';
        break;
      case TransferStatus.failed:
        statusIcon = Icons.error_outline;
        statusColor = const Color(0xFFEF4444);
        statusText = '失败';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 文件图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.insert_drive_file,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          // 文件信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.sizeText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // 传输进度条（仅在传输中时显示）
          if (item.status == TransferStatus.transferring)
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            )
          else
            Icon(statusIcon, size: 20, color: statusColor),
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
