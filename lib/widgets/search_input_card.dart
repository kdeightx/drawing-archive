import 'package:flutter/material.dart';

/// 搜索输入框卡片组件 - 包含搜索输入框和搜索按钮
class SearchInputCard extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSearch;
  final ValueChanged<String>? onSubmitted;

  const SearchInputCard({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
    this.onSubmitted,
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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
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
                onSubmitted: onSubmitted ?? (_) => onSearch(),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
