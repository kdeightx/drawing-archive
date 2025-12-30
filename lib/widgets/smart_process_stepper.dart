import 'package:flutter/material.dart';

/// 步骤数据模型
class StepData {
  final String label;
  final bool isCompleted;
  final bool isActive;
  final Color? color;  // 节点颜色（如果为null则使用activeColor）

  StepData({
    required this.label,
    this.isCompleted = false,
    this.isActive = false,
    this.color,
  });

  StepData copyWith({
    String? label,
    bool? isCompleted,
    bool? isActive,
    Color? color,
  }) {
    return StepData(
      label: label ?? this.label,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
    );
  }
}

/// 智能进度条组件 - 数据驱动，可复用
class SmartProcessStepper extends StatelessWidget {
  final List<StepData> steps;
  final Color activeColor;
  final Color backgroundColor;
  final bool isDark;
  final AnimationController? pulseController;

  const SmartProcessStepper({
    super.key,
    required this.steps,
    required this.activeColor,
    required this.backgroundColor,
    required this.isDark,
    this.pulseController,
  });

  /// 计算当前总体进度 (0.0 - 1.0)
  double _calculateProgress() {
    int lastActiveIndex = -1;
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].isCompleted || steps[i].isActive) {
        lastActiveIndex = i;
      }
    }

    if (lastActiveIndex == -1) return 0.0;
    if (steps.length <= 1) return 1.0;
    return lastActiveIndex / (steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final lineProgress = _calculateProgress();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // 自动计算每个节点的中心点 X 坐标
        // 使用 0.15 - 0.85 的布局区间
        final double startX = totalWidth * 0.15;
        final double endX = totalWidth * 0.85;
        final double totalDistance = endX - startX;

        final List<Offset> nodePositions = List.generate(steps.length, (index) {
          final double t = steps.length == 1 ? 0.5 : index / (steps.length - 1);
          return Offset(startX + t * totalDistance, 16);
        });

        return Column(
          children: [
            // 1. 图形区域 (连接线 + 圆环 + 节点)
            SizedBox(
              height: 32,
              child: Stack(
                children: [
                  // 底层：统一绘制连接线和圆环框架
                  CustomPaint(
                    size: Size(totalWidth, 32),
                    painter: _SmartStepperPainter(
                      positions: nodePositions,
                      lineProgress: lineProgress,
                      color: activeColor,
                      backgroundColor: backgroundColor,
                    ),
                  ),

                  // 顶层：放置具体的交互节点 (球体内容)
                  ...List.generate(steps.length, (index) {
                    final pos = nodePositions[index];
                    return Positioned(
                      left: pos.dx - 16,
                      width: 32,
                      height: 32,
                      child: _buildNodeWidget(steps[index]),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // 2. 文字标签区域 (绝对对齐节点)
            SizedBox(
              height: 30,
              child: Stack(
                children: List.generate(steps.length, (index) {
                  final pos = nodePositions[index];
                  final step = steps[index];
                  return Positioned(
                    left: pos.dx - 40,
                    width: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.3,
                            color: activeColor,
                          ),
                        ),
                        // 活跃状态显示指示点
                        if (step.isActive) ...[
                          const SizedBox(height: 3),
                          Center(
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withValues(alpha: 0.6),
                                    blurRadius: 3,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建节点小球 - 多层立体设计
  Widget _buildNodeWidget(StepData data) {
    final ballSize = data.isActive ? 20.0 : 16.0;
    final backgroundSize = ballSize + 6;
    // 只在活跃或已完成状态时使用步骤自己的颜色，否则使用全局activeColor
    final stepColor = (data.isActive || data.isCompleted) && data.color != null
        ? data.color!
        : activeColor;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景遮挡球（遮挡连接线）
          Container(
            width: backgroundSize,
            height: backgroundSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
            ),
          ),

          // 活跃状态的外呼吸光晕
          if (data.isActive && pulseController != null)
            _buildBreathingGlow(stepColor, ballSize),

          // 主体球层
          _buildMainBall(data, stepColor, ballSize),

          // 高光反射层（增加立体感）
          if (data.isActive || data.isCompleted)
            _buildHighlight(ballSize),
        ],
      ),
    );
  }

  /// 呼吸光晕效果
  Widget _buildBreathingGlow(Color color, double ballSize) {
    return AnimatedBuilder(
      animation: pulseController!,
      builder: (context, child) {
        final glowSize = ballSize + 8 + 6 * pulseController!.value;
        final glowAlpha = 0.3 - 0.2 * pulseController!.value;
        return Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: glowAlpha),
          ),
        );
      },
    );
  }

  /// 主体球层
  Widget _buildMainBall(StepData data, Color stepColor, double ballSize) {
    final isIdle = !data.isActive && !data.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: ballSize,
      height: ballSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 空闲状态：圆环；活跃/完成：实心渐变
        gradient: isIdle
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  stepColor.withValues(alpha: 0.95),
                  stepColor.withValues(alpha: 0.75),
                ],
                stops: const [0.3, 1.0],
              ),
        color: isIdle
            ? stepColor.withValues(alpha: isDark ? 0.25 : 0.15)
            : null,
        // 多层阴影营造立体感
        boxShadow: isIdle
            ? [
                // 内阴影效果
                BoxShadow(
                  color: backgroundColor,
                  offset: const Offset(1, 1),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
                // 外阴影
                BoxShadow(
                  color: stepColor.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                // 深色外阴影
                BoxShadow(
                  color: stepColor.withValues(alpha: 0.5),
                  blurRadius: data.isActive ? 8 : 4,
                  offset: const Offset(0, 2),
                  spreadRadius: data.isActive ? -1 : 0,
                ),
                // 亮色内阴影（模拟边缘高光）
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.3),
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                  spreadRadius: -1,
                ),
              ],
        // 空闲状态的圆环效果
        border: isIdle
            ? Border.all(
                color: stepColor.withValues(alpha: isDark ? 0.4 : 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: data.isCompleted
          ? _buildCompletedNodeContent()
          : (data.isActive ? _buildActiveNodeContent(stepColor) : null),
    );
  }

  /// 高光反射层（增加质感）
  Widget _buildHighlight(double ballSize) {
    return Positioned(
      top: ballSize * 0.15,
      left: ballSize * 0.25,
      child: Container(
        width: ballSize * 0.25,
        height: ballSize * 0.15,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
    );
  }

  /// 活跃节点内容（精致脉冲核心）
  Widget _buildActiveNodeContent(Color color) {
    if (pulseController == null) return const SizedBox();

    return AnimatedBuilder(
      animation: pulseController!,
      builder: (context, child) {
        // 双层脉冲：内层亮核 + 外层光环
        final coreSize = 4.0 + 1.5 * pulseController!.value;
        final ringSize = 6.0 + 2.0 * pulseController!.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 外光环
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3 - 0.2 * pulseController!.value),
              ),
            ),
            // 内亮核
            Container(
              width: coreSize,
              height: coreSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 3 + 2 * pulseController!.value,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 已完成节点内容（精致勾选图标）
  Widget _buildCompletedNodeContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 勾选图标
        Icon(
          Icons.check_rounded,
          size: 8,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
      ],
    );
  }
}

/// 核心：Painter 只负责画"死"的东西（线、圆环背景）
class _SmartStepperPainter extends CustomPainter {
  final List<Offset> positions;
  final double lineProgress;
  final Color color;
  final Color backgroundColor;

  _SmartStepperPainter({
    required this.positions,
    required this.lineProgress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final centerY = size.height / 2;
    const outerRadius = 13.0;  // 外圆半径
    const innerRadius = 10.5;  // 内圆半径（圆环粗细 = 13 - 10.5 = 2.5）
    const barHeight = 2.5;     // 连接线高度

    // --- 1. 绘制背景轨道（融合路径） ---
    final bgPath = Path();
    for (int i = 0; i < positions.length; i++) {
      // 添加圆节点
      bgPath.addOval(Rect.fromCircle(center: Offset(positions[i].dx, centerY), radius: outerRadius));
      // 添加连接线
      if (i < positions.length - 1) {
        bgPath.addRect(Rect.fromLTRB(
          positions[i].dx,
          centerY - barHeight / 2,
          positions[i + 1].dx,
          centerY + barHeight / 2,
        ));
      }
    }
    canvas.drawPath(bgPath, Paint()..color = color.withValues(alpha: 0.3));

    // --- 2. 绘制高亮进度条（融合路径） ---
    if (lineProgress > 0) {
      final activePath = Path();

      // 2.1 添加已激活的圆节点
      final totalWidth = positions.last.dx - positions.first.dx;
      final currentPos = positions.first.dx + totalWidth * lineProgress;

      for (int i = 0; i < positions.length; i++) {
        final pos = positions[i];
        if (currentPos >= pos.dx - outerRadius) {
          activePath.addOval(Rect.fromCircle(center: Offset(pos.dx, centerY), radius: outerRadius));
        }
      }

      // 2.2 添加连接线（圆头）
      final startX = positions.first.dx;
      final endX = currentPos.clamp(startX, positions.last.dx);
      activePath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(startX, centerY - barHeight / 2, endX, centerY + barHeight / 2),
        const Radius.circular(barHeight / 2),
      ));

      canvas.drawPath(activePath, Paint()..color = color.withValues(alpha: 0.6));
    }

    // --- 3. 挖孔（实现圆环效果） ---
    final maskPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    for (final pos in positions) {
      canvas.drawCircle(Offset(pos.dx, centerY), innerRadius, maskPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmartStepperPainter old) =>
      old.lineProgress != lineProgress || old.positions != positions;
}
