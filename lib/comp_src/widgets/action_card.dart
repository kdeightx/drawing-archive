import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/drawing_scanner_view_model.dart';
import 'action_buttons.dart';
import 'full_screen_image_viewer.dart';

/// 编号项数据模型
class NumberItem {
  final String id;          // 唯一标识
  final File image;         // 图片文件
  final int index;          // 显示序号
  String number;            // 编号值
  bool hasAiNumber;         // 是否有AI识别的编号
  bool recognitionFailed;   // 是否识别失败

  NumberItem({
    required this.id,
    required this.image,
    required this.index,
    this.number = '',
    this.hasAiNumber = false,
    this.recognitionFailed = false,
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
  /// 上传识别回调
  final VoidCallback? onUpload;
  /// 清空列表回调
  final VoidCallback? onClearAll;
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
    this.onUpload,
    this.onClearAll,
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
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
          width: isDark ? 2.0 : 1.5,
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
                    isEnabled: !isAnalyzing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.photo_library_outlined,
                    label: '相册',
                    onTap: onGalleryTap,
                    isEnabled: !isAnalyzing,
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
    bool isEnabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isEnabled
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
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
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
              width: isDark ? 1.5 : 1,
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

        // 操作按钮行（清空 + 上传识别 + 保存）
        ActionButtons(
          onClearAll: onClearAll,
          onUpload: onUpload,
          onSave: onSave,
          isAnalyzing: isAnalyzing,
          isSaving: isSaving,
          isListEmpty: numberItems.isEmpty,
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
    final viewModel = context.read<DrawingScannerViewModel>();

    // 判断输入框和删除按钮是否应该启用：
    // 在上传识别流程中（从发送中到已完成）禁用
    // 其他时候（未点击上传识别、已完成之后）启用
    final bool isEnabled = !viewModel.isAnalyzing;
    final bool canDelete = !viewModel.isAnalyzing;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: isLast ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 删除按钮
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: canDelete ? () => onDeleteTap(item.index) : null, // 上传识别流程中禁用
            tooltip: '删除',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: !canDelete
                ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                : null,
          ),
          const SizedBox(width: 8),

          // 图片缩略图
          InkWell(
            onTap: () => _showFullScreenPreview(context, item.index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
                  width: isDark ? 1.5 : 1,
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
              enabled: isEnabled, // 上传识别流程中禁用
              onTapOutside: (_) {
                // 点击输入框外部时取消焦点
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                hintText: item.recognitionFailed ? '识别失败' : '输入图纸编号',
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    width: 1,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: isEnabled
                    ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
              onChanged: (value) {
                item.number = value;
                onNumberChange(item.index);
              },
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

  /// 显示全屏预览
  void _showFullScreenPreview(BuildContext context, int index) {
    final viewModel = context.read<DrawingScannerViewModel>();
    viewModel.setCurrentImageIndex(index);
    viewModel.resetRotation();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: viewModel,
          child: const FullScreenImageViewer(),
        ),
      ),
    );
  }
}
