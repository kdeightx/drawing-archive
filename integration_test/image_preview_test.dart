import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:demo/main.dart' as app;
import 'package:demo/comp_src/widgets/full_screen_image_viewer.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// 平滑渲染函数：强制测试框架按 60FPS 渲染动画，而不是跳过
///
/// 这个函数让测试过程看起来像真人操作一样流畅、自然
/// 适合用于录制演示视频或展示给客户看
Future<void> pumpSmoothly(WidgetTester tester, Duration duration) async {
  // 60FPS 意味着每帧约 16ms
  const step = Duration(milliseconds: 16);
  final int frames = (duration.inMilliseconds / 16).ceil();

  for (int i = 0; i < frames; i++) {
    // 1. 让 Flutter 推进 16ms 的动画时间
    await tester.pump(step);

    // 2. 【关键】让 CPU 真实等待 16ms
    // 如果没有这行，测试会以毫秒级速度瞬间跑完几百帧，人眼根本看不清
    await Future.delayed(step);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('测试流程：启动应用 -> 点击搜索已归档按钮 -> 点击第一张图片', (
    WidgetTester tester,
  ) async {
    print('\n========================================');
    print('开始图片预览功能集成测试');
    print('========================================\n');

    // Step 1: 启动应用并处理权限请求
    print('Step 1: 启动应用并处理权限请求');
    app.main();

    // 等待应用启动（使用平滑渲染）
    await pumpSmoothly(tester, const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 查找并点击权限授权按钮
    // 尝试多种可能的按钮文本
    bool permissionClicked = false;

    // 尝试1: "Allow" 按钮（英文）
    try {
      final allowButton = find.text('Allow');
      if (allowButton.evaluate().isNotEmpty) {
        await tester.tap(allowButton);
        await pumpSmoothly(tester, const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        print('✅ 已点击 "Allow" 按钮');
        permissionClicked = true;
      }
    } catch (e) {
      // 忽略
    }

    // 尝试2: "允许" 按钮（中文）
    if (!permissionClicked) {
      try {
        final allowButton = find.text('允许');
        if (allowButton.evaluate().isNotEmpty) {
          await tester.tap(allowButton);
          await pumpSmoothly(tester, const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
          print('✅ 已点击 "允许" 按钮');
          permissionClicked = true;
        }
      } catch (e) {
        // 忽略
      }
    }

    // 尝试3: 匹配包含 "Allow access" 的文本
    if (!permissionClicked) {
      try {
        final allowAccessButton = find.textContaining('Allow access');
        if (allowAccessButton.evaluate().isNotEmpty) {
          await tester.tap(allowAccessButton);
          await pumpSmoothly(tester, const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
          print('✅ 已点击授权按钮');
          permissionClicked = true;
        }
      } catch (e) {
        // 忽略
      }
    }

    if (!permissionClicked) {
      print('   ⚠️ 未检测到权限对话框，可能已授权或按钮文本不匹配');
    }

    // 等待返回应用
    await pumpSmoothly(tester, const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    print('✅ 应用已启动');

    // Step 2: 点击"搜索已归档"按钮
    print('\nStep 2: 点击"搜索已归档"按钮');

    // 查找包含"搜索已归档"文本的按钮
    final searchButton = find.text('搜索已归档');
    expect(searchButton, findsOneWidget, reason: '应该找到"搜索已归档"按钮');

    await tester.tap(searchButton);
    // 使用平滑渲染动画
    await pumpSmoothly(tester, const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    print('✅ 已点击"搜索已归档"按钮');

    // Step 3: 点击第一张图片
    print('\nStep 3: 点击第一张图片');

    // 等待图片列表加载并渲染
    await tester.pump();
    await tester.pump();
    await pumpSmoothly(tester, const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // 策略：找到 ListView，然后点击它的第一个可点击的子元素
    print('   查找 ListView...');
    final listView = find.byType(ListView);

    if (listView.evaluate().isEmpty) {
      print('   ⚠️ 未找到 ListView');
      await tester.tapAt(const Offset(540, 400));
      await pumpSmoothly(tester, const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      print('✅ 已点击坐标位置');
    } else {
      print('   ✅ 找到 ListView');

      // 找到 ListView 内的第一个 InkWell（搜索结果卡片的点击区域）
      final firstInkWellInList = find.descendant(
        of: listView,
        matching: find.byType(InkWell),
      );

      final inkWellCount = firstInkWellInList.evaluate().length;
      print('   ListView 中找到 $inkWellCount 个 InkWell');

      if (inkWellCount > 0) {
        print('   点击 ListView 中的第一个 InkWell');
        await tester.tap(firstInkWellInList.first);
        // 页面切换动画使用平滑渲染
        await pumpSmoothly(tester, const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        print('✅ 已点击第一张图片');
      } else {
        print('   ⚠️ ListView 中没有找到 InkWell');
        await tester.tap(listView);
        await pumpSmoothly(tester, const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        print('✅ 已点击 ListView');
      }
    }

    // 等待图片查看器完全加载
    await pumpSmoothly(tester, const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Step 4: 测试双击放大
    print('\nStep 4: 测试双击放大');

    // 等待图片查看器完全加载
    await tester.pump();
    await pumpSmoothly(tester, const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 查找 PageView（新的手势处理组件）
    final pageViewFinder = find.byType(PageView);
    if (pageViewFinder.evaluate().isNotEmpty) {
      print('   找到 PageView 组件，执行双击放大');

      // 获取组件的位置和大小
      await tester.pumpAndSettle();

      // 使用 tester.tap() 模拟双击（更容易触发 GestureDetector）
      // 在组件中心位置执行双击手势
      final center = tester.getCenter(pageViewFinder);
      print('   图片中心位置: ${center.dx}, ${center.dy}');

      // 第一次双击（放大）- 快速点击两次
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(center);

      // 使用平滑渲染播放缩放动画（300ms 是动画时长）
      await pumpSmoothly(tester, const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      print('✅ 已执行双击放大（应该放大到 2.5x）');

      // 停顿一下让观众看清放大效果
      print('\n等待 2 秒观察放大效果...');
      await Future.delayed(const Duration(seconds: 2));

      // Step 5: 测试双击还原
      print('\nStep 5: 测试双击还原');

      // 第二次双击（还原）- 快速点击两次
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(center);

      // 使用平滑渲染播放缩放还原动画
      await pumpSmoothly(tester, const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      print('✅ 已执行双击还原（应该还原到 1.0x）');

      // 停顿一下让观众看清还原效果
      print('\n等待 2 秒观察还原效果...');
      await Future.delayed(const Duration(seconds: 2));

      // Step 6: 测试 4 个不同位置的双击缩放
      print('\nStep 6: 测试 4 个不同位置的双击缩放');

      final Size size = tester.getSize(pageViewFinder);
      print('   图片尺寸: ${size.width} x ${size.height}');

      // 定义 4 个测试位置：左上、右上、左下、右下
      final testPositions = [
        {'name': '左上角', 'x': 0.25, 'y': 0.25},
        {'name': '右上角', 'x': 0.75, 'y': 0.25},
        {'name': '左下角', 'x': 0.25, 'y': 0.75},
        {'name': '右下角', 'x': 0.75, 'y': 0.75},
      ];

      for (var pos in testPositions) {
        print('   测试${pos['name']}双击缩放...');
        final offset = Offset(
          size.width * (pos['x'] as double),
          size.height * (pos['y'] as double),
        );

        // 双击缩放
        await tester.tapAt(offset);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(offset);
        await pumpSmoothly(tester, const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        print('   ✅ ${pos['name']}缩放完成');

        await Future.delayed(const Duration(seconds: 1));

        // 还原
        await tester.tapAt(center);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(center);
        await pumpSmoothly(tester, const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        print('   ✅ 已还原');

        await Future.delayed(const Duration(seconds: 1));
      }

      print('\n✅ 4 个位置双击缩放测试完成！');

      // Step 7: 测试 4 个不同位置的双指缩放
      print('\nStep 7: 测试 4 个不同位置的双指缩放');

      final imageSize = tester.getSize(pageViewFinder);

      // 定义 4 个测试位置
      final pinchTestPositions = [
        {'name': '左上角', 'x': 0.25, 'y': 0.25},
        {'name': '右上角', 'x': 0.75, 'y': 0.25},
        {'name': '左下角', 'x': 0.25, 'y': 0.75},
        {'name': '右下角', 'x': 0.75, 'y': 0.75},
      ];

      for (var pos in pinchTestPositions) {
        print('   测试${pos['name']}双指缩放...');

        // 计算测试位置
        final testPos = Offset(
          imageSize.width * (pos['x'] as double),
          imageSize.height * (pos['y'] as double),
        );

        // 创建两个手指的初始位置（在测试位置两侧）
        final finger1Start = testPos + const Offset(-30, 0);
        final finger2Start = testPos + const Offset(30, 0);

        // 创建两个手势
        final gesture1 = await tester.startGesture(finger1Start, pointer: 7);
        final gesture2 = await tester.startGesture(finger2Start, pointer: 8);

        // 向外移动手指（放大）
        await gesture1.moveBy(const Offset(-80, 0));
        await gesture2.moveBy(const Offset(80, 0));

        // 使用平滑渲染播放缩放过程
        await pumpSmoothly(tester, const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        // 释放手势
        await gesture1.up();
        await gesture2.up();

        print('   ✅ ${pos['name']}双指放大完成');

        await Future.delayed(const Duration(seconds: 1));

        // 再次创建手势进行缩小
        final gesture3 = await tester.startGesture(finger1Start, pointer: 7);
        final gesture4 = await tester.startGesture(finger2Start, pointer: 8);

        // 向内移动手指（缩小）
        await gesture3.moveBy(const Offset(20, 0));
        await gesture4.moveBy(const Offset(-20, 0));

        await pumpSmoothly(tester, const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        await gesture3.up();
        await gesture4.up();

        print('   ✅ ${pos['name']}双指缩小完成');

        // 双击还原
        await tester.tapAt(center);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(center);
        await pumpSmoothly(tester, const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 1));
      }

      print('\n✅ 4 个位置双指缩放测试完成！');
    } else {
      print('   ⚠️ 未找到 PageView 组件');
    }

    // 保持应用打开，等待观察
    print('\n保持应用打开，等待观察...');
    await tester.pumpAndSettle(const Duration(seconds: 10));

    print('\n========================================');
    print('✅ 测试完成！');
    print('========================================\n');
  });

  // ========================================
  // 新增：手势健壮性测试（基于增量算法）
  // ========================================

  group('FullScreenImageViewer 手势健壮性测试', () {
    late List<String> testImagePaths;

    // 在所有测试开始前，生成 2 张测试图片文件
    setUpAll(() async {
      testImagePaths = [];
      final directory = await getTemporaryDirectory();

      // 创建简单的 1x1 像素透明图片数据 (PNG header)
      final Uint8List pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      for (int i = 0; i < 2; i++) {
        final File file = File('${directory.path}/test_image_$i.png');
        await file.writeAsBytes(pngBytes);
        testImagePaths.add(file.path);
      }
    });

    // 辅助函数：获取当前图片的变换矩阵
    Matrix4 getCurrentTransform(WidgetTester tester) {
      final transformFinder = find.descendant(
        of: find.byType(FullScreenImageViewer),
        matching: find.byType(Transform),
      );
      // 取第一个找到的 Transform（基于代码结构，它是直接包裹 Image 的）
      final Transform transformWidget = tester.widget(transformFinder.first);
      return transformWidget.transform;
    }

    testWidgets('测试 1: 初始状态下 PageView 翻页功能', (WidgetTester tester) async {
      print('\n--- 测试 1: 初始状态翻页 ---');

      await tester.pumpWidget(MaterialApp(
        home: FullScreenImageViewer(imagePaths: testImagePaths),
      ));
      await tester.pumpAndSettle();

      // 验证当前是第一页
      expect(find.text('1/2'), findsOneWidget);
      print('✅ 初始状态：第一页');

      // 执行向左滑动（翻到下一页）
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // 验证翻到了第二页
      expect(find.text('2/2'), findsOneWidget);
      print('✅ 翻页成功：第二页');
    });

    testWidgets('测试 2: 双击放大与 PageView 锁定机制', (WidgetTester tester) async {
      print('\n--- 测试 2: 双击放大与翻页锁定 ---');

      await tester.pumpWidget(MaterialApp(
        home: FullScreenImageViewer(imagePaths: testImagePaths),
      ));
      await tester.pumpAndSettle();

      final pageView = find.byType(PageView);
      final center = tester.getCenter(pageView);

      // 1. 双击中心
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle(); // 等待动画完成

      // 2. 验证矩阵是否放大 (Scale > 1.0)
      final matrix = getCurrentTransform(tester);
      final scale = matrix.getMaxScaleOnAxis();
      expect(scale, greaterThan(1.1), reason: "双击后应该放大");
      print('✅ 双击放大成功：scale = $scale');

      // 3. 尝试翻页（此时应该被锁死）
      await tester.drag(pageView, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // 验证依然在第一页 (PageScroll Locked)
      expect(find.text('1/2'), findsOneWidget, reason: "放大状态下不应触发翻页");
      print('✅ 放大状态下翻页已锁定');
    });

    testWidgets('测试 3: 双指旋转交互', (WidgetTester tester) async {
      print('\n--- 测试 3: 双指旋转 ---');

      await tester.pumpWidget(MaterialApp(
        home: FullScreenImageViewer(imagePaths: testImagePaths),
      ));
      await tester.pumpAndSettle();

      final pageView = find.byType(PageView);
      final center = tester.getCenter(pageView);

      // 创建两个手指
      final gesture1 = await tester.startGesture(center + const Offset(-50, 0), pointer: 7);
      final gesture2 = await tester.startGesture(center + const Offset(50, 0), pointer: 8);

      // 旋转 90 度 (模拟)
      // 左手指向上移，右手指向下移 -> 顺时针旋转
      await gesture1.moveTo(center + const Offset(0, -50));
      await gesture2.moveTo(center + const Offset(0, 50));

      await tester.pump(); // 触发重绘

      // 验证矩阵包含旋转
      final matrix = getCurrentTransform(tester);
      // 计算旋转分量 (sin值)
      final sinValue = matrix.entry(0, 1); // Row 0, Col 1
      expect(sinValue.abs(), greaterThan(0.1), reason: "应该检测到旋转");
      print('✅ 旋转成功：sin(theta) = $sinValue');

      await gesture1.up();
      await gesture2.up();
    });

    testWidgets('测试 4: 双击复位功能 (旋转+放大后双击)', (WidgetTester tester) async {
      print('\n--- 测试 4: 双击复位 ---');

      await tester.pumpWidget(MaterialApp(
        home: FullScreenImageViewer(imagePaths: testImagePaths),
      ));
      await tester.pumpAndSettle();

      final pageView = find.byType(PageView);
      final center = tester.getCenter(pageView);

      // 先搞乱状态：双击放大
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      // 验证已放大
      expect(getCurrentTransform(tester).getMaxScaleOnAxis(), greaterThan(1.1));
      print('✅ 已放大');

      // 再次双击（应该复位）
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle(); // 等待复位动画

      // 验证回归单位矩阵 (Identity)
      final matrix = getCurrentTransform(tester);
      expect(matrix.isIdentity(), isTrue, reason: "再次双击应还原为初始状态");
      print('✅ 双击复位成功：回归 Identity');
    });

    testWidgets('测试 5: 无限拖拽 (放大后单指移动)', (WidgetTester tester) async {
      print('\n--- 测试 5: 无限拖拽 ---');

      await tester.pumpWidget(MaterialApp(
        home: FullScreenImageViewer(imagePaths: testImagePaths),
      ));
      await tester.pumpAndSettle();

      final pageView = find.byType(PageView);
      final center = tester.getCenter(pageView);

      // 1. 先双击放大，进入"自由模式"
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      // 获取初始位移
      final initialMatrix = getCurrentTransform(tester);
      final initialTranslation = initialMatrix.getTranslation();
      print('✅ 初始位移：(${initialTranslation.x.toStringAsFixed(2)}, ${initialTranslation.y.toStringAsFixed(2)})');

      // 2. 执行拖拽 (向右下拖动)
      const dragOffset = Offset(100, 100);
      await tester.dragFrom(center, dragOffset);
      await tester.pump(); // 触发一帧更新

      // 3. 验证位移发生了变化
      final newMatrix = getCurrentTransform(tester);
      final newTranslation = newMatrix.getTranslation();

      // 验证 X 和 Y 轴都发生了移动
      // 注意：由于我们是向右下拖，Translation 应该增加
      expect(newTranslation.x, greaterThan(initialTranslation.x));
      expect(newTranslation.y, greaterThan(initialTranslation.y));
      print('✅ 拖拽后位移：(${newTranslation.x.toStringAsFixed(2)}, ${newTranslation.y.toStringAsFixed(2)})');
    });
  });
}
