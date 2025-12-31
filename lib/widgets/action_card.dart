import 'dart:io';

import 'package:flutter/material.dart';

/// 编号项数据模型
class NumberItem {
  final String id;          // 唯一标识
  final File image;         // 图片文件
  final int index;          // 显示序号
  String number;            // 编号值
  bool hasAiNumber;         // 是否有AI识别的编号

  NumberItem({
    required this.id,
    required this.image,
    required this.index,
    this.number = '',
    this.hasAiNumber = false,
  });
}

/// 操作卡片组件 - 包含图片选择、搜索、编号输入等功能
class ActionCard extends StatelessWidget {
  /// 相机按钮回调
  final VoidCallback onCameraTap;
  /// 相册按钮回调
  final VoidCallback onGalleryTap;
  /// 搜索按钮回调
  final VoidCallback onSearchTap;
  /// 编号项列表
  final List<NumberItem> numberItems;
  /// 当前页码
  final int currentPage;
  /// 总页数
  final int totalPages;
  /// 每页显示数量
  final int itemsPerPage;
  /// 编号变化回调
  final ValueChanged<int> onNumberChange;
  /// 删除图片回调
  final ValueChanged<int> onDeleteTap;
  /// 上一页回调
  final VoidCallback? onPreviousPage;
  /// 下一页回调
  final VoidCallback? onNextPage;
  /// 保存回调
  final VoidCallback onSave;
  /// 是否正在保存
  final bool isSaving;
  /// 是否正在分析
  final bool isAnalyzing;

  const ActionCard({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onSearchTap,
    required this.numberItems,
    required this.currentPage,
    required this.totalPages,
    this.itemsPerPage = 5,
    required this.onNumberChange,
    required this.onDeleteTap,
    this.onPreviousPage,
    this.onNextPage,
    required this.onSave,
    this.isSaving = false,
    this.isAnalyzing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 第一行：相机和相册按钮
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.camera_alt_outlined,
                    label: '拍照',
                    onTap: onCameraTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.photo_library_outlined,
                    label: '相册',
                    onTap: onGalleryTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 搜索按钮
            _buildSearchButton(context),
            // 编号区域（有图片时显示）
            if (numberItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNumberSection(context, isDark),
            ],
          ],
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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

  /// 搜索按钮（渐变样式）
  Widget _buildSearchButton(BuildContext context) {
    return InkWell(
      onTap: onSearchTap,
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '搜索已归档',
              style: TextStyle(
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

  /// 编号区域
  Widget _buildNumberSection(BuildContext context, bool isDark) {
    // 计算当前页的编号列表
    final int startIndex = currentPage * itemsPerPage;
    final int endIndex = (startIndex + itemsPerPage).clamp(0, numberItems.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        _buildNumberHeader(context, startIndex, endIndex),
        const SizedBox(height: 12),

        // 编号列表容器
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
                return _buildNumberItem(
                  context,
                  numberItems[actualIndex],
                  isDark,
                  index == endIndex - startIndex - 1,
                );
              }),

              // 分页按钮
              if (numberItems.length > itemsPerPage)
                _buildPaginationButtons(context, isDark),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 保存按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (isAnalyzing || isSaving) ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              disabledBackgroundColor: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 8),
                      Text('保存所有图片'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// 编号区域标题行
  Widget _buildNumberHeader(BuildContext context, int startIndex, int endIndex) {
    return Row(
      children: [
        const Icon(Icons.tag_outlined, size: 18),
        const SizedBox(width: 6),
        Text(
          '图纸编号',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        // 页码信息
        if (numberItems.length > itemsPerPage)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '第 ${currentPage + 1}/$totalPages 页',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        // 图片数量
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${numberItems.length} 张',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// 单个编号输入项
  Widget _buildNumberItem(BuildContext context, NumberItem item, bool isDark, bool isLast) {
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
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 20,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 序号
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#${item.index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 编号输入框
          Expanded(
            child: TextField(
              controller: TextEditingController(text: item.number),
              decoration: InputDecoration(
                hintText: '输入图纸编号',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
              onChanged: (value) => onNumberChange(item.index),
              onSubmitted: (value) {
                item.number = value;
              },
            ),
          ),

          // AI识别标识
          if (item.hasAiNumber)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

          // 删除按钮
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => onDeleteTap(item.index),
            tooltip: '删除',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 分页按钮
  Widget _buildPaginationButtons(BuildContext context, bool isDark) {
    final isPrevDisabled = onPreviousPage == null;
    final isNextDisabled = onNextPage == null;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onPreviousPage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(
                  color: isPrevDisabled
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                '上一页',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isPrevDisabled
                      ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: onNextPage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(
                  color: isNextDisabled
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                '下一页',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isNextDisabled
                      ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
