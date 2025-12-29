import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/drawing_service.dart';
import 'drawing_search_page.dart';
import 'drawing_settings_page.dart';

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
  final TransformationController _transformationController = TransformationController();
  final PageController _pageController = PageController();

  late AnimationController _scanController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // 清理所有编号输入控制器
    for (var controller in _numberControllers) {
      controller.dispose();
    }
    _transformationController.dispose();
    _pageController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
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

    setState(() => _isAnalyzing = true);

    try {
      final File currentImage = _selectedImages[_currentImageIndex];
      final String number = await widget.drawingService.analyzeImage(currentImage);

      if (!mounted) return;

      setState(() {
        _recognizedNumbers[_currentImageIndex] = number;
        _numberControllers[_currentImageIndex].text = number;
        _isAnalyzing = false;
      });

      _showSnackBar(AppLocalizations.of(context)!.saved, isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _showSnackBar('${AppLocalizations.of(context)!.recognizeFailed}: $e', isError: true);
    }
  }

  /// 批量分析所有图片
  Future<void> _handleAnalyzeAllImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isAnalyzing = true);

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

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      _showSnackBar('已完成 ${_selectedImages.length} 张图片的识别', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
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
          if (_isAnalyzing || _isSaving) _buildLoadingOverlay(l10n),
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.drawingScanSystem,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusText(l10n),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _isAnalyzing
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusIndicator(l10n),
          ],
        ),
      ),
    );
  }

  String _getStatusText(AppLocalizations l10n) {
    if (_isAnalyzing) return l10n.statusAnalyzing;
    if (_selectedImages.isNotEmpty) {
      if (_selectedImages.length > 1) {
        return '已选择 ${_selectedImages.length} 张图片 (${_currentImageIndex + 1}/${_selectedImages.length})';
      }
      return l10n.statusReady;
    }
    return l10n.statusWaiting;
  }

  Widget _buildStatusIndicator(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color statusColor = _isAnalyzing
        ? const Color(0xFFF59E0B)
        : (_selectedImages.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF94A3B8));

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color.lerp(
                isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                statusColor,
                _pulseController.value,
              )!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: _isAnalyzing
                      ? [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isAnalyzing ? l10n.analyzing : (_selectedImages.isNotEmpty ? l10n.statusReady : l10n.statusStandby),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        );
      },
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
        // 扫描动画覆盖层
        if (_isAnalyzing) _buildScanOverlay(),
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

  Widget _buildScanOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.9),
        ),
        child: Center(
          child: _buildCircularProgress(),
        ),
      ),
    );
  }

  Widget _buildCircularProgress() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.rotate(
                  angle: _scanController.value * 2 * 3.14159,
                  child: CircularProgressIndicator(
                    value: 0.7,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${(_scanController.value * 100).toInt()}%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                    label: '${l10n.gallery}(多选)',
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

  Widget _buildLoadingOverlay(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.95),
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.lerp(
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.primary,
                            _pulseController.value,
                          )!,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  _isSaving ? '批量处理中...' : l10n.analyzing,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _isSaving ? '正在保存 ${_selectedImages.length} 张图片' : l10n.analyzingHint,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
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
