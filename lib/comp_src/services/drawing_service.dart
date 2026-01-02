import 'dart:io' as io;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 图片来源枚举
enum ImageSource { camera, gallery }

/// 图纸服务 - 核心业务逻辑层
///
/// 负责处理与图纸相关的所有业务逻辑
class DrawingService {
  final image_picker.ImagePicker _imagePicker = image_picker.ImagePicker();

  /// 存储发送给 AI 的图片的文件夹
  io.Directory? _aiImagesDirectory;

  /// 获取 AI 图片存储目录
  io.Directory? get aiImagesDirectory => _aiImagesDirectory;

  /// 初始化服务 - 检查并创建存储文件夹
  /// 返回 true 表示初始化成功，false 表示需要用户授权
  Future<bool> initialize() async {
    if (kDebugMode) {
      print('DrawingService: 初始化中...');
    }

    try {
      // Android 11+ 需要请求 MANAGE_EXTERNAL_STORAGE 权限
      if (io.Platform.isAndroid) {
        final manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          if (kDebugMode) {
            print('需要请求管理外部存储权限...');
          }
          final result = await Permission.manageExternalStorage.request();

          // 权限被拒绝或永久拒绝，尝试打开设置页面
          if (!result.isGranted) {
            debugPrint('✗ 管理外部存储权限被拒绝');

            // 尝试打开应用设置页面
            final opened = await openAppSettings();
            if (opened) {
              debugPrint('已打开应用设置页面，请授予"管理所有文件"权限');
            }
            return false;
          }
          if (kDebugMode) {
            print('✓ 管理外部存储权限已授予');
          }
        }
      }

      // 直接使用外部存储根目录，与 Download、Documents 等系统文件夹同级
      // 路径格式：/storage/emulated/0/DrawingScanner/
      final folderPath = '/storage/emulated/0/DrawingScanner';
      final folder = io.Directory(folderPath);

      if (kDebugMode) {
        print('准备创建/检查文件夹: $folderPath');
      }

      // 检查文件夹是否存在，不存在则创建
      if (!await folder.exists()) {
        if (kDebugMode) {
          print('文件夹不存在，正在创建...');
        }
        await folder.create(recursive: true);
        debugPrint('✓ 已创建 AI 图片存储文件夹: $folderPath');
      } else {
        if (kDebugMode) {
          print('✓ AI 图片存储文件夹已存在: $folderPath');
        }
      }

      _aiImagesDirectory = folder;

      // 列出文件夹中的文件（如果有）
      if (_aiImagesDirectory != null && kDebugMode) {
        final files = _aiImagesDirectory!.listSync();
        print('文件夹中共有 ${files.length} 个文件');
      }

      // 清理上次使用时可能残留的临时图片
      await clearAllTempImages();

      return true;
    } catch (e) {
      debugPrint('✗ 初始化存储文件夹失败: $e');
      return false;
    }
  }

  /// 选择图片（从相机或相册）- 单选
  Future<io.File?> pickImage(ImageSource source) async {
    // 1. 先请求权限
    final hasPermission = await _requestPermission(source);
    if (!hasPermission) {
      debugPrint('权限被拒绝');
      return null;
    }

    // 2. 权限已授予，调用 image_picker
    try {
      final imagePickerSource = source == ImageSource.camera
          ? image_picker.ImageSource.camera
          : image_picker.ImageSource.gallery;

      final image_picker.XFile? pickedFile = await _imagePicker.pickImage(
        source: imagePickerSource,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('用户取消选择图片');
        return null;
      }

      debugPrint('图片来源: ${source == ImageSource.camera ? "相机" : "相册"}, 路径: ${pickedFile.path}');
      return io.File(pickedFile.path);
    } catch (e) {
      debugPrint('选择图片失败: $e');
      return null;
    }
  }

  /// 多选图片（仅相册）
  Future<List<io.File>> pickMultipleImages() async {
    // 1. 请求相册权限
    final hasPermission = await _requestPermission(ImageSource.gallery);
    if (!hasPermission) {
      debugPrint('权限被拒绝');
      return [];
    }

    // 2. 调用多选接口
    try {
      final List<image_picker.XFile> pickedFiles = await _imagePicker.pickMultipleMedia();

      if (pickedFiles.isEmpty) {
        debugPrint('用户取消选择图片');
        return [];
      }

      final List<io.File> files = pickedFiles.map((xFile) => io.File(xFile.path)).toList();
      debugPrint('多选图片数量: ${files.length}');
      return files;
    } catch (e) {
      debugPrint('多选图片失败: $e');
      return [];
    }
  }

  /// 请求相应的权限
  Future<bool> _requestPermission(ImageSource source) async {
    late Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // 相册权限（根据平台选择）
      if (io.Platform.isAndroid) {
        // Android 13+ 使用 photos
        // Android 12 及以下 使用 storage
        permission = Permission.photos;
      } else {
        // iOS 使用 photos
        permission = Permission.photos;
      }
    }

    // 检查权限状态
    final status = await permission.status;

    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.limited:
      case PermissionStatus.restricted:
        // 请求权限
        final result = await permission.request();
        return result.isGranted;
      case PermissionStatus.permanentlyDenied:
        debugPrint('权限被永久拒绝，请到设置中开启');
        return false;
      case PermissionStatus.provisional:
        return true;
    }
    // ignore: dead_code
    return false;
  }

  /// 复制图片到临时文件夹
  ///
  /// 将图片复制到 DrawingScanner/AI_ 文件夹
  /// 返回复制后的临时文件，可用于后续删除
  Future<io.File> copyImageToTempFolder(io.File image) async {
    if (_aiImagesDirectory == null) {
      throw Exception('存储文件夹未初始化');
    }

    try {
      final fileName = 'AI_${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final tempPath = '${_aiImagesDirectory!.path}/$fileName';
      await image.copy(tempPath);
      final tempFile = io.File(tempPath);
      debugPrint('✓ 已复制图片到临时文件夹: $fileName');
      return tempFile;
    } catch (e) {
      debugPrint('复制图片失败: $e');
      rethrow;
    }
  }

  /// 分析图片，识别图纸编号
  ///
  /// [image] 要分析的图片文件
  /// [shouldCopy] 是否复制到临时文件夹（默认 true）
  Future<String> analyzeImage(io.File image, {bool shouldCopy = true}) async {
    // 将图片复制到 AI 图片存储文件夹
    if (shouldCopy && _aiImagesDirectory != null) {
      try {
        final fileName = 'AI_${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        await image.copy('${_aiImagesDirectory!.path}/$fileName');
        debugPrint('已复制图片到存储文件夹: $fileName');
      } catch (e) {
        debugPrint('复制图片失败: $e');
      }
    }

    // 调用真实 AI API 识别图纸编号
    return await _recognizeDrawingNumberWithAI(image);
  }

  /// 使用真实 AI API 识别图纸编号
  ///
  /// 从 SharedPreferences 加载 API 配置，调用 AI 识别图纸编号
  Future<String> _recognizeDrawingNumberWithAI(io.File image) async {
    try {
      // 加载 API 配置
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('ai_api_base_url') ?? 'https://api.302.ai/v1';
      final apiKey = prefs.getString('ai_api_key') ?? '';
      final modelName = prefs.getString('ai_model_name') ?? 'gemini-1.5-flash-exp';

      // 检查配置是否有效
      if (apiKey.isEmpty) {
        throw Exception('API Key 未配置，请先在设置中配置 AI API');
      }

      // 读取图片并转换为 Base64
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType = _getImageMimeType(image.path);

      // 构建 data URI
      final dataUri = 'data:$mimeType;base64,$base64Image';

      // 构建请求 URL
      final Uri uri = Uri.parse('$baseUrl/chat/completions');

      // 构建请求体（多模态格式）
      final Map<String, dynamic> requestBody = {
        'model': modelName,
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
                  'url': dataUri,
                },
              },
            ],
          },
        ],
      };

      // 发送请求
      debugPrint('正在调用 AI API 识别图纸编号...');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
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
        debugPrint('✓ AI 识别结果: $cleanResult');

        // 检查是否是有效的图纸编号格式
        final numberPattern = RegExp(r'^\d+\.\d+-\d+$');
        if (!numberPattern.hasMatch(cleanResult)) {
          throw Exception('AI 识别结果格式不正确: "$cleanResult"，期望格式：数字.数字-数字（如：1.0101-1100）');
        }

        return cleanResult;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? '未知错误';
        debugPrint('✗ AI 识别失败 (${response.statusCode}): $errorMsg');
        throw Exception('AI 识别失败 (${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      debugPrint('✗ AI 识别失败: $e');

      // 检查是否是网络相关异常
      final errorMsg = e.toString();
      if (errorMsg.contains('SocketException') ||
          errorMsg.contains('HttpException') ||
          errorMsg.contains('Network') ||
          errorMsg.contains('Connection') ||
          errorMsg.contains('Timeout') ||
          errorMsg.contains('Failed host lookup') ||
          e is http.ClientException) {
        throw Exception('网络连接失败，请检查网络连接或 API 配置');
      }

      rethrow; // 直接抛出异常，不再使用模拟数据
    }
  }

  /// 根据文件路径获取 MIME 类型
  String _getImageMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// 保存图纸归档记录
  ///
  /// 将图片重命名为图纸编号并保存到 DrawingScanner 文件夹
  /// 如果同名文件已存在，则直接覆盖
  /// [image] 要保存的图片文件
  /// [finalNumber] 识别出的图纸编号（作为文件名）
  Future<void> saveEntry(io.File image, String finalNumber) async {
    if (_aiImagesDirectory == null) {
      throw Exception('存储文件夹未初始化');
    }

    try {
      // 获取文件扩展名
      final fileExtension = image.path.split('.').last.toLowerCase();
      final newFileName = '$finalNumber.$fileExtension';
      final newPath = '${_aiImagesDirectory!.path}/$newFileName';

      // 直接复制并重命名文件（如果文件已存在会自动覆盖）
      await image.copy(newPath);
      debugPrint('✓ 已保存图纸: $newFileName → $newPath');
    } catch (e) {
      debugPrint('✗ 保存失败: $e');
      rethrow;
    }
  }

  /// 删除单个临时图片文件
  ///
  /// 只删除 AI_ 开头的临时文件，不删除已归档的文件
  /// 如果文件不存在或不是临时文件，则忽略
  Future<void> deleteTempImage(io.File image) async {
    try {
      // 检查文件是否存在
      if (!await image.exists()) {
        debugPrint('文件不存在，跳过删除: ${image.path}');
        return;
      }

      // 检查是否是临时文件（AI_ 开头）
      final fileName = image.path.split('/').last;
      if (!fileName.startsWith('AI_')) {
        debugPrint('文件不是临时文件，跳过删除: $fileName');
        return;
      }

      // 删除临时文件
      await image.delete();
      debugPrint('✓ 已删除临时文件: $fileName');
    } catch (e) {
      debugPrint('删除临时文件失败 ${image.path}: $e');
      rethrow;
    }
  }

  /// 清理所有未保存的临时图片
  ///
  /// 扫描 DrawingScanner/ 目录，删除所有 AI_ 开头的临时文件
  /// 保留所有已重命名的图片（不以 AI_ 开头的文件）
  Future<void> clearAllTempImages() async {
    if (_aiImagesDirectory == null) {
      debugPrint('存储文件夹未初始化，无法清理临时文件');
      return;
    }

    try {
      // 列出目录中的所有文件
      final files = _aiImagesDirectory!.listSync();

      // 筛选出所有临时文件（AI_ 开头）
      final tempFiles = files.whereType<io.File>().where((file) {
        final fileName = file.path.split('/').last;
        return fileName.startsWith('AI_');
      }).toList();

      if (tempFiles.isEmpty) {
        debugPrint('✓ 没有需要清理的临时文件');
        return;
      }

      // 删除所有临时文件
      int deletedCount = 0;
      for (var tempFile in tempFiles) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint('✓ 已删除临时文件: ${tempFile.path}');
            deletedCount++;
          }
        } catch (e) {
          debugPrint('删除临时文件失败 ${tempFile.path}: $e');
        }
      }

      debugPrint('✓ 共清理了 $deletedCount 个临时文件');

      // 显示清理后文件夹中还剩多少个文件
      final remainingFiles = _aiImagesDirectory!.listSync();
      debugPrint('✓ 清理后文件夹中共有 ${remainingFiles.length} 个文件');
    } catch (e) {
      debugPrint('清理临时文件失败: $e');
    }
  }

  /// 搜索已归档图纸
  Future<List<DrawingEntry>> searchDrawings({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
    bool ascending = true,
  }) async {
    if (_aiImagesDirectory == null) {
      debugPrint('存储文件夹未初始化');
      return [];
    }

    try {
      debugPrint('🔍 开始搜索已归档图纸...');
      debugPrint('  关键词: ${keyword ?? "无"}');
      debugPrint('  日期范围: $startDate ~ $endDate');
      debugPrint('  排序: ${ascending ? "正序" : "倒序"}');

      // 1. 列出文件夹中的所有文件
      final files = _aiImagesDirectory!.listSync();
      debugPrint('  文件夹中共有 ${files.length} 个文件');

      // 2. 筛选出已归档的文件（不包括 AI_ 开头的临时文件）
      // 并且只保留图片文件（.jpg, .jpeg, .png）
      final archivedFiles = files.whereType<io.File>().where((file) {
        final fileName = file.path.split('/').last;
        final isNotTemp = !fileName.startsWith('AI_');

        // 检查是否是图片文件
        final extension = fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
            : '';
        final isImage = ['jpg', 'jpeg', 'png'].contains(extension);

        return isNotTemp && isImage;
      }).toList();

      debugPrint('  已归档文件数量: ${archivedFiles.length}');

      // 3. 构建 DrawingEntry 列表
      List<DrawingEntry> results = [];

      for (var file in archivedFiles) {
        try {
          // 获取文件名（不含扩展名）作为图纸编号
          final fileName = file.path.split('/').last;
          final number = fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;

          // 检查图纸编号是否为空
          if (number.trim().isEmpty) {
            debugPrint('  ⚠️ 发现空文件名的异常文件，正在删除: $fileName');
            try {
              await file.delete();
              debugPrint('  ✓ 已删除异常文件: $fileName');
            } catch (e) {
              debugPrint('  ✗ 删除异常文件失败: $e');
            }
            continue;
          }

          // 获取文件修改时间作为归档日期
          final stat = await file.stat();
          final modifiedDate = stat.modified;

          // 关键词过滤
          if (keyword != null && keyword.isNotEmpty) {
            if (!number.toLowerCase().contains(keyword.toLowerCase())) {
              continue; // 跳过不匹配的文件
            }
          }

          // 日期范围过滤
          if (startDate != null && modifiedDate.isBefore(startDate)) {
            final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
            if (modifiedDate.isBefore(startOfDay)) {
              continue; // 在开始日期之前
            }
          }

          if (endDate != null) {
            final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
            if (modifiedDate.isAfter(endOfDay)) {
              continue; // 在结束日期之后
            }
          }

          // 添加到结果列表
          results.add(DrawingEntry(
            number: number,
            date: modifiedDate,
            status: '已归档',
            filePath: file.path,
          ));

          debugPrint('  ✓ 找到匹配: $number (${modifiedDate.toString().substring(0, 19)})');
        } catch (e) {
          debugPrint('  ✗ 处理文件失败: ${file.path}, 错误: $e');
          continue;
        }
      }

      debugPrint('  搜索完成，找到 ${results.length} 个匹配结果');

      // 4. 排序
      results.sort((a, b) => ascending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));

      return results;
    } catch (e) {
      debugPrint('✗ 搜索失败: $e');
      return [];
    }
  }

}

/// 图纸条目数据模型
class DrawingEntry {
  final String number;
  final DateTime date;
  final String status;
  final String filePath;

  DrawingEntry({
    required this.number,
    required this.date,
    required this.status,
    required this.filePath,
  });
}
