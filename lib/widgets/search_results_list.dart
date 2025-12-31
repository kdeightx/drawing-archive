import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/drawing_service.dart';

/// 搜索结果列表组件 - 显示搜索到的图纸列表
class SearchResultsList extends StatelessWidget {
  final List<DrawingEntry> results;
  final bool isLoading;
  final VoidCallback? onResultTap;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.isLoading,
    this.onResultTap,
  });

  /// 格式化日期显示
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '未找到相关图纸',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ResultCard(
            item: item,
            onTap: onResultTap,
            formatDate: _formatDate,
          ),
        );
      },
    );
  }
}

/// 单个搜索结果卡片组件
class _ResultCard extends StatelessWidget {
  final DrawingEntry item;
  final VoidCallback? onTap;
  final String Function(DateTime) formatDate;

  const _ResultCard({
    required this.item,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图纸图标
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

              // 图纸信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 编号
                    Text(
                      item.number,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),

                    // 日期
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(item.date),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 状态标签
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

              // 箭头图标
              Icon(
                Icons.chevron_right_outlined,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
