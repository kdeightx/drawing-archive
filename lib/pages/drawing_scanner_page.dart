import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/drawing_service.dart';
import 'drawing_search_page.dart';
import 'drawing_settings_page.dart';

/// 进度状态
enum ProgressState {
  sending,    // 发送数据中
  scanning,   // AI扫描中
  completed,  // 扫描完成
}

/// 图纸扫描入库页面 - 精密工业风格
class DrawingScannerPage extends StatefulWidget {
  final DrawingService drawingService;

  const DrawingScannerPage({
    super.key,
    required this.drawingService,
  });

  @override
  State<DrawingScannerPage> createState() => _DrawingScannerPageState();
}

class _DrawingScannerPageState extends State<DrawingScannerPage>
    with TickerProviderStateMixin {
  /// 选中的图片列表（支持多选）
  List<File> _selectedImages = [];
  /// 当前查看的图片索引
  int _currentImageIndex = 0;
  /// 每张图片对应的编号列表
  List<String> _recognizedNumbers = [];
  /// 每张图片的编号输入控制器
  List<TextEditingController> _numberControllers = [];
  /// 编号列表当前页码
  int _numberPage = 0;
  /// 每页显示的编号数量
  static const int _numbersPerPage = 5;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  /// 进度状态
  ProgressState? _progressState;
  final TransformationController _transformationController = TransformationController();
  final PageController _pageController = PageController();

  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    // 清理所有编号输入控制器
    for (var controller in _numberControllers) {
      controller.dispose();
    }
    _transformationController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  /// 处理单选图片（相机）
  Future<void> _handlePickImage(ImageSource source) async {
    if (source != ImageSource.camera) {
      // 相册使用多选
      await _handlePickMultipleImages();
      return;
    }

    try {
      final File? image = await widget.drawingService.pickImage(source);
      if (image == null) return;

      setState(() {
        _selectedImages = [image];
        _currentImageIndex = 0;
        _recognizedNumbers = [''];
        _numberControllers = [TextEditingController()];
        _numberPage = 0;
        _transformationController.value = Matrix4.identity();
      });

      await _handleAnalyzeImage();
    } catch (e) {
      if (mounted) {
        _showSnackBar('${AppLocalizations.of(context)!.pickImageFailed}: $e', isError: true);
      }
    }
  }

  /// 处理多选图片（相册）
  Future<void> _handlePickMultipleImages() async {
    try {
      final List<File> images = await widget.drawingService.pickMultipleImages();
      if (images.isEmpty) return;

      // 弹出确认对话框
      if (!mounted) return;
      final confirmed = await _showConfirmDialog(images.length);

      if (confirmed) {
        // 初始化编号列表和控制器
        final List<String> numbers = List.filled(images.length, '');
        final List<TextEditingController> controllers =
            List.generate(images.length, (index) => TextEditingController());

        setState(() {
          _selectedImages = images;
          _currentImageIndex = 0;
          _recognizedNumbers = numbers;
          _numberControllers = controllers;
          _numberPage = 0;
          _transformationController.value = Matrix4.identity();
        });

        // 批量分析所有图片
        await _handleAnalyzeAllImages();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${AppLocalizations.of(context)!.pickImageFailed}: $e', isError: true);
      }
    }
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(int imageCount) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConfirmImageDialog(imageCount: imageCount),
    ) ?? false;
  }

  Future<void> _handleAnalyzeImage() async {
    if (_selectedImages.isEmpty) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.selectImageFirst, isError: true);
      }
      return;
    }

    // 显示进度：发送数据
    setState(() => _progressState = ProgressState.sending);
    await Future.delayed(const Duration(milliseconds: 500));

    // 显示进度：AI扫描中
    if (!mounted) return;
    setState(() => _progressState = ProgressState.scanning);

    try {
      final File currentImage = _selectedImages[_currentImageIndex];
      final String number = await widget.drawingService.analyzeImage(currentImage);

      if (!mounted) return;

      // 显示进度：完成
      setState(() {
        _progressState = ProgressState.completed;
        _recognizedNumbers[_currentImageIndex] = number;
        _numberControllers[_currentImageIndex].text = number;
      });

      // 延迟后隐藏进度（显示完成状态3秒）
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _progressState = null);
      }

      _showSnackBar(AppLocalizations.of(context)!.saved, isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _progressState = null);
      _showSnackBar('${AppLocalizations.of(context)!.recognizeFailed}: $e', isError: true);
    }
  }

  /// 批量分析所有图片
  Future<void> _handleAnalyzeAllImages() async {
    if (_selectedImages.isEmpty) return;

    // 显示进度：发送数据
    setState(() => _progressState = ProgressState.sending);
    await Future.delayed(const Duration(milliseconds: 500));

    // 显示进度：AI扫描中
    if (!mounted) return;
    setState(() => _progressState = ProgressState.scanning);

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        if (!mounted) return;

        final String number = await widget.drawingService.analyzeImage(_selectedImages[i]);

        if (mounted) {
          setState(() {
            _recognizedNumbers[i] = number;
            _numberControllers[i].text = number;
          });
        }
      }

      // 显示进度：完成
      if (!mounted) return;
      setState(() => _progressState = ProgressState.completed);

      // 延迟后隐藏进度（显示完成状态3秒）
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _progressState = null);
      }

      _showSnackBar('已完成 ${_selectedImages.length} 张图片的识别', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _progressState = null);
      _showSnackBar('${AppLocalizations.of(context)!.recognizeFailed}: $e', isError: true);
    }
  }

  Future<void> _handleSave() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.selectImageFirst, isError: true);
      return;
    }

    // 检查所有编号是否都已填写
    for (int i = 0; i < _numberControllers.length; i++) {
      if (_numberControllers[i].text.trim().isEmpty) {
        _showSnackBar('请填写第 ${i + 1} 张图片的编号', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // 批量保存所有图片
      int successCount = 0;
      for (int i = 0; i < _selectedImages.length; i++) {
        final number = _numberControllers[i].text.trim();
        await widget.drawingService.saveEntry(_selectedImages[i], number);
        successCount++;
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('已保存 $successCount 张图片'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        _resetPage();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('${AppLocalizations.of(context)!.saveFailed}: $e', isError: true);
    }
  }

  void _resetPage() {
    // 清理所有控制器
    for (var controller in _numberControllers) {
      controller.dispose();
    }
    setState(() {
      _selectedImages = [];
      _currentImageIndex = 0;
      _recognizedNumbers = [];
      _numberControllers = [];
      _numberPage = 0;
      _transformationController.value = Matrix4.identity();
      _isAnalyzing = false;
      _isSaving = false;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(l10n),
      body: Stack(
        children: [
          _buildGridBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(l10n),
                  const SizedBox(height: 20),
                  _buildImageCard(l10n),
                  const SizedBox(height: 16),
                  _buildActionCard(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(l10n.scanTitle),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DrawingSettingsPage()),
            );
          },
          tooltip: l10n.settingsTitle,
        ),
      ],
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIdle = _progressState == null;

    // 根据进度状态确定颜色和进度
    Color statusColor = const Color(0xFF94A3B8);
    int currentStep = -1;
    double progress = 0.0;

    switch (_progressState) {
      case ProgressState.sending:
        statusColor = const Color(0xFF3B82F6);
        currentStep = 0;
        progress = 0.33;
        break;
      case ProgressState.scanning:
        statusColor = const Color(0xFFF59E0B);
        currentStep = 1;
        progress = 0.66;
        break;
      case ProgressState.completed:
        statusColor = const Color(0xFF10B981);
        currentStep = 2;
        progress = 1.0;
        break;
      case null:
        break;
    }

    // 空闲状态颜色 - 中性银灰色
    final idleColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final currentColor = isIdle ? idleColor : statusColor;

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: currentColor.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
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
                  isIdle ? '就绪' : (currentStep == 0 ? '发送中' : (currentStep == 1 ? 'AI扫描中' : '已完成')),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: currentColor.withValues(alpha: 0.8),
                  ),
                ),

                // 右侧：百分比（使用相同字体风格）
                Text(
                  isIdle ? '0%' : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: currentColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // 8 → 12，给状态文字留空间

            // 全新设计：三节点链式进度指示器（带标签）
            _buildProgressIndicatorWithLabels(currentStep, currentColor, isIdle, isDark),
          ],
        ),
      ),
    );
  }

  /// 全新设计：三节点链式进度指示器（带标签）
  Widget _buildProgressIndicatorWithLabels(int currentStep, Color color, bool isIdle, bool isDark) {
    // 计算连接线进度：空闲0，发送中到第1个节点(33%)，扫描中到第2个节点(67%)，完成(100%)
    final lineProgress = isIdle ? 0.0 : ((currentStep + 1) / 3);

    return Column(
      children: [
        // 进度指示器（圆球 + 连接线）
        SizedBox(
          height: 32,
          child: Stack(
            children: [
              // 连接线（背景）
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: CustomPaint(
                  size: const Size(double.infinity, 3),
                  painter: _ConnectorLinePainter(
                    color: isIdle
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                        : color.withValues(alpha: 0.3),
                    progress: 0.0, // 背景线总是满的
                  ),
                ),
              ),

              // 连接线（进度填充，带动画）
              if (!isIdle)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: lineProgress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 3),
                        painter: _ConnectorLinePainter(
                          color: color,
                          progress: value,
                        ),
                      );
                    },
                  ),
                ),

              // 三个圆球节点
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressNode(0, currentStep, color, isIdle, isDark),
                    _buildProgressNode(1, currentStep, color, isIdle, isDark),
                    _buildProgressNode(2, currentStep, color, isIdle, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 阶段标签（精确对齐到圆球）
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 56, // 增加到56px，确保"AI扫描中"一行显示
              child: Center(child: _buildStageLabel('发送中', 0, currentStep, color, isIdle)),
            ),
            SizedBox(
              width: 56,
              child: Center(child: _buildStageLabel('AI扫描中', 1, currentStep, color, isIdle)),
            ),
            SizedBox(
              width: 56,
              child: Center(child: _buildStageLabel('已完成', 2, currentStep, color, isIdle)),
            ),
          ],
        ),
      ],
    );
  }

  /// 进度节点（圆球）
  Widget _buildProgressNode(int step, int currentStep, Color color, bool isIdle, bool isDark) {
    final isCompleted = !isIdle && step < currentStep;
    final isActive = !isIdle && step == currentStep;

    return SizedBox(
      width: 36, // 40 → 36
      height: 32, // 36 → 32
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 28 : (isCompleted ? 22 : 16), // 32/26/20 → 28/22/16
          height: isActive ? 28 : (isCompleted ? 22 : 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: (isCompleted || isActive)
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: isActive ? 10 : 5, // 12/6 → 10/5
                      spreadRadius: isActive ? 2 : 0, // 3/1 → 2/0
                    ),
                  ]
                : null,
          ),
          child: isActive
              ? _buildActiveNodeContent(color)
              : (isCompleted ? _buildCompletedNodeContent() : null),
        ),
      ),
    );
  }

  /// 活跃节点内容（旋转光环）
  Widget _buildActiveNodeContent(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 旋转光环
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * 3.14159,
              child: Container(
                width: 28, // 32 → 28
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: CustomPaint(
                  painter: _ArcPainter(color: color),
                ),
              ),
            );
          },
        ),

        // 中心圆点
        Container(
          width: 10, // 12 → 10
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 5, // 6 → 5
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 已完成节点内容（勾选图标）
  Widget _buildCompletedNodeContent() {
    return const Icon(
      Icons.check,
      size: 12, // 14 → 12
      color: Colors.white,
    );
  }

  /// 阶段标签
  Widget _buildStageLabel(String label, int step, int currentStep, Color color, bool isIdle) {
    final isActive = !isIdle && step == currentStep;
    final isCompleted = !isIdle && step < currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12, // 统一12px
            fontWeight: FontWeight.w600, // 统一W600
            letterSpacing: 0.5,
            height: 1.2,
            color: isIdle
                ? color.withValues(alpha: 0.5)
                : (isCompleted || isActive ? color : const Color(0xFF94A3B8)),
          ),
          textAlign: TextAlign.center,
        ),
        // 活跃状态显示指示点
        if (!isIdle && isActive) ...[
          const SizedBox(height: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageCard(AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _selectedImages.isEmpty ? _buildPlaceholder(l10n) : _buildImageViewer(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08 + 0.04 * _pulseController.value),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4 + 0.3 * _pulseController.value),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tapToUpload,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '支持多选图片',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // 图片查看器（支持滑动切换）
        PageView.builder(
          controller: _pageController,
          itemCount: _selectedImages.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
              _transformationController.value = Matrix4.identity();
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  _selectedImages[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          const SizedBox(height: 8),
                          Text(AppLocalizations.of(context)!.pickImageFailed, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        // 多张图片时显示指示器
        if (_selectedImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),
      ],
    );
  }

  /// 页面指示器
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _selectedImages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentImageIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentImageIndex == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt_outlined,
                    label: l10n.camera,
                    onTap: () => _handlePickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library_outlined,
                    label: l10n.gallery,
                    onTap: () => _handlePickMultipleImages(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchButton(l10n),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNumberSection(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DrawingSearchPage(
            drawingService: widget.drawingService,
          )),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.searchArchived,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberSection(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 计算当前页的编号列表
    final int startIndex = _numberPage * _numbersPerPage;
    final int endIndex = (startIndex + _numbersPerPage).clamp(0, _selectedImages.length);
    final int totalPages = (_selectedImages.length / _numbersPerPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            const Icon(Icons.tag_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.drawingNumber,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            // 显示页码信息
            if (_selectedImages.length > _numbersPerPage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '第 ${_numberPage + 1}/$totalPages 页',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            // 显示图片数量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_selectedImages.length} 张',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 编号列表卡片（子页面）
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // 编号列表
              ...List.generate(endIndex - startIndex, (index) {
                final actualIndex = startIndex + index;
                return _buildNumberItem(l10n, actualIndex, index == endIndex - startIndex - 1);
              }),

              // 分页按钮
              if (_selectedImages.length > _numbersPerPage)
                _buildPaginationButtons(totalPages),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 保存按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_isAnalyzing || _isSaving) ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              disabledBackgroundColor: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, size: 18),
                      const SizedBox(width: 8),
                      Text('保存所有图片'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// 单个编号输入项
  Widget _buildNumberItem(AppLocalizations l10n, int index, bool isLast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAiNumber = _recognizedNumbers[index].isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: isLast ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 图片缩略图
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    child: Icon(
                      Icons.broken_image,
                      size: 20,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 图片序号和 AI 标识
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '图片 ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  if (hasAiNumber) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 10, color: Color(0xFF10B981)),
                          const SizedBox(width: 2),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF065F46) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const Spacer(),

          // 编号输入框
          Expanded(
            flex: 2,
            child: TextField(
              controller: _numberControllers[index],
              decoration: InputDecoration(
                hintText: l10n.placeholderNumber,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
              enabled: !_isAnalyzing,
            ),
          ),
        ],
      ),
    );
  }

  /// 分页按钮
  Widget _buildPaginationButtons(int totalPages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 上一页按钮
          Expanded(
            child: InkWell(
              onTap: _numberPage > 0
                  ? () {
                      setState(() {
                        _numberPage--;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: _numberPage > 0
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: _numberPage > 0 ? Colors.white : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '上一页',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _numberPage > 0 ? Colors.white : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 下一页按钮
          Expanded(
            child: InkWell(
              onTap: _numberPage < totalPages - 1
                  ? () {
                      setState(() {
                        _numberPage++;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: _numberPage < totalPages - 1
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '下一页',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _numberPage < totalPages - 1
                              ? Colors.white
                              : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: _numberPage < totalPages - 1
                            ? Colors.white
                            : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 图片选择确认对话框
class _ConfirmImageDialog extends StatelessWidget {
  final int imageCount;

  const _ConfirmImageDialog({required this.imageCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部装饰条
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 图标
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 标题
                  Text(
                    '确认选择',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 图片数量
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '已选择 $imageCount 张图片',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 按钮行
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogButton(
                          context: context,
                          label: '取消',
                          isPrimary: false,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogButton(
                          context: context,
                          label: '确认',
                          isPrimary: true,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required BuildContext context,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 连接线绘制器
class _ConnectorLinePainter extends CustomPainter {
  final Color color;
  final double progress; // 0.0 到 1.0

  _ConnectorLinePainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景线（灰色）
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 3 // 4 → 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      bgPaint,
    );

    // 进度线（彩色）
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 3 // 4 → 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width * progress, centerY),
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 旋转弧线绘制器（用于活跃节点）
class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 绘制 270° 弧线
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 // 3 → 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // 从顶部开始
      2 * 3.14159 * 0.75, // 270°
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.5)
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
