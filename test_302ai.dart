import 'dart:convert';
import 'package:http/http.dart' as http;

/// 测试 302.AI API 配置
Future<void> test302AI() async {
  const baseUrl = 'https://api.302.ai/v1';
  const apiKey = 'sk-7XcEMXt8V4QX8nA8RHTeUSIwXVJZ5P8ZCkjID4fZHujhUlyA';
  const modelName = 'gemini-3-flash-preview';

  print('🧪 测试 302.AI API 配置');
  print('========================');
  print('Base URL: $baseUrl');
  print('Model Name: $modelName');
  print('API Key: ${apiKey.substring(0, 10)}...');
  print('');

  try {
    // 构建请求 URL
    final uri = Uri.parse('$baseUrl/chat/completions');
    print('📍 请求 URL: $uri');

    // 构建请求体（优化：使用最短消息 + 限制返回 token 数量）
    final requestBody = {
      'model': modelName,
      'stream': false,
      'max_tokens': 10, // 限制返回的 token 数量，减少消耗
      'messages': [
        {
          'role': 'user',
          'content': 'Hi', // 使用最简短的测试消息
        }
      ],
    };
    print('📦 请求体: ${jsonEncode(requestBody)}');
    print('');

    // 发送请求
    print('🌐 发送 HTTP POST 请求...');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('❌ 连接超时');
      },
    );

    print('📡 响应状态码: ${response.statusCode}');
    print('📄 响应体: ${response.body}');
    print('');

    // 检查响应
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices']?[0]?['message']?['content'];
      print('✅ 测试成功！');
      print('AI 响应: $content');
    } else {
      print('❌ 测试失败！');
      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['error']?['message'] ?? '未知错误';
      print('错误信息: $errorMsg');
    }
  } catch (e) {
    print('❌ 异常: $e');
  }
}
