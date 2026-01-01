import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AI API 配置 ViewModel
///
/// 负责管理 AI API 配置的状态和业务逻辑
class AiApiConfigViewModel extends ChangeNotifier {
  // ========== 默认值 ==========

  /// 默认 Base URL
  static const String defaultBaseUrl = 'https://api.302.ai/v1';

  /// 默认模型名称
  static const String defaultModelName = 'gemini-1.5-flash-exp';

  /// SharedPreferences 键名
  static const String _keyBaseUrl = 'ai_api_base_url';
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyModelName = 'ai_model_name';

  // ========== 状态变量 ==========

  /// Base URL
  String _baseUrl = defaultBaseUrl;
  String get baseUrl => _baseUrl;

  /// API Key
  String _apiKey = '';
  String get apiKey => _apiKey;

  /// 模型名称
  String _modelName = defaultModelName;
  String get modelName => _modelName;

  /// 是否正在测试连接
  bool _isTesting = false;
  bool get isTesting => _isTesting;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 测试连接结果
  String? _testResult;
  String? get testResult => _testResult;

  /// 配置是否有效（所有字段都已填写）
  bool get isConfigValid {
    return _baseUrl.trim().isNotEmpty &&
        _apiKey.trim().isNotEmpty &&
        _modelName.trim().isNotEmpty;
  }

  // ========== 构造函数 ==========

  AiApiConfigViewModel();

  // ========== 公共方法 ==========

  /// 初始化配置（在页面创建后调用）
  Future<void> init() async {
    await _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      debugPrint('📖 开始加载配置...');
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
      _apiKey = prefs.getString(_keyApiKey) ?? '';
      _modelName = prefs.getString(_keyModelName) ?? defaultModelName;
      debugPrint('  Base URL: $_baseUrl');
      debugPrint('  API Key: ${_apiKey.isNotEmpty ? "已填写 (${_apiKey.length} 字符)" : "空"}');
      debugPrint('  Model Name: $_modelName');
      debugPrint('✅ 配置加载完成');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载配置失败: $e');
    }
  }

  /// 保存配置
  Future<bool> saveConfig() async {
    debugPrint('🔧 开始保存配置...');
    debugPrint('  Base URL: $_baseUrl');
    debugPrint('  API Key: ${_apiKey.isNotEmpty ? "已填写 (${_apiKey.length} 字符)" : "空"}');
    debugPrint('  Model Name: $_modelName');

    if (!isConfigValid) {
      _errorMessage = '请填写所有必填字段';
      debugPrint('❌ 验证失败: $_errorMessage');
      notifyListeners();
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, _baseUrl.trim());
      await prefs.setString(_keyApiKey, _apiKey.trim());
      await prefs.setString(_keyModelName, _modelName.trim());
      _errorMessage = null;
      debugPrint('✅ 配置保存成功');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '保存配置失败: $e';
      debugPrint('❌ 保存失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 测试 API 连接
  Future<bool> testConnection() async {
    debugPrint('🧪 开始测试 API 连接...');
    debugPrint('  Base URL: $_baseUrl');
    debugPrint('  API Key: ${_apiKey.isNotEmpty ? "已填写 (${_apiKey.length} 字符)" : "空"}');
    debugPrint('  Model Name: $_modelName');

    if (!isConfigValid) {
      _errorMessage = '请先填写所有必填字段';
      debugPrint('❌ 验证失败: $_errorMessage');
      notifyListeners();
      return false;
    }

    _isTesting = true;
    _testResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      // 构建请求 URL
      final Uri uri = Uri.parse('$_baseUrl/chat/completions');
      debugPrint('📍 请求 URL: $uri');

      // 构建请求体（优化：使用最短消息 + 限制返回 token 数量）
      final Map<String, dynamic> requestBody = {
        'model': _modelName,
        'stream': false,
        'max_tokens': 10, // 限制返回的 token 数量，减少消耗
        'messages': [
          {
            'role': 'user',
            'content': 'Hi', // 使用最简短的测试消息
          }
        ],
      };
      debugPrint('📦 请求体: ${jsonEncode(requestBody)}');

      // 发送请求
      debugPrint('🌐 发送 HTTP POST 请求...');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${_apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ 请求超时');
          throw Exception('连接超时，请检查网络或 Base URL');
        },
      );

      debugPrint('📡 响应状态码: ${response.statusCode}');
      debugPrint('📄 响应体: ${response.body}');

      // 检查响应
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? content = responseData['choices']?.first['message']?['content'];

        _testResult = '连接成功！\nAI 响应: ${content ?? "无内容"}';
        _errorMessage = null;
        _isTesting = false;
        debugPrint('✅ 测试连接成功');
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? '未知错误';

        _errorMessage = '连接失败 (${response.statusCode}): $errorMsg';
        _testResult = null;
        _isTesting = false;
        debugPrint('❌ 测试连接失败: $_errorMessage');
        notifyListeners();
        return false;
      }
    } on http.ClientException catch (e) {
      _errorMessage = '网络错误: ${e.message}';
      _testResult = null;
      _isTesting = false;
      debugPrint('❌ 网络异常: $e');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = '测试失败: $e';
      _testResult = null;
      _isTesting = false;
      debugPrint('❌ 测试异常: $e');
      notifyListeners();
      return false;
    }
  }

  /// 调用 AI API 识别图纸编号
  ///
  /// [imageBase64] 图片的 Base64 编码（带 data URI 前缀）
  /// 返回识别出的图纸编号
  Future<String> recognizeDrawingNumber(String imageBase64) async {
    if (!isConfigValid) {
      throw Exception('AI API 配置无效，请先配置');
    }

    try {
      // 构建请求 URL
      final Uri uri = Uri.parse('$_baseUrl/chat/completions');

      // 构建请求体（多模态格式）
      final Map<String, dynamic> requestBody = {
        'model': _modelName,
        'stream': false,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '''请识别这张机械图纸中的图纸编号。
要求：
1. 只返回图纸编号，不要返回任何其他文字
2. 图纸编号格式通常为：数字.数字-数字（如：1.0101-1100）
3. 如果图片中没有清晰的图纸编号，请返回 "未识别"
4. 不要添加任何解释或说明''',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': imageBase64,
                },
              },
            ],
          },
        ],
      };

      // 发送请求
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${_apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('AI 识别超时');
        },
      );

      // 检查响应
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? content = responseData['choices']?.first['message']?['content'];

        if (content == null || content.isEmpty) {
          throw Exception('AI 未返回识别结果');
        }

        // 清理结果（去除可能的换行和多余空格）
        final cleanResult = content.trim().replaceAll('\n', '').replaceAll('\r', '');

        // 检查是否是有效的图纸编号格式
        final numberPattern = RegExp(r'^\d+\.\d+-\d+$');
        if (!numberPattern.hasMatch(cleanResult)) {
          throw Exception('AI 识别结果格式不正确: $cleanResult');
        }

        return cleanResult;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? '未知错误';
        throw Exception('AI 识别失败 (${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      debugPrint('AI 识别失败: $e');
      rethrow;
    }
  }

  /// 更新 Base URL
  void updateBaseUrl(String value) {
    _baseUrl = value;
    notifyListeners();
  }

  /// 更新 API Key
  void updateApiKey(String value) {
    _apiKey = value;
    notifyListeners();
  }

  /// 更新模型名称
  void updateModelName(String value) {
    _modelName = value;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    _testResult = null;
    notifyListeners();
  }

  /// 重置为默认值
  Future<void> resetToDefaults() async {
    _baseUrl = defaultBaseUrl;
    _apiKey = '';
    _modelName = defaultModelName;
    _errorMessage = null;
    _testResult = null;

    // 清除持久化配置
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyModelName);

    notifyListeners();
  }
}
