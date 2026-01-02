import 'package:flutter/material.dart';
import 'dart:io' as io;

import '../../l10n/app_localizations.dart';
import '../../comp_src/services/drawing_service.dart';
import '../../comp_src/widgets/search_input_card.dart';
import '../../comp_src/widgets/search_results_list.dart';
import '../../comp_src/widgets/full_screen_image_viewer.dart';

/// 图纸搜索页面 - 精密工业风格
class DrawingSearchPage extends StatefulWidget {
  final DrawingService drawingService;

  const DrawingSearchPage({super.key, required this.drawingService});

  @override
  State<DrawingSearchPage> createState() => _DrawingSearchPageState();
}

class _DrawingSearchPageState extends State<DrawingSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAscending = true;
  DateTime? _startDate;
  DateTime? _endDate;
  List<DrawingEntry> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  /// 加载搜索结果
  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.drawingService.searchDrawings(
        keyword: _searchController.text.isNotEmpty ? _searchController.text : null,
        startDate: _startDate,
        endDate: _endDate,
        ascending: _isAscending,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 格式化日期显示
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    _loadResults();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.searchCompleted),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  /// 显示日期范围选择器
  Future<void> _showDateRangePicker() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.currentFeatureNotImplemented),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 清除日期筛选
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadResults();
  }

  /// 处理搜索结果点击
  void _handleResultTap(int index) {
    final entry = _results[index];
    final imagePath = entry.filePath;

    // 验证文件是否存在
    final file = io.File(imagePath);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件不存在: $imagePath'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 打开全屏图片查看器（独立组件）
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: _results.map((e) => e.filePath).toList(),
          imageTitles: _results.map((e) => e.number).toList(),
          initialIndex: index,
          enableRotation: true, // 搜索结果也支持旋转
        ),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchInputCard(
                    controller: _searchController,
                    hintText: l10n.searchPlaceholder,
                    onSearch: _performSearch,
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterSection(l10n),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchResultsList(
                      results: _results,
                      isLoading: _isLoading,
                      onResultTap: _handleResultTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_outlined),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(l10n.searchTitle),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  Widget _buildGridBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(isDark: isDark),
    );
  }

  Widget _buildFilterSection(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildDateRangeButton(l10n),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOrderToggle(l10n),
        ),
      ],
    );
  }

  Widget _buildDateRangeButton(AppLocalizations l10n) {
    final hasFilter = _startDate != null || _endDate != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: hasFilter ? _showDateRangeClearDialog : _showDateRangePicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: hasFilter
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFilter
                ? Theme.of(context).colorScheme.primary
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)),
            width: hasFilter ? 2 : (isDark ? 2.0 : 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.filter_alt : Icons.calendar_today_outlined,
              color: hasFilter
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF64748B),
              size: 18,
            ),
            if (!hasFilter) ...[
              const SizedBox(width: 6),
              Text(
                l10n.dateRange,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ] else ...[
              const SizedBox(width: 6),
              Text(
                _getDateRangeText(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取日期范围显示文本
  String _getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      if (_startDate!.year == _endDate!.year &&
          _startDate!.month == _endDate!.month &&
          _startDate!.day == _endDate!.day) {
        return _formatDate(_startDate);
      }
      return '${_formatDate(_startDate)} →';
    }
    return _formatDate(_startDate ?? _endDate);
  }

  /// 显示清除日期筛选对话框
  Future<void> _showDateRangeClearDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.currentDateRange,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _getDateRangeText(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.totalResults(_results.length),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearDateFilter();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    child: Text(l10n.clear),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.modify),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderToggle(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        setState(() {
          _isAscending = !_isAscending;
        });
        _loadResults();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
            width: isDark ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAscending ? Icons.arrow_upward_outlined : Icons.arrow_downward_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _isAscending ? l10n.orderAscending : l10n.orderDescending,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _GridPainter extends CustomPainter {
  final bool isDark;

  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF64748B).withValues(alpha: 0.25)
          : const Color(0xFF94A3B8).withValues(alpha: 0.25)
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
