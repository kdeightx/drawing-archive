import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/drawing_service.dart';

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
        const SnackBar(
          content: Text('当前功能未实现'),
          duration: Duration(seconds: 1),
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
                  child: _buildSearchCard(l10n),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterSection(l10n),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildResultsList(l10n),
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
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_outlined),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(l10n.searchTitle),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }

  Widget _buildSearchCard(AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchPlaceholder,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _performSearch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.search, color: Theme.of(context).colorScheme.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
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
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: hasFilter ? 2 : 1,
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
              '当前日期范围',
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
              '共 ${_results.length} 条结果',
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
                      side: BorderSide(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    child: const Text('清除'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('修改'),
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
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
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

  Widget _buildResultsList(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildResultCard(item, l10n),
        );
      },
    );
  }

  Widget _buildResultCard(DrawingEntry item, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.number,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.date),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.statusArchived,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_outlined,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                size: 24,
              ),
            ],
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
