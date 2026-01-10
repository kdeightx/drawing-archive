import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart'; // 必须引入
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_image/extended_image.dart';

/// 全屏图片预览组件 (终极修正版)
///
/// 修复了 1.0x 状态下 GestureDetector 抢占手势导致无法翻页的问题
/// 特性：
/// 1. 支持双指【缩放】+【旋转】+【平移】+【无限拖拽】
/// 2. 完美解决与 PageView 的手势冲突
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
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
  bool _enablePageScroll = true;

  late AnimationController _uiAnimController;
  late Animation<double> _uiOpacityAnim;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    _uiAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _uiOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _uiAnimController, curve: Curves.easeInOut),
    );

    if (_showControls) _uiAnimController.forward();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _uiAnimController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _uiAnimController.forward();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        _uiAnimController.reverse();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    });
  }

  void _onStateChanged(bool isReset) {
    if (_enablePageScroll != isReset) {
      setState(() {
        _enablePageScroll = isReset;
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
            child: PageView.builder(
              controller: _pageController,
              // 这里的 physics 配合下面的手势识别器，完美解决冲突
              physics: _enablePageScroll
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return _GestureImageItem(
                  imagePath: widget.imagePaths[index],
                  onTap: _toggleControls,
                  onStateChanged: _onStateChanged,
                  enablePageScroll: _enablePageScroll, // 传入当前状态
                );
              },
            ),
          ),
          _buildTopBar(),
          _buildBottomIndicator(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: FadeTransition(
        opacity: _uiOpacityAnim,
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12, left: 8, right: 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIndicator() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: FadeTransition(
        opacity: _uiOpacityAnim,
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
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
            child: Center(
              child: Text(
                _enablePageScroll ? '左右滑动查看图片' : '双指旋转 · 自由拖拽',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GestureImageItem extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;
  final ValueChanged<bool> onStateChanged;
  final bool enablePageScroll; // 接收父组件的状态

  const _GestureImageItem({
    required this.imagePath,
    required this.onTap,
    required this.onStateChanged,
    required this.enablePageScroll,
  });

  @override
  State<_GestureImageItem> createState() => _GestureImageItemState();
}

class _GestureImageItemState extends State<_GestureImageItem>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late AnimationController _animController;
  Animation<Matrix4>? _animation;

  // 增量计算所需的状态变量
  Offset? _lastFocalPoint;
  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  int _lastPointerCount = 0; // 记录手指数量，用于检测切换

  Timer? _singleTapTimer;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _transformController.addListener(_checkState);
  }

  @override
  void dispose() {
    _transformController.removeListener(_checkState);
    _transformController.dispose();
    _animController.dispose();
    _singleTapTimer?.cancel();
    super.dispose();
  }

  void _checkState() {
    final Matrix4 m = _transformController.value;
    final double scale = m.getMaxScaleOnAxis();
    final bool hasRotation = m.entry(0, 1).abs() > 0.01;
    final bool hasScale = scale < 0.99 || scale > 1.01;
    final bool isTransformed = hasRotation || hasScale;
    widget.onStateChanged(!isTransformed);
  }

  /// 手势开始：记录初始状态
  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    _lastRotation = 0.0;
    _lastPointerCount = details.pointerCount;
  }

  /// 手势更新：核心增量算法
  void _onScaleUpdate(ScaleUpdateDetails details) {
    // 1. 手指数量变化检测 (防跳动核心)
    // 当从 1指 -> 2指 或 2指 -> 1指 时，FocalPoint 会突变。
    // 我们必须在此刻重置"上一帧"的数据，跳过这一帧的计算，防止图片瞬移。
    if (details.pointerCount != _lastPointerCount) {
      _lastFocalPoint = details.localFocalPoint;
      _lastScale = details.scale;
      _lastRotation = details.rotation;
      _lastPointerCount = details.pointerCount;
      return;
    }

    // 2. 计算增量 (Delta)
    // 这一帧比上一帧变了多少？
    final double scaleDelta = details.scale / _lastScale;
    final double rotationDelta = details.rotation - _lastRotation;

    // 3. 构建增量矩阵
    // 逻辑：将图片中心平移到新的手指位置 -> 旋转 -> 缩放 -> 移回原位
    final Matrix4 deltaMatrix = Matrix4.identity()
      ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
      ..rotateZ(rotationDelta)
      ..scale(scaleDelta)
      ..translate(-_lastFocalPoint!.dx, -_lastFocalPoint!.dy);

    // 4. 应用增量 (左乘：基于屏幕坐标系)
    // NewState = Delta * OldState
    _transformController.value = deltaMatrix * _transformController.value;

    // 5. 更新状态，为下一帧做准备
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = details.scale;
    _lastRotation = details.rotation;
  }

  void _handleDoubleTap() {
    if (_animController.isAnimating) return;

    final Matrix4 current = _transformController.value;
    final double scale = current.getMaxScaleOnAxis();
    final bool hasRotation = current.entry(0, 1).abs() > 0.01;

    Matrix4 target;
    if (scale < 0.99 || scale > 1.01 || hasRotation) {
      target = Matrix4.identity();
    } else {
      final Offset tapPos = _doubleTapDetails?.localPosition ?? Offset.zero;
      final double s = 2.5;
      final double dx = tapPos.dx * (1 - s);
      final double dy = tapPos.dy * (1 - s);
      target = Matrix4.identity()..translate(dx, dy)..scale(s);
    }

    _animation = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuad),
    );
    _animation!.addListener(() {
      _transformController.value = _animation!.value;
    });
    _animController.forward(from: 0);
  }

  void _handleSingleTap() {
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(const Duration(milliseconds: 200), () {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 【核心修复】使用 RawGestureDetector + 自定义手势识别器
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        // 自定义 Scale 识别器：在单指且允许翻页时，主动"装死"，让给 PageView
        _CheckScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            _CheckScaleGestureRecognizer>(
          () => _CheckScaleGestureRecognizer(
            debugOwner: this,
            isPageScrollEnabled: widget.enablePageScroll,
          ),
          (_CheckScaleGestureRecognizer instance) {
            instance.onStart = _onScaleStart;
            instance.onUpdate = _onScaleUpdate;
          },
        ),
        // 双击识别器保持不变
        DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            DoubleTapGestureRecognizer>(
          () => DoubleTapGestureRecognizer(debugOwner: this),
          (DoubleTapGestureRecognizer instance) {
            instance.onDoubleTapDown = (d) => _doubleTapDetails = d;
            instance.onDoubleTap = _handleDoubleTap;
          },
        ),
        // 单击识别器
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this),
          (TapGestureRecognizer instance) {
            instance.onTap = _handleSingleTap;
          },
        ),
      },
      // 【修复核心】：使用 AnimatedBuilder 监听 _transformController
      // 只有加上这个，矩阵变化时界面才会刷新！
      child: AnimatedBuilder(
        animation: _transformController,
        builder: (context, child) {
          return Transform(
            transform: _transformController.value,
            alignment: Alignment.topLeft,
            child: child,
          );
        },
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

/// 【自定义手势识别器】
/// 解决痛点：GestureDetector 在单指滑动时会抢占 PageView 的事件。
/// 原理：如果检测到只有 1 个手指，且当前允许翻页，就直接丢弃移动事件，
/// 这样底层的 PageView 就能收到事件并正常翻页了。
class _CheckScaleGestureRecognizer extends ScaleGestureRecognizer {
  final bool isPageScrollEnabled;
  int _pointerCount = 0; // 手动追踪手指数量

  _CheckScaleGestureRecognizer({
    super.debugOwner,
    required this.isPageScrollEnabled,
  });

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointerCount++;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerCount--;
    }

    // 【关键逻辑】
    // 1. 如果当前允许翻页 (isPageScrollEnabled = true)
    // 2. 并且只有 1 根手指 (_pointerCount < 2)
    // 3. 并且是移动事件 (PointerMoveEvent)
    // -> 那么，我们直接忽略这个事件（不传给 super）。
    // 结果：ScaleGestureRecognizer 认为没有发生移动，不会宣示主权。
    // PageView 的 HorizontalDragGestureRecognizer 则会看到移动，并宣示主权，成功翻页！
    if (isPageScrollEnabled && _pointerCount < 2 && event is PointerMoveEvent) {
      return;
    }

    super.handleEvent(event);
  }
}
