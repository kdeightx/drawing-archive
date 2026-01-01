import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/drawing_service.dart';

/// 进度状态枚举
enum ProgressState {
  sending,    // 发送数据中
  scanning,   // AI扫描中
  completed,  // 扫描完成
}

/// DrawingScanner 页面的 ViewModel
///
/// 负责管理图纸扫描页面的状态和业务逻辑
class DrawingScannerViewModel extends ChangeNotifier {
  /// DrawingService 服务实例
  final DrawingService drawingService;

  // ========== 状态变量 ==========

  /// 选中的图片列表（支持多选）
  List<File> _selectedImages = [];
  List<File> get selectedImages => _selectedImages;

  /// 当前查看的图片索引
  int _currentImageIndex = 0;
  int get currentImageIndex => _currentImageIndex;

  /// 每张图片对应的编号列表
  List<String> _recognizedNumbers = [];
  List<String> get recognizedNumbers => _recognizedNumbers;

  /// 每张图片的编号输入控制器
  List<TextEditingController> _numberControllers = [];
  List<TextEditingController> get numberControllers => _numberControllers;

  /// 每张图片的识别失败状态
  List<bool> _recognitionFailedList = [];
  List<bool> get recognitionFailedList => _recognitionFailedList;

  /// 编号列表当前页码
  int _numberPage = 0;
  int get numberPage => _numberPage;

  /// 每页显示的编号数量
  int get numbersPerPage => 5;

  /// 总页数
  int get totalPages => (_selectedImages.length / numbersPerPage).ceil();

  /// 是否正在分析
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  /// 当前正在识别的图片索引（-1表示没有正在识别的图片）
  int _analyzingIndex = -1;
  int get analyzingIndex => _analyzingIndex;

  /// 是否正在保存
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// 进度状态
  ProgressState? _progressState;
  ProgressState? get progressState => _progressState;

  /// AI 识别是否失败
  bool _aiRecognitionFailed = false;
  bool get aiRecognitionFailed => _aiRecognitionFailed;

  /// 当前旋转角度（0, 90, 180, 270）
  int _currentRotation = 0;
  int get currentRotation => _currentRotation;

  // ========== 构造函数 ==========

  DrawingScannerViewModel({required this.drawingService});

  // ========== 公共方法 ==========

  /// 选择单张图片（相机）
  Future<void> pickImage() async {
    // 检查是否正在分析中
    if (_isAnalyzing) {
      throw Exception('正在识别图片，请等待识别完成后再拍照');
    }

    try {
      final File? image = await drawingService.pickImage(ImageSource.camera);
      if (image == null) {
        return;
      }

      // 复制到临时文件夹
      final tempFile = await drawingService.copyImageToTempFolder(image);

      // 插入到列表最前面
      _selectedImages.insert(0, tempFile);
      _recognizedNumbers.insert(0, '');
      _numberControllers.insert(0, TextEditingController());
      _recognitionFailedList.insert(0, false); // 新图片未识别失败
      _currentImageIndex = 0; // 切换到新拍的图片
      _aiRecognitionFailed = false; // 重置 AI 识别失败状态
      notifyListeners();

      // 不再自动触发识别，等待用户点击上传按钮
    } catch (e) {
      rethrow;
    }
  }

  /// 选择多张图片（相册）
  Future<bool> pickMultipleImages() async {
    // 检查是否正在分析中
    if (_isAnalyzing) {
      throw Exception('正在识别图片，请等待识别完成后再选择');
    }

    try {
      final List<File> images = await drawingService.pickMultipleImages();
      if (images.isEmpty) return false;

      // 复制所有图片到临时文件夹，获取临时文件路径
      final List<File> tempImages = [];
      for (var image in images) {
        final tempFile = await drawingService.copyImageToTempFolder(image);
        tempImages.add(tempFile);
      }

      // 为新图片创建编号列表和控制器
      final List<String> numbers = List.filled(tempImages.length, '', growable: true);
      final List<TextEditingController> controllers =
          List.generate(tempImages.length, (index) => TextEditingController(), growable: true);
      final List<bool> recognitionFailed = List.filled(tempImages.length, false, growable: true); // 新图片未识别失败

      // 插入到列表最前面
      _selectedImages.insertAll(0, tempImages);
      _recognizedNumbers.insertAll(0, numbers);
      _numberControllers.insertAll(0, controllers);
      _recognitionFailedList.insertAll(0, recognitionFailed);
      _currentImageIndex = 0; // 切换到第一张新图片
      _aiRecognitionFailed = false; // 重置 AI 识别失败状态
      notifyListeners();

      // 不再自动触发识别，等待用户点击上传按钮
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 上传并识别所有未识别的图片
  Future<void> uploadAndRecognizeAll() async {
    if (_selectedImages.isEmpty) {
      throw Exception('请先选择图片');
    }

    // 找出所有还没有识别结果的图片
    final List<int> pendingIndexes = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_recognizedNumbers[i].isEmpty) {
        pendingIndexes.add(i);
      }
    }

    if (pendingIndexes.isEmpty) {
      // 所有图片都已识别，不需要重复识别
      return;
    }

    debugPrint('🚀 开始识别 ${pendingIndexes.length} 张图片...');

    // 标记开始识别流程
    _isAnalyzing = true;
    notifyListeners();

    // 显示进度：发送数据
    _progressState = ProgressState.sending;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // 显示进度：AI扫描中
    _progressState = ProgressState.scanning;
    notifyListeners();

    int successCount = 0;
    int failureCount = 0;
    bool hasApiError = false;

    // 逐个识别未识别的图片，每张图片单独处理异常
    for (int index in pendingIndexes) {
      _analyzingIndex = index; // 标记正在识别的图片
      notifyListeners();

      try {
        final String number = await drawingService.analyzeImage(_selectedImages[index], shouldCopy: false);
        _recognizedNumbers[index] = number;
        _numberControllers[index].text = number;
        _recognitionFailedList[index] = false; // 识别成功，清除失败标记
        successCount++;
        debugPrint('  ✓ 图片 ${index + 1} 识别完成: $number');
      } catch (e) {
        failureCount++;
        _recognitionFailedList[index] = true; // 标记识别失败
        debugPrint('  ✗ 图片 ${index + 1} 识别失败: $e');

        // 检查是否是 AI API 相关错误
        final errorMsg = e.toString();
        if (errorMsg.contains('API Key 未配置') ||
            errorMsg.contains('AI 识别失败') ||
            errorMsg.contains('AI 识别超时') ||
            errorMsg.contains('网络连接失败') ||
            errorMsg.contains('网络') ||
            errorMsg.contains('连接') ||
            errorMsg.contains('超时')) {
          hasApiError = true;
        }

        // 继续识别下一张图片，不中断流程
        continue;
      }

      notifyListeners();
    }

    // 显示进度：完成
    _progressState = ProgressState.completed;
    _analyzingIndex = -1; // 清除正在识别的标记
    notifyListeners();

    debugPrint('✅ 识别完成：成功 $successCount 张，失败 $failureCount 张');

    // 3秒后恢复到非活跃状态
    await Future.delayed(const Duration(seconds: 3));
    _progressState = null;
    _isAnalyzing = false;
    _aiRecognitionFailed = hasApiError; // 如果有API错误，标记失败
    notifyListeners();

    // 如果全部失败，抛出异常提示用户
    if (successCount == 0 && failureCount > 0) {
      throw Exception('所有图片识别失败，请检查网络连接或AI API配置');
    }
  }

  /// 清理当前选中的临时图片
  ///
  /// 在重新选择图片之前，删除上一轮未保存的临时文件
  Future<void> _clearCurrentTempImages() async {
    for (var image in _selectedImages) {
      try {
        await drawingService.deleteTempImage(image);
      } catch (e) {
        // 忽略删除失败的文件（可能已被手动删除）
        debugPrint('清理临时文件失败: $e');
      }
    }
  }

  /// 分析单张图片
  Future<void> analyzeImage() async {
    if (_selectedImages.isEmpty) {
      throw Exception('请先选择图片');
    }

    // 显示进度：发送数据
    _progressState = ProgressState.sending;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // 显示进度：AI扫描中
    _progressState = ProgressState.scanning;
    _analyzingIndex = _currentImageIndex; // 标记正在识别的图片
    notifyListeners();

    try {
      final File currentImage = _selectedImages[_currentImageIndex];
      final String number = await drawingService.analyzeImage(currentImage, shouldCopy: false);

      // 显示进度：完成
      _progressState = ProgressState.completed;
      _recognizedNumbers[_currentImageIndex] = number;
      _numberControllers[_currentImageIndex].text = number;
      notifyListeners();

      // 延迟后隐藏进度（显示完成状态3秒）
      await Future.delayed(const Duration(seconds: 3));
      _progressState = null;
      _isAnalyzing = false;
      _analyzingIndex = -1; // 清除正在识别的标记
      notifyListeners();
    } catch (e) {
      _progressState = null;
      _isAnalyzing = false;
      _analyzingIndex = -1; // 清除正在识别的标记
      notifyListeners();

      // 检查是否是 AI API 相关错误
      final errorMsg = e.toString();
      if (errorMsg.contains('API Key 未配置') ||
          errorMsg.contains('AI 识别失败') ||
          errorMsg.contains('AI 识别超时') ||
          errorMsg.contains('网络连接失败') ||
          errorMsg.contains('网络') ||
          errorMsg.contains('连接') ||
          errorMsg.contains('超时')) {
        _aiRecognitionFailed = true; // 标记 AI 识别失败
        throw Exception('AI API 连接失败：$errorMsg');
      }

      rethrow;
    }
  }

  /// 批量分析所有图片
  Future<void> analyzeAllImages() async {
    if (_selectedImages.isEmpty) return;

    // 显示进度：发送数据
    _progressState = ProgressState.sending;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // 显示进度：AI扫描中
    _progressState = ProgressState.scanning;
    notifyListeners();

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final String number = await drawingService.analyzeImage(_selectedImages[i], shouldCopy: false);
        _recognizedNumbers[i] = number;
        _numberControllers[i].text = number;
        notifyListeners();
      }

      // 显示进度：完成
      _progressState = ProgressState.completed;
      notifyListeners();

      // 3秒后恢复到非活跃状态
      await Future.delayed(const Duration(seconds: 3));
      _progressState = null;
      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _progressState = null;
      _isAnalyzing = false;
      notifyListeners();

      // 检查是否是 AI API 相关错误
      final errorMsg = e.toString();
      if (errorMsg.contains('API Key 未配置') ||
          errorMsg.contains('AI 识别失败') ||
          errorMsg.contains('AI 识别超时') ||
          errorMsg.contains('网络连接失败') ||
          errorMsg.contains('网络') ||
          errorMsg.contains('连接') ||
          errorMsg.contains('超时')) {
        _aiRecognitionFailed = true; // 标记 AI 识别失败
        throw Exception('AI API 连接失败：$errorMsg');
      }

      rethrow;
    }
  }

  /// 分析新添加的图片
  ///
  /// [startIndex] 新图片的起始索引
  /// [count] 新图片的数量
  Future<void> _analyzeNewImages(int startIndex, int count) async {
    if (_selectedImages.isEmpty) return;

    // 显示进度：发送数据
    _progressState = ProgressState.sending;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // 显示进度：AI扫描中
    _progressState = ProgressState.scanning;
    notifyListeners();

    try {
      // 只分析新添加的图片
      for (int i = startIndex; i < startIndex + count; i++) {
        _analyzingIndex = i; // 标记正在识别的图片
        notifyListeners();

        final String number = await drawingService.analyzeImage(_selectedImages[i], shouldCopy: false);
        _recognizedNumbers[i] = number;
        _numberControllers[i].text = number;
        notifyListeners();
      }

      // 显示进度：完成
      _progressState = ProgressState.completed;
      _analyzingIndex = -1; // 清除正在识别的标记
      notifyListeners();

      // 3秒后恢复到非活跃状态
      await Future.delayed(const Duration(seconds: 3));
      _progressState = null;
      _isAnalyzing = false;
      notifyListeners();
    } catch (e) {
      _progressState = null;
      _isAnalyzing = false;
      _analyzingIndex = -1; // 清除正在识别的标记
      notifyListeners();

      // 检查是否是 AI API 相关错误
      final errorMsg = e.toString();
      if (errorMsg.contains('API Key 未配置') ||
          errorMsg.contains('AI 识别失败') ||
          errorMsg.contains('AI 识别超时') ||
          errorMsg.contains('网络连接失败') ||
          errorMsg.contains('网络') ||
          errorMsg.contains('连接') ||
          errorMsg.contains('超时')) {
        _aiRecognitionFailed = true; // 标记 AI 识别失败
        throw Exception('AI API 连接失败：$errorMsg');
      }

      rethrow;
    }
  }

  /// 保存所有图片
  Future<int> saveAllImages() async {
    if (_selectedImages.isEmpty) {
      throw Exception('请先选择图片');
    }

    debugPrint('📦 准备保存图片...');

    // 找出所有有编号的图片（识别成功或手动填写）
    final List<int> validIndexes = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_numberControllers[i].text.trim().isNotEmpty) {
        validIndexes.add(i);
      }
    }

    if (validIndexes.isEmpty) {
      throw Exception('没有已识别的图片可保存，请先进行识别或手动填写编号');
    }

    debugPrint('  找到 ${validIndexes.length} 张已识别的图片（共 ${_selectedImages.length} 张）');

    _isSaving = true;
    notifyListeners();

    try {
      // 只保存有编号的图片
      int successCount = 0;

      debugPrint('开始保存已识别的图片...');
      for (int index in validIndexes) {
        final number = _numberControllers[index].text.trim();
        debugPrint('  [${successCount + 1}/${validIndexes.length}] 保存图片 ${index + 1}: $number');
        await drawingService.saveEntry(_selectedImages[index], number);
        successCount++;
        debugPrint('    ✓ 保存成功');
      }

      debugPrint('✅ 成功保存 $successCount 张已识别的图片');

      // 保存成功后清理所有临时图片并重置页面
      await drawingService.clearAllTempImages();
      await reset();

      _isSaving = false;
      notifyListeners();

      return successCount;
    } catch (e) {
      debugPrint('❌ 保存失败: $e');
      _isSaving = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 删除图片
  Future<void> deleteImage(int index) async {
    // 先删除临时文件
    await drawingService.deleteTempImage(_selectedImages[index]);

    // 再从列表中移除
    _numberControllers[index].dispose();
    _numberControllers.removeAt(index);
    _selectedImages.removeAt(index);
    _recognizedNumbers.removeAt(index);
    _recognitionFailedList.removeAt(index);

    if (_currentImageIndex >= _selectedImages.length) {
      _currentImageIndex = _selectedImages.length - 1;
    }

    if (_numberPage > 0 && (_numberPage * numbersPerPage) >= _selectedImages.length) {
      _numberPage--;
    }

    notifyListeners();
  }

  /// 更新编号
  void updateNumber(int index, String number) {
    _recognizedNumbers[index] = number;
    notifyListeners();
  }

  /// 切换当前图片
  void setCurrentImageIndex(int index) {
    _currentImageIndex = index;
    // UI 控制器由各个组件自行管理
    notifyListeners();
  }

  /// 上一页
  void previousPage() {
    if (_numberPage > 0) {
      _numberPage--;
      notifyListeners();
    }
  }

  /// 下一页
  void nextPage() {
    if (_numberPage < totalPages - 1) {
      _numberPage++;
      notifyListeners();
    }
  }

  /// 顺时针旋转90度
  void rotateClockwise() {
    _currentRotation = (_currentRotation + 90) % 360;
    notifyListeners();
  }

  /// 逆时针旋转90度
  void rotateCounterClockwise() {
    _currentRotation = (_currentRotation - 90) % 360;
    if (_currentRotation < 0) _currentRotation += 360;
    notifyListeners();
  }

  /// 重置旋转和缩放
  void resetRotation() {
    _currentRotation = 0;
    // UI 控制器由各个组件自行管理
    notifyListeners();
  }

  /// 重置页面
  Future<void> reset() async {
    // 清理所有控制器
    for (var controller in _numberControllers) {
      controller.dispose();
    }

    _selectedImages = [];
    _currentImageIndex = 0;
    _recognizedNumbers = [];
    _numberControllers = [];
    _recognitionFailedList = []; // 重置识别失败列表
    _numberPage = 0;
    _currentRotation = 0;  // 重置旋转角度
    _isAnalyzing = false;
    _analyzingIndex = -1; // 重置正在识别的图片索引
    _isSaving = false;
    _progressState = null;

    notifyListeners();
  }

  /// 清空所有图片（删除临时文件并重置页面）
  Future<void> clearAllImages() async {
    debugPrint('🗑️ 清空所有图片...');

    // 删除所有临时文件
    for (var image in _selectedImages) {
      try {
        await drawingService.deleteTempImage(image);
        debugPrint('  ✓ 已删除临时文件: ${image.path.split('/').last}');
      } catch (e) {
        debugPrint('  ✗ 删除失败: ${image.path.split('/').last} - $e');
      }
    }

    // 重置页面
    await reset();

    debugPrint('✅ 所有图片已清空');
  }

  /// 释放资源
  @override
  void dispose() {
    // 清理所有编号输入控制器
    for (var controller in _numberControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
