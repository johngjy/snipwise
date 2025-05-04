import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/services/window_service.dart';
import '../providers/editor_providers.dart';

/// 窗口管理服务，处理窗口大小调整和布局计算
class WindowManagerService {
  static final WindowManagerService _instance =
      WindowManagerService._internal();

  factory WindowManagerService() => _instance;

  WindowManagerService._internal();

  final Logger _logger = Logger();

  /// 基于图像尺寸和屏幕限制调整窗口大小
  Future<double> adjustWindowSize(
    WidgetRef ref, {
    required ui.Rect? logicalRect,
    required Uint8List? imageData,
    required double capturedScale,
  }) async {
    final editorState = ref.read(editorStateProvider);

    if (logicalRect == null || editorState.originalImageSize == null) {
      _logger.w('无法调整窗口大小：图像逻辑矩形或大小缺失');
      ref.read(editorStateProvider.notifier).setLoading(false);
      return 1.0; // 默认比例
    }

    try {
      ref.read(editorStateProvider.notifier).setLoading(true);

      // 获取图像尺寸和屏幕尺寸
      final Size imageSize = Size(
        logicalRect.width,
        logicalRect.height,
      );

      final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final Size screenSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      _logger.d('开始计算窗口尺寸，图像尺寸: $imageSize, 屏幕尺寸: $screenSize');

      // 初始化布局
      ref.read(layoutProvider.notifier).initialize(screenSize);

      // 加载截图并计算布局
      final initialScale = ref
          .read(editorStateProvider.notifier)
          .loadScreenshotWithLayout(editorState.currentImageData, imageSize,
              capturedScale: capturedScale);
      _logger.d('计算得到的初始缩放比例: $initialScale');

      // 获取计算出的窗口尺寸并调整窗口
      final editorWindowSize = ref.read(layoutProvider).editorWindowSize;
      _logger.d('计算得到的窗口尺寸: $editorWindowSize');

      await WindowService.instance.resizeWindow(editorWindowSize);
      await windowManager.center();
      _logger.d('窗口大小调整完成');

      return initialScale;
    } catch (e, stackTrace) {
      _logger.e('使用Riverpod调整窗口大小时出错', error: e, stackTrace: stackTrace);
      ref.read(editorStateProvider.notifier).setLoading(false);
      return 1.0; // 默认比例
    }
  }

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    try {
      await windowManager.minimize();
      _logger.d('窗口已最小化');
    } catch (e) {
      _logger.e('最小化窗口失败', error: e);
    }
  }

  /// 最大化窗口
  Future<void> maximizeWindow() async {
    try {
      // 先检查是否已经最大化
      final isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
        _logger.d('窗口已取消最大化');
      } else {
        await windowManager.maximize();
        _logger.d('窗口已最大化');
      }
    } catch (e) {
      _logger.e('切换窗口最大化状态失败', error: e);
    }
  }

  /// 关闭窗口
  Future<bool> closeWindow() async {
    try {
      await windowManager.close();
      return true;
    } catch (e) {
      _logger.e('关闭窗口失败', error: e);
      return false;
    }
  }

  /// 注册窗口事件监听器
  void registerWindowListener(WindowListener listener) {
    windowManager.addListener(listener);
  }

  /// 注销窗口事件监听器
  void unregisterWindowListener(WindowListener listener) {
    windowManager.removeListener(listener);
  }

  /// 处理窗口关闭请求，显示确认对话框
  Future<bool> handleWindowCloseRequest(BuildContext context) async {
    bool shouldClose = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出吗？未保存的更改将会丢失。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              shouldClose = false;
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              shouldClose = true;
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    return shouldClose;
  }
}
