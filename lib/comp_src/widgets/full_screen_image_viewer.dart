import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_models/drawing_scanner_view_model.dart';

/// 全屏图片预览组件
///
/// 支持多图查看、缩放、旋转、滑动切换、双击放大
class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({super.key});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with TickerProviderStateMixin {
  /// TransformationController 用于缩放和平移
  late TransformationController _transformationController;

  /// PageController 用于图片滑动切换
  late PageController _pageController;

  /// 动画控制器
  late AnimationController _animationController;

  /// 动画
  Animation<Matrix4>? _animation;

  /// Transform 容器的 GlobalKey，用于双击时的坐标转换
  final GlobalKey _transformKey = GlobalKey();

  /// 手势初始状态
  Offset? _initialFocalPoint;
  Matrix4? _initialMatrix;

  /// 控制 UI 是否显示（用于沉浸式交互）
  bool _showControls = true;

  /// 判断是否应该允许页面滑动（当缩放比例 > 1.0 时禁止滑动）
  bool get _allowPageScroll {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    return scale <= 1.01; // 允许小的浮点误差
  }

  @override
  void initState() {
    super.initState();
    // 进入页面时，强制将状态栏文字设为白色（因为背景是黑色）
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final viewModel = context.read<DrawingScannerViewModel>();
    _transformationController = TransformationController();
    _pageController = PageController(initialPage: viewModel.currentImageIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _transformationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // 退出页面时，恢复原来的状态栏样式
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _transformationController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<DrawingScannerViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              _buildImageContent(viewModel),
              _buildTopAppBar(viewModel),
              _buildBottomIndicator(viewModel),
            ],
          );
        },
      ),
    );
  }

  /// 构建图片内容区域
  Widget _buildImageContent(DrawingScannerViewModel viewModel) {
    if (viewModel.selectedImages.isEmpty) {
      return const Center(
        child: Text(
          '暂无图片',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: viewModel.selectedImages.length,
      physics: _allowPageScroll
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(), // 缩放时禁止滑动切换
      onPageChanged: (index) {
        viewModel.setCurrentImageIndex(index);
        viewModel.resetRotation();
      },
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // 单击切换 UI 显示/隐藏（沉浸式交互）
            setState(() {
              _showControls = !_showControls;
            });
            // 配合系统沉浸式模式（隐藏/显示顶部状态栏）
            if (_showControls) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            } else {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
            }
          },
          onDoubleTapDown: (details) {
            // 双击放大/缩小（传递屏幕绝对坐标）
            _handleDoubleTap(details.globalPosition);
          },
          // 使用 translucent 让滑动手势传递给 PageView
          behavior: HitTestBehavior.translucent,
          child: SizedBox.expand(
            child: _buildRotatedImage(viewModel, index),
          ),
        );
      },
    );
  }

  /// 处理双击事件
  void _handleDoubleTap(Offset globalFocalPoint) {
    // 获取 Transform 容器的渲染盒子
    final RenderBox? renderBox = _transformKey.currentContext?.findRenderObject() as RenderBox?;

    // 如果找不到渲染对象（通常不会发生），直接返回
    if (renderBox == null) return;

    // A. 关键步骤：将屏幕绝对坐标(Global)转换为组件局部坐标(Local)
    // 这一步会自动处理所有的旋转、平移带来的坐标系变化
    final Offset localFocalPoint = renderBox.globalToLocal(globalFocalPoint);

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _animateToScale(1.0);
    } else {
      // 传入转换后的局部坐标
      _animateToScaleAtPoint(2.0, localFocalPoint, renderBox);
    }
  }

  /// 动画缩放到指定比例
  void _animateToScale(double targetScale) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity()..scale(targetScale, targetScale, targetScale),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward();

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  /// 以指定位置为中心缩放（简化版，不使用 toScene）
  /// [localFocalPoint]: 点击点在组件局部坐标系中的位置
  /// [renderBox]: 用于计算中心点的相对位置
  void _animateToScaleAtPoint(double targetScale, Offset localFocalPoint, RenderBox renderBox) {
    // 获取当前变换矩阵
    final Matrix4 currentMatrix = _transformationController.value;

    // 计算视图中心的局部坐标
    final Offset viewportCenter = renderBox.size.center(Offset.zero);

    // 计算缩放前点击点相对于中心的偏移
    final Offset offsetFromCenter = localFocalPoint - viewportCenter;

    // 计算平移量
    // 公式：让点击点在缩放后移动到屏幕中心
    // Translation = -Offset * (Scale - 1)
    final double translationX = -offsetFromCenter.dx * (targetScale - 1);
    final double translationY = -offsetFromCenter.dy * (targetScale - 1);

    // 构建目标矩阵
    final Matrix4 endMatrix = Matrix4.identity()
      ..translate(translationX, translationY, 0.0)
      ..scale(targetScale, targetScale, targetScale);

    // 开始动画
    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    _animationController.forward();

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  /// 构建可旋转、缩放、移动的图片（支持双指旋转 + 定点缩放）
  Widget _buildRotatedImage(DrawingScannerViewModel viewModel, int index) {
    final size = MediaQuery.of(context).size;
    final isRotated = viewModel.currentRotation == 90 || viewModel.currentRotation == 270;

    return Center(
      child: RotatedBox(
        quarterTurns: viewModel.currentRotation ~/ 90,
        child: SizedBox(
          width: isRotated ? size.height : size.width,
          height: isRotated ? size.width : size.height,
          child: _buildGestureImage(viewModel, index),
        ),
      ),
    );
  }

  /// 构建带手势的图片（双指缩放+旋转+移动）
  Widget _buildGestureImage(DrawingScannerViewModel viewModel, int index) {
    return Container(
      key: index == viewModel.currentImageIndex ? _transformKey : null, // 只在当前页绑定 key
      child: AnimatedBuilder(
        animation: _transformationController,
        builder: (context, child) {
          return GestureDetector(
            // 关键：确保点击空白处也能响应手势
            behavior: HitTestBehavior.translucent,

            // 1. 手势开始：记录"起跑线"
            onScaleStart: (details) {
              _initialFocalPoint = details.localFocalPoint; // 记录手指按下的位置（作为中心点）
              _initialMatrix = _transformationController.value.clone(); // 记录图片当前的姿态
            },

            // 2. 手势更新：实时计算变换
            onScaleUpdate: (details) {
              if (_initialFocalPoint == null || _initialMatrix == null) return;

              // --- 准备数据 ---
              final double scale = details.scale;
              final double rotation = details.rotation;

              // 计算手指的移动向量（当前位置 - 起始位置）
              // 这实现了"拖动到屏幕中间查看"的功能
              final Offset translationDelta = details.localFocalPoint - _initialFocalPoint!;

              final Offset focalPoint = _initialFocalPoint!; // 缩放/旋转的中心点（锚点）

              // --- 矩阵计算 ---
              final Matrix4 matrix = _initialMatrix!.clone();

              // 步骤 A: 平移
              // 先让图片跟随手指移动
              matrix.translate(translationDelta.dx, translationDelta.dy, 0.0);

              // 步骤 B: 定点缩放与旋转 (Focal Zoom & Rotate)
              // 逻辑三明治：移到锚点 -> 变换 -> 移回锚点

              // B.1 将坐标原点移动到手指按下的位置
              matrix.translate(focalPoint.dx, focalPoint.dy, 0.0);

              // B.2 应用旋转和缩放
              matrix.rotateZ(rotation);
              matrix.scale(scale, scale, scale);

              // B.3 将坐标原点恢复回去
              matrix.translate(-focalPoint.dx, -focalPoint.dy, 0.0);

              // --- 应用最终结果 ---
              _transformationController.value = matrix;
            },

            // 3. 手势结束
            onScaleEnd: (details) {
              _initialFocalPoint = null;
              _initialMatrix = null;

              // 可选：在这里添加回弹动画（checkBoundary）
              // 如果图片缩得太小，可以在这里让它弹回 1.0 倍
              final currentScale = _transformationController.value.getMaxScaleOnAxis();
              if (currentScale < 1.0) {
                _animateToScale(1.0);
              }
            },

            child: Transform(
              transform: _transformationController.value,
              alignment: Alignment.center, // 矩阵已经处理了对齐，这里默认即可
              child: Image.file(
                viewModel.selectedImages[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建顶部操作栏
  Widget _buildTopAppBar(DrawingScannerViewModel viewModel) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        // 关键：根据 _showControls 控制透明度
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        // 如果隐藏了，就忽略点击事件，防止误触
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            // 去掉 SafeArea，改用 Padding，这样渐变色能铺满顶部
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8, // 适配刘海屏
              bottom: 12,
              left: 8,
              right: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8), // 顶部深色
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 两端对齐
              children: [
                // 1. 新增：返回按钮
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '返回',
                ),

                // 中间的信息和旋转按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.rotate_left, color: Colors.white),
                      onPressed: () => viewModel.rotateCounterClockwise(),
                      tooltip: '逆时针旋转',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${viewModel.currentImageIndex + 1}/${viewModel.selectedImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.rotate_right, color: Colors.white),
                      onPressed: () => viewModel.rotateClockwise(),
                      tooltip: '顺时针旋转',
                    ),
                  ],
                ),

                // 右侧占位（为了让中间内容居中）或者放其他功能按钮
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部指示器
  Widget _buildBottomIndicator(DrawingScannerViewModel viewModel) {
    if (viewModel.selectedImages.length <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  viewModel.selectedImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: viewModel.currentImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: viewModel.currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
