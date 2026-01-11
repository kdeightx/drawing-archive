import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../services/drawing_service.dart';
import '../view_models/drawing_scanner_view_model.dart';
import '../widgets/action_card.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/image_display_card.dart';
import '../widgets/smart_process_stepper.dart';
import 'drawing_search_page.dart';
import 'drawing_settings_page.dart';

/// 图纸扫描入库页面 - View 层（纯 UI）
///
/// 使用 MVVM 架构，业务逻辑在 DrawingScannerViewModel 中
class DrawingScannerPage extends StatelessWidget {
  final DrawingService drawingService;

  const DrawingScannerPage({super.key, required this.drawingService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DrawingScannerViewModel(drawingService: drawingService),
      child: const _DrawingScannerView(),
    );
  }
}

class _DrawingScannerView extends StatefulWidget {
  const _DrawingScannerView();

  @override
  State<_DrawingScannerView> createState() => _DrawingScannerViewState();
}

class _DrawingScannerViewState extends State<_DrawingScannerView> {
  /// ScrollController 用于页面滚动
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, l10n),
      body: Stack(
        children: [
          _buildGridBackground(context),
          SafeArea(
            child: Consumer<DrawingScannerViewModel>(
              builder: (context, viewModel, child) {
                // 监听导航状态，执行图片预览导航
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

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, l10n, viewModel),
                      const SizedBox(height: 20),
                      _buildImageCard(context, viewModel),
                      const SizedBox(height: 16),
                      _buildActionCard(context, viewModel, l10n),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(l10n.scanTitle),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DrawingSettingsPage(),
              ),
            );
          },
          tooltip: l10n.settingsTitle,
        ),
      ],
    );
  }

  /// 构建网格背景
  Widget _buildGridBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(isDark: isDark),
    );
  }

  /// 构建页面头部（进度卡片）
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    DrawingScannerViewModel viewModel,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIdle = viewModel.progressState == null;

    // 计算当前步骤和进度
    int currentStep = -1;
    double progress = 0.0;

    switch (viewModel.progressState) {
      case ProgressState.sending:
        currentStep = 0;
        progress = 0.33;
        break;
      case ProgressState.scanning:
        currentStep = 1;
        progress = 0.66;
        break;
      case ProgressState.completed:
        currentStep = 2;
        progress = 1.0;
        break;
      case null:
        break;
    }

    // 状态颜色
    final baseBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    // 各阶段状态球颜色
    final sendingColor = const Color(0xFF3B82F6); // 蓝色 - 发送中
    final scanningColor = const Color(0xFFF59E0B); // 橙色 - AI扫描中
    final completedColor = const Color(0xFF10B981); // 绿色 - 已完成

    // 构建步骤数据
    final steps = [
      StepData(
        label: '发送中',
        isActive: currentStep == 0 && !isIdle,
        isCompleted: currentStep > 0,
        color: sendingColor,
      ),
      StepData(
        label: 'AI扫描中',
        isActive: currentStep == 1 && !isIdle,
        isCompleted: currentStep > 1,
        color: scanningColor,
      ),
      StepData(
        label: '已完成',
        isActive: currentStep == 2 && !isIdle,
        isCompleted: currentStep >= 2,
        color: completedColor,
      ),
    ];

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：状态文字 + 百分比
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧：状态文字
                Text(
                  isIdle
                      ? '就绪'
                      : (currentStep == 0
                            ? '发送中'
                            : (currentStep == 1 ? 'AI扫描中' : '已完成')),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                // 右侧：百分比
                Text(
                  isIdle ? '0%' : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 进度指示器
            SmartProcessStepper(
              steps: steps,
              activeColor: baseBlue,
              backgroundColor: bgColor,
              isDark: isDark,
              pulseController: null, // ViewModel 不需要动画控制器
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片卡片
  Widget _buildImageCard(
    BuildContext context,
    DrawingScannerViewModel viewModel,
  ) {
    return ImageDisplayCard(
      images: viewModel.selectedImages,
      currentIndex: viewModel.currentImageIndex,
      onIndexChange: (index) {
        viewModel.setCurrentImageIndex(index);
      },
      onImageTap: (index) {
        viewModel.onImageTapped(index);
      },
    );
  }

  /// 构建操作卡片
  Widget _buildActionCard(
    BuildContext context,
    DrawingScannerViewModel viewModel,
    AppLocalizations l10n,
  ) {
    // 构建 NumberItem 列表
    final numberItems = List.generate(viewModel.selectedImages.length, (index) {
      return NumberItem(
        id: 'img_$index',
        image: viewModel.selectedImages[index],
        index: index,
        number: viewModel.numberControllers[index].text,
        hasAiNumber: viewModel.recognizedNumbers[index].isNotEmpty,
        recognitionFailed: viewModel.recognitionFailedList[index], // 使用识别失败状态
      );
    });

    return ActionCard(
      onCameraTap: () => viewModel.pickImage(),
      onGalleryTap: () async {
        try {
          await viewModel.pickMultipleImages();
        } catch (e) {
          if (!context.mounted) return;
          _showSnackBar(context, '${l10n.pickImageFailed}: $e', isError: true);
        }
      },
      onSearchTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DrawingSearchPage(drawingService: viewModel.drawingService),
          ),
        );
      },
      numberItems: numberItems,
      currentPage: viewModel.numberPage,
      totalPages: viewModel.totalPages,
      numberControllers:
          viewModel.numberControllers, // 传入 ViewModel 管理的 controllers
      itemsPerPage: viewModel.numbersPerPage,
      onNumberChange: (index) {
        // 编号变化时更新控制器
        final newValue = numberItems[index].number;
        final controller = viewModel.numberControllers[index];

        // 只有当值真的不同时才更新，避免光标跳动等问题
        if (controller.text != newValue) {
          controller.text = newValue;
        }
      },
      onDeleteTap: (index) async {
        await viewModel.deleteImage(index);
      },
      onPreviousPage: viewModel.numberPage > 0
          ? () => viewModel.previousPage()
          : null,
      onNextPage: viewModel.numberPage < viewModel.totalPages - 1
          ? () => viewModel.nextPage()
          : null,
      onUpload: () async {
        try {
          await viewModel.uploadAndRecognizeAll();
        } catch (e) {
          if (!context.mounted) return;

          // 检查是否是 AI API 连接失败
          String errorMsg = '$e';
          if (errorMsg.contains('AI API 连接失败')) {
            _showSnackBar(
              context,
              '${l10n.pickImageFailed}: $errorMsg\n\n💡 您可以手动编辑编号并保存图片',
              isError: true,
              duration: const Duration(seconds: 5),
            );
          } else {
            _showSnackBar(context, '上传识别失败: $e', isError: true);
          }
        }
      },
      onSave: () async {
        try {
          // [修复核心] 强制移除焦点，确保输入框中的内容同步到 Controller
          FocusScope.of(context).unfocus();

          // 等待一小段时间让事件循环处理文本更新
          await Future.delayed(const Duration(milliseconds: 50));

          final count = await viewModel.saveAllImages();
          if (!context.mounted) return;

          _showSnackBar(
            context,
            l10n.saveSuccess(count),
            isError: false,
            isSuccess: true,
          );
        } catch (e) {
          if (!context.mounted) return;
          _showSnackBar(context, '${l10n.saveFailed}: $e', isError: true);
        }
      },
      onClearAll: () async {
        // 显示确认对话框
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Card(
                margin: EdgeInsets.zero,
                elevation: isDark ? 2 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFFCBD5E1),
                    width: isDark ? 2.0 : 1.5,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 图标
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFEF4444),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 标题
                      const Text(
                        '确认清空列表',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 按钮组
                      Row(
                        children: [
                          // 确认清空按钮
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      '确认清空',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 取消按钮
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '取消',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        // 用户点击了"确认清空"
        if (confirmed == true) {
          try {
            await viewModel.clearAllImages();
          } catch (e) {
            if (!context.mounted) return;
            _showSnackBar(context, '清空失败: $e', isError: true);
          }
        }
      },
      isSaving: viewModel.isSaving,
      isAnalyzing: viewModel.isAnalyzing,
    );
  }

  /// 显示顶部通知
  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    // 根据类型确定颜色和图标
    Color backgroundColor;
    IconData icon;

    if (isError) {
      backgroundColor = Theme.of(context).colorScheme.error;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = const Color(0xFF10B981); // 绿色
      icon = Icons.check_circle;
    } else {
      backgroundColor = Theme.of(context).colorScheme.primary;
      icon = Icons.check_circle;
    }

    // 使用 Overlay 显示顶部通知（避免与 Scaffold SnackBar 系统冲突）
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        // 计算 AppBar 高度 + 顶部安全区域
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        final double topPadding = mediaQuery.padding.top;
        final double appBarHeight = kToolbarHeight;

        return Positioned(
          top: topPadding + appBarHeight + 8,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _TopNotification(
              message: message,
              backgroundColor: backgroundColor,
              icon: icon,
              onDismiss: () => overlayEntry.remove(),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    // 指定时间后自动移除
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/// 顶部通知卡片组件
class _TopNotification extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: null, // 允许多行显示
                  overflow: TextOverflow.visible, // 不截断文本
                ),
              ),
            ],
          ),
        ),
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
