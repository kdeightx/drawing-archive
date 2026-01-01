import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// AI API 配置页面 - 精密工业风格
class AiApiConfigPage extends StatefulWidget {
  const AiApiConfigPage({super.key});

  @override
  State<AiApiConfigPage> createState() => _AiApiConfigPageState();
}

class _AiApiConfigPageState extends State<AiApiConfigPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final l10n = AppLocalizations.of(context)!;

    // 验证表单
    if (_formKey.currentState?.validate() ?? false) {
      // 暂不持久化，仅显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.configSaved),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 说明卡片
                    _buildInfoCard(l10n),
                    const SizedBox(height: 20),

                    // API Key 输入框
                    _buildInputCard(
                      icon: Icons.key_outlined,
                      label: l10n.apiKey,
                      hint: l10n.apiKeyHint,
                      controller: _apiKeyController,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.errorApiKeyRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Base URL 输入框
                    _buildInputCard(
                      icon: Icons.link_outlined,
                      label: l10n.baseUrl,
                      hint: l10n.baseUrlHint,
                      controller: _baseUrlController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.errorBaseUrlRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 模型名称输入框
                    _buildInputCard(
                      icon: Icons.model_training_outlined,
                      label: l10n.modelName,
                      hint: l10n.modelNameHint,
                      controller: _modelNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.errorModelNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 保存按钮
                    _buildSaveButton(l10n),
                  ],
                ),
              ),
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
      title: Text(l10n.aiApiConfig),
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

  Widget _buildInfoCard(AppLocalizations l10n) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: _isDarkMode ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
          width: _isDarkMode ? 2.0 : 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.aiApiConfigDescription,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: _isDarkMode ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
          width: _isDarkMode ? 2.0 : 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
                width: _isDarkMode ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0),
                width: _isDarkMode ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor: _isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, size: 18),
            const SizedBox(width: 8),
            Text(l10n.saveConfig),
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
