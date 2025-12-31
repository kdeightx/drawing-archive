import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/drawing_service.dart';
import '../widgets/action_card.dart';
import '../widgets/image_display_card.dart';
import '../widgets/smart_process_stepper.dart';
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
  final ScrollController _scrollController = ScrollController();

  late AnimationController _pulseController;

  /// 操作区域的 GlobalKey，用于确保删除后该区域在视野内
  final GlobalKey _actionCardKey = GlobalKey();

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
    // 清理所有编号输入控制器
    for (var controller in _numberControllers) {
      controller.dispose();
    }
    _transformationController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
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
        final List<String> numbers = List.filled(images.length, '', growable: true);
        final List<TextEditingController> controllers =
            List.generate(images.length, (index) => TextEditingController(), growable: true);

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

      // 3秒后恢复到非活跃状态（所有步骤恢复初始灰色圆环状态）
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _progressState = null);
      }

      _showSnackBar(
        '已完成 ${_selectedImages.length} 张图片的识别',
        isError: false,
        isSuccess: true,
      );
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

  void _showSnackBar(String message, {required bool isError, bool isSuccess = false}) {
    if (!mounted) return;

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

    // 计算 AppBar 高度 + 顶部安全区域 + 间距
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double topPadding = mediaQuery.padding.top; // 顶部安全区域（状态栏）
    final double appBarHeight = kToolbarHeight; // AppBar 默认高度 56
    final double topPosition = topPadding + appBarHeight + 8; // +8 像素间距

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // 显示在 AppBar 下方
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: mediaQuery.size.height - topPosition - 60, // 计算底部边距，使SnackBar显示在顶部
        ),
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
              controller: _scrollController,
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

    // 计算当前步骤和进度
    int currentStep = -1;
    double progress = 0.0;

    switch (_progressState) {
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
    final sendingColor = const Color(0xFF3B82F6);    // 蓝色 - 发送中
    final scanningColor = const Color(0xFFF59E0B);   // 橙色 - AI扫描中
    final completedColor = const Color(0xFF10B981);  // 绿色 - 已完成

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
        isCompleted: currentStep >= 2,  // 修改：>= 2 表示完成状态也是已完成
        color: completedColor,
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: isDark ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.5,
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
                  isIdle ? '就绪' : (currentStep == 0 ? '发送中' : (currentStep == 1 ? 'AI扫描中' : '已完成')),
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

            // 进度指示器（使用新的智能组件）
            SmartProcessStepper(
              steps: steps,
              activeColor: baseBlue,
              backgroundColor: bgColor,
              isDark: isDark,
              pulseController: _pulseController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(AppLocalizations l10n) {
    return ImageDisplayCard(
      images: _selectedImages,
      currentIndex: _currentImageIndex,
      pageController: _pageController,
      transformationController: _transformationController,
      onIndexChange: (index) {
        setState(() {
          _currentImageIndex = index;
          _transformationController.value = Matrix4.identity();
        });
      },
    );
  }


  Widget _buildActionCard(AppLocalizations l10n) {
    // 构建 NumberItem 列表
    final numberItems = List.generate(_selectedImages.length, (index) {
      return NumberItem(
        id: 'img_$index',
        image: _selectedImages[index],
        index: index,
        number: _numberControllers[index].text,
        hasAiNumber: _recognizedNumbers[index].isNotEmpty,
      );
    });

    final totalPages = (_selectedImages.length / _numbersPerPage).ceil();

    return ActionCard(
      key: _actionCardKey,
      onCameraTap: () => _handlePickImage(ImageSource.camera),
      onGalleryTap: _handlePickMultipleImages,
      onSearchTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DrawingSearchPage(
            drawingService: widget.drawingService,
          )),
        );
      },
      numberItems: numberItems,
      currentPage: _numberPage,
      totalPages: totalPages,
      itemsPerPage: _numbersPerPage,
      onNumberChange: (index) {
        // 编号变化时更新控制器
        _numberControllers[index].text = numberItems[index].number;
      },
      onDeleteTap: (index) async {
        setState(() {
          _selectedImages.removeAt(index);
          _numberControllers[index].dispose();
          _numberControllers.removeAt(index);
          _recognizedNumbers.removeAt(index);
          if (_currentImageIndex >= _selectedImages.length) {
            _currentImageIndex = _selectedImages.length - 1;
          }
          if (_numberPage > 0 && (_numberPage * _numbersPerPage) >= _selectedImages.length) {
            _numberPage--;
          }
        });

        // 等待 setState 完成后，确保操作区域在可视范围内
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && _actionCardKey.currentContext != null) {
          Scrollable.ensureVisible(
            _actionCardKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.2, // 操作区域显示在屏幕上方 20% 的位置
          );
        }
      },
      onPreviousPage: _numberPage > 0
          ? () async {
              setState(() {
                _numberPage--;
              });

              // 等待 setState 完成后，确保操作区域在可视范围内
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted && _actionCardKey.currentContext != null) {
                Scrollable.ensureVisible(
                  _actionCardKey.currentContext!,
                  duration: const Duration(milliseconds: 300),
                  alignment: 0.2,
                );
              }
            }
          : null,
      onNextPage: _numberPage < totalPages - 1
          ? () async {
              setState(() {
                _numberPage++;
              });

              // 等待 setState 完成后，确保操作区域在可视范围内
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted && _actionCardKey.currentContext != null) {
                Scrollable.ensureVisible(
                  _actionCardKey.currentContext!,
                  duration: const Duration(milliseconds: 300),
                  alignment: 0.2,
                );
              }
            }
          : null,
      onSave: _handleSave,
      isSaving: _isSaving,
      isAnalyzing: _isAnalyzing,
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
