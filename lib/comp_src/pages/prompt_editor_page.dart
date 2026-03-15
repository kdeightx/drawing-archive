import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../view_models/ai_api_config_view_model.dart';

/// 提示词编辑页面
class PromptEditorPage extends StatefulWidget {
  final AiApiConfigViewModel viewModel;

  const PromptEditorPage({super.key, required this.viewModel});

  @override
  State<PromptEditorPage> createState() => _PromptEditorPageState();
}

class _PromptEditorPageState extends State<PromptEditorPage> {
  late TextEditingController _promptController;
  bool _hasChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _promptController.addListener(_onTextChanged);
    _loadSavedPrompt();
  }

  Future<void> _loadSavedPrompt() async {
    // 先从 SharedPreferences 加载保存的提示词
    await widget.viewModel.init();
    // 加载完成后更新文本框内容
    _promptController.text = widget.viewModel.customPrompt;
    setState(() {
      _isLoading = false;
    });
  }

  void _onTextChanged() {
    final hasChanges = _promptController.text != widget.viewModel.customPrompt;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _promptController.removeListener(_onTextChanged);
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.promptEditor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          if (_hasChanges && !_isLoading)
            TextButton(
              onPressed: _savePrompt,
              child: Text(
                l10n.save,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 说明卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.promptTips,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.promptDescription,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 提示词输入框
            Text(
              l10n.customPrompt,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _promptController,
                maxLines: 15,
                minLines: 8,
                decoration: InputDecoration(
                  hintText: l10n.promptHint,
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 重置按钮
            OutlinedButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.resetToDefault),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePrompt() async {
    // 先将用户编辑的内容同步到 ViewModel
    widget.viewModel.updateCustomPrompt(_promptController.text);
    // 然后保存
    final success = await widget.viewModel.savePrompt();
    if (success && mounted) {
      setState(() {
        _hasChanges = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.configSaved),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _resetToDefault() {
    _promptController.text = AiApiConfigViewModel.defaultPrompt;
  }
}
