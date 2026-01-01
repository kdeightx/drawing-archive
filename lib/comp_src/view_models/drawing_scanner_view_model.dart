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

  /// 是否正在保存
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// 进度状态
  ProgressState? _progressState;
  ProgressState? get progressState => _progressState;

  /// 当前旋转角度（0, 90, 180, 270）
  int _currentRotation = 0;
  int get currentRotation => _currentRotation;

  // ========== 构造函数 ==========

  DrawingScannerViewModel({required this.drawingService});

  // ========== 公共方法 ==========

  /// 选择单张图片（相机）
  Future<void> pickImage() async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      // 先清理上一轮的临时文件
      await _clearCurrentTempImages();

      final File? image = await drawingService.pickImage(ImageSource.camera);
      if (image == null) {
        _isAnalyzing = false;
        notifyListeners();
        return;
      }

      // 复制到临时文件夹
      final tempFile = await drawingService.copyImageToTempFolder(image);

      _selectedImages = [tempFile];
      _currentImageIndex = 0;
      _recognizedNumbers = [''];
      _numberControllers = [TextEditingController()];
      _numberPage = 0;
      notifyListeners();

      // 自动触发识别
      await analyzeImage();
    } catch (e) {
      _isAnalyzing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 选择多张图片（相册）
  Future<bool> pickMultipleImages() async {
    try {
      // 先清理上一轮的临时文件
      await _clearCurrentTempImages();

      final List<File> images = await drawingService.pickMultipleImages();
      if (images.isEmpty) return false;

      // 复制所有图片到临时文件夹，获取临时文件路径
      final List<File> tempImages = [];
      for (var image in images) {
        final tempFile = await drawingService.copyImageToTempFolder(image);
        tempImages.add(tempFile);
      }

      // 初始化编号列表和控制器
      final List<String> numbers = List.filled(tempImages.length, '', growable: true);
      final List<TextEditingController> controllers =
          List.generate(tempImages.length, (index) => TextEditingController(), growable: true);

      // 使用临时文件路径（AI_ 开头）
      _selectedImages = tempImages;
      _currentImageIndex = 0;
      _recognizedNumbers = numbers;
      _numberControllers = controllers;
      _numberPage = 0;
      notifyListeners();

      // 批量分析所有图片
      await analyzeAllImages();
      return true;
    } catch (e) {
      rethrow;
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
      notifyListeners();
    } catch (e) {
      _progressState = null;
      _isAnalyzing = false;
      notifyListeners();
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
      rethrow;
    }
  }

  /// 保存所有图片
  Future<int> saveAllImages() async {
    if (_selectedImages.isEmpty) {
      throw Exception('请先选择图片');
    }

    // 检查所有编号是否都已填写
    for (int i = 0; i < _numberControllers.length; i++) {
      if (_numberControllers[i].text.trim().isEmpty) {
        throw Exception('请填写第 ${i + 1} 张图片的编号');
      }
    }

    _isSaving = true;
    notifyListeners();

    try {
      // 批量保存所有图片
      int successCount = 0;
      for (int i = 0; i < _selectedImages.length; i++) {
        final number = _numberControllers[i].text.trim();
        await drawingService.saveEntry(_selectedImages[i], number);
        successCount++;
      }

      // 保存成功后清理所有临时图片并重置页面
      await drawingService.clearAllTempImages();
      await reset();

      _isSaving = false;
      notifyListeners();

      return successCount;
    } catch (e) {
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
    _numberPage = 0;
    _currentRotation = 0;  // 重置旋转角度
    _isAnalyzing = false;
    _isSaving = false;
    _progressState = null;

    notifyListeners();
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
