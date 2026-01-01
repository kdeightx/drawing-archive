import 'package:flutter/material.dart';

/// 操作按钮组件 - 清空、上传识别、保存
///
/// 使用 Flex 布局，比例为 1:2:2
class ActionButtons extends StatelessWidget {
  /// 清空按钮回调
  final VoidCallback? onClearAll;

  /// 上传识别按钮回调
  final VoidCallback? onUpload;

  /// 保存按钮回调
  final VoidCallback? onSave;

  /// 是否正在分析
  final bool isAnalyzing;

  /// 是否正在保存
  final bool isSaving;

  /// 列表是否为空
  final bool isListEmpty;

  const ActionButtons({
    super.key,
    required this.onClearAll,
    required this.onUpload,
    required this.onSave,
    required this.isAnalyzing,
    required this.isSaving,
    required this.isListEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // 清空按钮（次要按钮）- flex: 1, icon only
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isClearDisabled ? null : onClearAll,
              style: _buildClearButtonStyle(isDark),
              child: const Icon(Icons.delete_outline, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 上传识别按钮 - flex: 2, OutlinedButton with primary color
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isUploadDisabled ? null : onUpload,
              style: _buildUploadButtonStyle(context, isDark),
              child: _buildUploadButtonContent(isDark),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 保存按钮 - flex: 2, ElevatedButton with primary color
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaveDisabled ? null : onSave,
              style: _buildSaveButtonStyle(context, isDark),
              child: _buildSaveButtonContent(),
            ),
          ),
        ),
      ],
    );
  }

  // ========== 禁用状态计算 ==========

  bool get _isClearDisabled => isAnalyzing || isSaving || isListEmpty;
  bool get _isUploadDisabled => isAnalyzing || isSaving || isListEmpty || onUpload == null;
  bool get _isSaveDisabled => isAnalyzing || isSaving;

  // ========== 按钮样式 ==========

  /// 清空按钮样式（红色警告）
  ButtonStyle _buildClearButtonStyle(bool isDark) {
    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
      side: BorderSide(
        color: _isClearDisabled
            ? (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0))
            : (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 上传识别按钮样式（主题色）
  ButtonStyle _buildUploadButtonStyle(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return OutlinedButton.styleFrom(
      foregroundColor: isAnalyzing
          ? (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0))
          : primaryColor,
      side: BorderSide(
        color: (isAnalyzing || isSaving || isListEmpty)
            ? (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0))
            : primaryColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 保存按钮样式（主题色）
  ButtonStyle _buildSaveButtonStyle(BuildContext context, bool isDark) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      disabledBackgroundColor: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // ========== 按钮内容 ==========

  /// 上传识别按钮内容（图标+文字 或 加载指示器）
  Widget _buildUploadButtonContent(bool isDark) {
    if (isAnalyzing) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          ),
        ),
      );
    }

    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 18),
        SizedBox(width: 6),
        Text('上传识别', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  /// 保存按钮内容（图标+文字 或 加载指示器）
  Widget _buildSaveButtonContent() {
    if (isSaving) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 18),
        SizedBox(width: 6),
        Text('保存图片', style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
