import 'dart:io';

import 'package:flutter/material.dart';

/// 图片显示卡片组件 - 支持多图查看、缩放、滑动切换
class ImageDisplayCard extends StatelessWidget {
  /// 图片列表
  final List<File> images;
  /// 当前查看的图片索引
  final int currentIndex;
  /// PageController 用于滑动切换
  final PageController pageController;
  /// TransformationController 用于缩放平移
  final TransformationController transformationController;
  /// 索引变化回调
  final ValueChanged<int> onIndexChange;

  const ImageDisplayCard({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.transformationController,
    required this.onIndexChange,
  });

  @override
  Widget build(BuildContext context) {
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
          child: images.isEmpty ? _buildPlaceholder(context) : _buildImageViewer(context),
        ),
      ),
    );
  }

  /// 空状态占位符
  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: const AlwaysStoppedAnimation(0.5),
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '点击上传图片',
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

  /// 图片查看器
  Widget _buildImageViewer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // 图片查看器（支持滑动切换）
        PageView.builder(
          controller: pageController,
          itemCount: images.length,
          onPageChanged: onIndexChange,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              transformationController: transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          const SizedBox(height: 8),
                          Text('图片加载失败', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
        if (images.length > 1) _buildPageIndicator(context),
      ],
    );
  }

  /// 页码指示器
  Widget _buildPageIndicator(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          images.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: currentIndex == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
