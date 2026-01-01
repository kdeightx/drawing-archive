import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../view_models/ai_api_config_view_model.dart';

/// AI API 配置页面 - 精密工业风格
///
/// 使用 MVVM 架构，业务逻辑在 AiApiConfigViewModel 中
class AiApiConfigPage extends StatelessWidget {
  const AiApiConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiApiConfigViewModel(),
      child: const _AiApiConfigView(),
    );
  }
}

class _AiApiConfigView extends StatefulWidget {
  const _AiApiConfigView();

  @override
  State<_AiApiConfigView> createState() => _AiApiConfigViewState();
}

class _AiApiConfigViewState extends State<_AiApiConfigView> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 AI API 配置页面 initState');

    // 在第一帧渲染后异步加载配置
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('📋 PostFrameCallback 开始执行');
      final viewModel = context.read<AiApiConfigViewModel>();

      // 等待配置加载完成
      await viewModel.init();

      // 更新输入框的值
      if (mounted) {
        debugPrint('✏️ 更新输入框的值');
        _baseUrlController.text = viewModel.baseUrl;
        _apiKeyController.text = viewModel.apiKey;
        _modelNameController.text = viewModel.modelName;
        debugPrint('  已将 ViewModel 的值同步到输入框');
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  void _handleSave(AiApiConfigViewModel viewModel) async {
    final l10n = AppLocalizations.of(context)!;

    debugPrint('💾 保存按钮点击');
    debugPrint('  输入框的值:');
    debugPrint('    Base URL: ${_baseUrlController.text}');
    debugPrint('    API Key: ${_apiKeyController.text.isNotEmpty ? "已填写 (${_apiKeyController.text.length} 字符)" : "空"}');
    debugPrint('    Model Name: ${_modelNameController.text}');

    // 更新 ViewModel 中的值
    viewModel.updateBaseUrl(_baseUrlController.text);
    viewModel.updateApiKey(_apiKeyController.text);
    viewModel.updateModelName(_modelNameController.text);

    debugPrint('  ViewModel 的值:');
    debugPrint('    Base URL: ${viewModel.baseUrl}');
    debugPrint('    API Key: ${viewModel.apiKey.isNotEmpty ? "已填写 (${viewModel.apiKey.length} 字符)" : "空"}');
    debugPrint('    Model Name: ${viewModel.modelName}');

    // 验证表单
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('✅ 表单验证通过');
      // 保存配置
      final success = await viewModel.saveConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(success ? l10n.configSaved : viewModel.errorMessage ?? '保存失败'),
              ],
            ),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        if (success) {
          Navigator.pop(context);
        }
      }
    } else {
      debugPrint('❌ 表单验证失败');
    }
  }

  void _handleTest(AiApiConfigViewModel viewModel) async {
    // 更新 ViewModel 中的值
    viewModel.updateBaseUrl(_baseUrlController.text);
    viewModel.updateApiKey(_apiKeyController.text);
    viewModel.updateModelName(_modelNameController.text);

    // 验证表单
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // 清除之前的错误和结果
    viewModel.clearError();

    // 测试连接
    final success = await viewModel.testConnection();

    // 显示测试结果（在屏幕上方）
    if (mounted) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final double topPadding = mediaQuery.padding.top;
      final double appBarHeight = kToolbarHeight;
      final double topPosition = topPadding + appBarHeight + 8;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? '连接成功！'
                      : (viewModel.errorMessage ?? '连接失败'),
                ),
              ),
            ],
          ),
          backgroundColor: success
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: mediaQuery.size.height - topPosition - 60,
          ),
          duration: Duration(seconds: success ? 3 : 5),
        ),
      );
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
            child: Consumer<AiApiConfigViewModel>(
              builder: (context, viewModel, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 说明卡片
                        _buildInfoCard(l10n),
                        const SizedBox(height: 20),

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

                        // 操作按钮组
                        _buildActionButtons(l10n, viewModel),
                      ],
                    ),
                  ),
                );
              },
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

  Widget _buildActionButtons(AppLocalizations l10n, AiApiConfigViewModel viewModel) {
    return Row(
      children: [
        // 测试连接按钮
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: viewModel.isTesting ? null : () => _handleTest(viewModel),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: viewModel.isTesting
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: viewModel.isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_find_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('测试连接'),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 保存按钮
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: viewModel.isTesting ? null : () => _handleSave(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                disabledBackgroundColor: _isDarkMode ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 18),
                  SizedBox(width: 8),
                  Text('保存'),
                ],
              ),
            ),
          ),
        ),
      ],
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
