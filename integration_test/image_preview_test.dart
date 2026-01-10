import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:demo/main.dart' as app;

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

    // 查找 InteractiveViewer（新的手势处理组件）
    final interactiveViewer = find.byType(InteractiveViewer);
    if (interactiveViewer.evaluate().isNotEmpty) {
      print('   找到 InteractiveViewer 组件，执行双击放大');

      // 获取组件的位置和大小
      await tester.pumpAndSettle();

      // 使用 tester.tap() 模拟双击（更容易触发 GestureDetector）
      // 在组件中心位置执行双击手势
      final center = tester.getCenter(interactiveViewer);
      print('   图片中心位置: ${center.dx}, ${center.dy}');

      // 第一次双击（放大）- 快速点击两次
      await tester.tap(interactiveViewer);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(interactiveViewer);

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
      await tester.tap(interactiveViewer);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(interactiveViewer);

      // 使用平滑渲染播放缩放还原动画
      await pumpSmoothly(tester, const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      print('✅ 已执行双击还原（应该还原到 1.0x）');

      // 停顿一下让观众看清还原效果
      print('\n等待 2 秒观察还原效果...');
      await Future.delayed(const Duration(seconds: 2));

      // Step 6: 测试 4 个不同位置的双击缩放
      print('\nStep 6: 测试 4 个不同位置的双击缩放');

      final Size size = tester.getSize(interactiveViewer);
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
        await tester.tap(interactiveViewer);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(interactiveViewer);
        await pumpSmoothly(tester, const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        print('   ✅ 已还原');

        await Future.delayed(const Duration(seconds: 1));
      }

      print('\n✅ 4 个位置双击缩放测试完成！');

      // Step 7: 测试 4 个不同位置的双指缩放
      print('\nStep 7: 测试 4 个不同位置的双指缩放');

      final imageSize = tester.getSize(interactiveViewer);

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
        await tester.tap(interactiveViewer);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(interactiveViewer);
        await pumpSmoothly(tester, const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 1));
      }

      print('\n✅ 4 个位置双指缩放测试完成！');
    } else {
      print('   ⚠️ 未找到 InteractiveViewer 组件');
    }

    // 保持应用打开，等待观察
    print('\n保持应用打开，等待观察...');
    await tester.pumpAndSettle(const Duration(seconds: 10));

    print('\n========================================');
    print('✅ 测试完成！');
    print('========================================\n');
  });
}
