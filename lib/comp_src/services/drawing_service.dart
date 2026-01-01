import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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

  /// 分析图片，识别图纸编号
  Future<String> analyzeImage(io.File image) async {
    // 将图片复制到 AI 图片存储文件夹
    if (_aiImagesDirectory != null) {
      try {
        final fileName = 'AI_${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        final copiedFile = await image.copy('${_aiImagesDirectory!.path}/$fileName');
        debugPrint('已复制图片到存储文件夹: ${copiedFile.path}');
      } catch (e) {
        debugPrint('复制图片失败: $e');
      }
    }

    // TODO: 实际实现需要调用 AI/OCR 服务
    // return await ocrService.recognizeDrawingNumber(image);

    // 当前为模拟实现
    await Future.delayed(const Duration(seconds: 2));
    final random = Random();
    return '${random.nextInt(9) + 1}.${100 + random.nextInt(900)}-${1000 + random.nextInt(9000)}';
  }

  /// 保存图纸归档记录
  Future<void> saveEntry(io.File image, String finalNumber) async {
    // TODO: 实际实现需要保存到数据库/服务器
    // await database.saveDrawingEntry(image, finalNumber);

    // 当前为模拟实现
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('保存成功: $finalNumber');
  }

  /// 搜索已归档图纸
  Future<List<DrawingEntry>> searchDrawings({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
    bool ascending = true,
  }) async {
    // TODO: 实际实现需要从数据库/服务器查询
    // return await database.searchDrawings(...);

    // 当前为模拟实现
    await Future.delayed(const Duration(milliseconds: 300));
    return _getMockResults(startDate, endDate, ascending);
  }

  /// 获取模拟搜索结果
  List<DrawingEntry> _getMockResults(
    DateTime? startDate,
    DateTime? endDate,
    bool ascending,
  ) {
    List<Map<String, dynamic>> mockResults = [
      {'number': '1.0234-5678', 'date': '2024-01-15', 'status': 'statusArchived'},
      {'number': '2.0456-7890', 'date': '2024-01-14', 'status': 'statusArchived'},
      {'number': '3.0678-9012', 'date': '2024-01-13', 'status': 'statusArchived'},
      {'number': '1.0890-1234', 'date': '2024-01-12', 'status': 'statusArchived'},
      {'number': '4.0123-4567', 'date': '2024-01-11', 'status': 'statusArchived'},
      {'number': '5.0345-6789', 'date': '2024-01-10', 'status': 'statusArchived'},
    ];

    // 按日期范围筛选
    if (startDate != null || endDate != null) {
      mockResults = mockResults.where((item) {
        final itemDate = DateTime.parse(item['date']!);
        if (startDate != null && itemDate.isBefore(startDate)) return false;
        if (endDate != null && itemDate.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    // 排序
    mockResults.sort((a, b) => a['date']!.compareTo(b['date']!));
    if (!ascending) {
      mockResults = mockResults.reversed.toList();
    }

    return mockResults.map((item) => DrawingEntry(
      number: item['number']!,
      date: DateTime.parse(item['date']!),
      status: item['status']!,
    )).toList();
  }
}

/// 图纸条目数据模型
class DrawingEntry {
  final String number;
  final DateTime date;
  final String status;

  DrawingEntry({
    required this.number,
    required this.date,
    required this.status,
  });
}
