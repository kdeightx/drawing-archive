import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_image/extended_image.dart';

/// 全屏图片预览组件（使用 InteractiveViewer 实现无边界缩放）
///
/// 提供系统相册级体验的图片预览功能：
/// - 全屏预览（黑色背景）
/// - 多图浏览（左右滑动切换）
/// - 手势缩放（双指/双击，以点击位置为中心）
/// - 无边界拖动（缩放后可自由拖动，不受边界限制）
/// - 沉浸式交互（单击隐藏/显示 UI）
/// - 智能交互（缩放前滑动翻页，缩放后锁定翻页）
class FullScreenImageViewer extends StatefulWidget {
  /// 图片文件路径列表
  final List<String> imagePaths;

  /// 初始显示的图片索引
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showControls = true;

  /// 是否允许 PageView 翻页
  /// 当任意图片缩放 > 1.01 时，锁定 PageView
  bool _enablePageScroll = true;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_showControls) _animationController.forward();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  /// 切换 UI 显示/隐藏状态
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _animationController.forward();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        _animationController.reverse();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    });
  }

  /// 子组件通知父组件：缩放状态改变了
  /// isZoomed: true 表示正在放大，需要锁死翻页；false 表示恢复原状，允许翻页
  void _onZoomStatusChanged(bool isZoomed) {
    // 只有状态真正改变时才 setState，优化性能
    if (_enablePageScroll == isZoomed) {
      setState(() {
        _enablePageScroll = !isZoomed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildImageGallery(),
          ),
          _buildTopBar(),
          _buildBottomIndicator(),
        ],
      ),
    );
  }

  /// 构建图片画廊（使用 PageView）
  Widget _buildImageGallery() {
    if (widget.imagePaths.isEmpty) {
      return const Center(
        child: Text(
          '暂无图片',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      // 【核心逻辑】根据缩放状态动态切换物理效果
      // 放大时：NeverScrollable (锁死)
      // 正常时：Bouncing (允许翻页)
      physics: _enablePageScroll
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: widget.imagePaths.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        return _ZoomableImageItem(
          imagePath: widget.imagePaths[index],
          onTap: _toggleControls,
          onZoomStatusChanged: _onZoomStatusChanged,
        );
      },
    );
  }

  /// 构建顶部工具栏
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 8,
              right: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '返回',
                ),
                Text(
                  '${_currentIndex + 1}/${widget.imagePaths.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部指示器
  Widget _buildBottomIndicator() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Text(
                _enablePageScroll ? '左右滑动查看图片' : '双指缩放 · 拖动查看',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 可缩放的图片项组件
///
/// 使用 InteractiveViewer 实现无边界拖动和缩放
class _ZoomableImageItem extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomStatusChanged;

  const _ZoomableImageItem({
    required this.imagePath,
    required this.onTap,
    required this.onZoomStatusChanged,
  });

  @override
  State<_ZoomableImageItem> createState() => _ZoomableImageItemState();
}

class _ZoomableImageItemState extends State<_ZoomableImageItem>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late AnimationController _doubleTapAnimationController;
  Animation<Matrix4>? _doubleTapAnimation;

  TapDownDetails? _doubleTapDetails;
  Timer? _singleTapTimer;
  bool _isZoomed = false;

  /// 双击缩放的目标比例
  static const double _doubleTapScale = 2.5;

  @override
  void initState() {
    super.initState();
    _doubleTapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 监听缩放变化
    _transformController.addListener(_onTransformationChange);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChange);
    _transformController.dispose();
    _doubleTapAnimationController.dispose();
    _singleTapTimer?.cancel();
    super.dispose();
  }

  /// 监听变换矩阵变化
  void _onTransformationChange() {
    final double scale = _transformController.value.getMaxScaleOnAxis();
    // 设置一个容差范围：scale < 0.99 或 scale > 1.01 都认为是缩放状态
    // 这样既能检测放大，也能检测缩小
    final bool isZoomedNow = scale < 0.99 || scale > 1.01;

    if (_isZoomed != isZoomedNow) {
      setState(() {
        _isZoomed = isZoomedNow;
      });
      // 通知父组件更新 PageView 的物理锁
      widget.onZoomStatusChanged(isZoomedNow);
    }
  }

  /// 处理双击事件
  void _handleDoubleTap() {
    if (_doubleTapAnimationController.isAnimating) return;

    final double currentScale = _transformController.value.getMaxScaleOnAxis();
    final Offset tapPosition = _doubleTapDetails!.localPosition;

    Matrix4 endMatrix;
    // 如果不在 1.0 的容差范围内（即已放大或已缩小），还原到 1.0
    if (currentScale < 0.99 || currentScale > 1.01) {
      endMatrix = Matrix4.identity();
    } else {
      // 如果是 1.0 状态，放大到 2.5 倍
      // 计算偏移量，使点击点处于屏幕中心
      // 算法：Translate(-pos * (scale - 1)) -> Scale(s)
      final double targetScale = _doubleTapScale;
      final double dx = -tapPosition.dx * (targetScale - 1);
      final double dy = -tapPosition.dy * (targetScale - 1);

      endMatrix = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    }

    // 启动动画
    _doubleTapAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _doubleTapAnimationController,
      curve: Curves.fastOutSlowIn,
    ));

    _doubleTapAnimation!.addListener(() {
      _transformController.value = _doubleTapAnimation!.value;
    });

    _doubleTapAnimationController.forward(from: 0);
  }

  /// 处理单击（防抖）
  void _handleSingleTap() {
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(const Duration(milliseconds: 200), () {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapDetails = d,
      onDoubleTap: _handleDoubleTap,
      onTap: _handleSingleTap,
      behavior: HitTestBehavior.translucent,
      child: InteractiveViewer(
        transformationController: _transformController,

        // 允许缩小到很小 (0.01)
        minScale: 0.01,
        // 允许无限放大
        maxScale: double.infinity,

        // 始终允许无限边界，确保在 1.0 时也能直接捏合缩小
        boundaryMargin: const EdgeInsets.all(double.infinity),

        // 只有在缩放状态下才响应平移 (Pan)
        // 1.0 时 Pan 被禁用，手势穿透给 PageView 用于翻页
        panEnabled: _isZoomed,

        // 始终允许缩放
        scaleEnabled: true,

        child: ExtendedImage.file(
          File(widget.imagePath),
          fit: BoxFit.contain,
          mode: ExtendedImageMode.none,
          enableLoadState: true,
        ),
      ),
    );
  }
}
