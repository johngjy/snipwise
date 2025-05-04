import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:screen_capturer/screen_capturer.dart' as screen_capturer;
import 'package:screen_retriever/screen_retriever.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/capture_mode.dart';
import '../../domain/entities/capture_result.dart';

/// 截图服务类
class CaptureService {
  /// 单例实例
  static final CaptureService instance = CaptureService._internal();
  final _windowManager = WindowManager.instance;
  final _logger = Logger();

  /// 全局导航键
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 私有构造函数
  CaptureService._internal() {
    _initializeWindowManager();
  }

  /// 初始化窗口管理器
  Future<void> _initializeWindowManager() async {
    try {
      await _windowManager.ensureInitialized();
      await _windowManager.setPreventClose(true);
      await _windowManager.setTitle('Snipwise');
    } catch (e) {
      _logger.e('Error initializing window manager', error: e);
    }
  }

  /// 获取临时文件路径
  Future<String> _getTemporaryFilePath() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(tempDir.path, 'screenshot_$timestamp.png');
    _logger.d('Generated temporary file path: $filePath');
    return filePath;
  }

  /// 辅助方法：隐藏窗口用于截图
  Future<bool> _hideWindowForCapture(String captureModeLabel) async {
    _logger.d('Attempting to hide window for $captureModeLabel capture...');
    try {
      // 使用透明化窗口代替最小化
      await _windowManager.setOpacity(0.0);
      _logger.d('Window opacity set to 0 for $captureModeLabel capture.');
      return true;
    } catch (windowError) {
      _logger.w(
          'Failed to hide window for $captureModeLabel: $windowError - proceeding anyway');
      return false; // 表示窗口隐藏失败，但我们仍然继续
    }
  }

  /// 辅助方法：截图后恢复窗口
  Future<void> _restoreWindowAfterCapture(
      bool windowWasHidden, String captureModeLabel) async {
    _logger.d('$captureModeLabel capture finally block: Restoring window...');
    if (windowWasHidden) {
      try {
        // 等待足够长时间以确保截图操作完成
        await Future.delayed(const Duration(milliseconds: 100));

        // 直接恢复窗口显示
        await _windowManager.setOpacity(1.0);
        await Future.delayed(const Duration(milliseconds: 50));

        // 尝试获取焦点
        await _windowManager.focus();
        _logger
            .d('Window successfully restored after $captureModeLabel capture.');
      } catch (restoreError) {
        _logger
            .e('Error restoring window after $captureModeLabel: $restoreError');
        // 尝试备用恢复方法
        try {
          await Future.delayed(const Duration(milliseconds: 200));
          await _windowManager.setOpacity(1.0);
          _logger.d(
              'Backup window restore successful after $captureModeLabel capture.');
        } catch (e) {
          _logger.e('Backup window restore failed after $captureModeLabel: $e');
        }
      }
    } else {
      _logger.d(
          'Window was not hidden for $captureModeLabel, no need to restore.');
    }
  }

  /// 获取当前的设备像素比
  double _getCurrentDevicePixelRatio() {
    try {
      // 优先使用 WidgetsBinding 获取当前视图的 DPR
      final scale = WidgetsBinding
          .instance.platformDispatcher.views.first.devicePixelRatio;
      _logger.d('Retrieved device pixel ratio: $scale');
      return scale;
    } catch (e) {
      _logger.e('Failed to get device pixel ratio: $e. Defaulting to 1.0');
      return 1.0;
    }
  }

  /// 执行截图，根据模式调用对应的内部实现方法
  Future<CaptureResult?> capture(CaptureMode mode,
      {Size? fixedSize, Duration? delay}) async {
    _logger.i('Capture called with mode: $mode, delay: $delay');

    // 检查屏幕截图权限
    try {
      final isAccessAllowed =
          await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
      _logger.d('Screen capture permission status: $isAccessAllowed');

      if (!isAccessAllowed) {
        _logger.w('No screen capture permission. Requesting access...');
        await screen_capturer.ScreenCapturer.instance.requestAccess();
        _logger.d('Permission request completed');

        final accessGranted =
            await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
        if (!accessGranted) {
          _logger.e('User denied screen capture permission');
          return null;
        }
      }
    } catch (e) {
      _logger.e('Error checking screen capture permissions', error: e);
      // 继续执行，因为某些平台可能不需要显式权限
    }

    // 处理延迟截图
    if (delay != null && delay.inMilliseconds > 0) {
      _logger.d('Applying delay of ${delay.inSeconds} seconds before capture');
      await Future.delayed(delay);
      _logger.d('Delay completed, proceeding with capture');
    }

    // 根据不同的模式调用相应的内部实现方法
    switch (mode) {
      case CaptureMode.region:
        return await _captureRegionInternal();

      case CaptureMode.window:
        return await _captureWindowInternal();

      case CaptureMode.fullscreen:
        return await _captureFullscreenInternal();

      case CaptureMode.freeform:
        _logger.w('Freeform capture not yet implemented');
        return null;

      case CaptureMode.scrolling:
        _logger.w('Scrolling capture not yet implemented');
        return null;

      case CaptureMode.longscroll:
        _logger.w(
            'Long scroll capture should be handled by LongScreenshotService, not CaptureService');
        return null;

      case CaptureMode.fixedSize:
        if (fixedSize == null) {
          _logger.e('Fixed size capture called without specifying a size');
          return null;
        }
        _logger.w('Fixed size capture not yet implemented');
        return null;

      default:
        _logger.w('Unsupported capture mode: $mode');
        return null;
    }
  }

  /// 全屏截图 - 内部实现
  Future<CaptureResult?> _captureFullscreenInternal() async {
    final double currentScale = _getCurrentDevicePixelRatio();
    const String modeLabel = 'fullscreen';
    _logger.d('Starting $modeLabel capture (internal)...');
    final tempFilePath = await _getTemporaryFilePath();
    _logger.d('Target temporary file: $tempFilePath');

    bool windowHidden = false;
    try {
      // 1. 隐藏自己的窗口以确保不出现在截图中
      windowHidden = await _hideWindowForCapture(modeLabel);

      // 2. 等待绘制完成
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. 执行截图操作
      final screenCapturer = screen_capturer.ScreenCapturer.instance;
      final captureData = await screenCapturer.capture(
        mode: screen_capturer.CaptureMode.screen,
        imagePath: tempFilePath,
      );

      // 4. 处理截图结果
      if (captureData != null && captureData.imagePath != null) {
        double captureScale = currentScale;

        // 5. 读取图片数据
        final file = File(captureData.imagePath!);
        if (!await file.exists()) {
          _logger.e('Captured file does not exist: ${captureData.imagePath}');
          return null;
        }

        final imageBytes = await file.readAsBytes();
        if (imageBytes.isEmpty) {
          _logger.e('Captured file is empty');
          return null;
        }

        _logger.i(
            'Fullscreen capture successful, size: ${imageBytes.length} bytes');

        // 6. 创建截图结果对象
        return CaptureResult(
          imageBytes: imageBytes,
          imagePath: captureData.imagePath,
          scale: captureScale,
        );
      } else {
        _logger.e('Failed to capture fullscreen');
        return null;
      }
    } catch (e) {
      _logger.e('Error in fullscreen capture', error: e);
      return null;
    } finally {
      // 恢复窗口显示，无论截图是否成功
      await _restoreWindowAfterCapture(windowHidden, modeLabel);
    }
  }

  /// 区域截图 - 内部实现
  Future<CaptureResult?> _captureRegionInternal() async {
    final double currentScale = _getCurrentDevicePixelRatio();
    const String modeLabel = 'region';
    _logger.d('Starting $modeLabel capture (internal)...');
    final tempFilePath = await _getTemporaryFilePath();
    _logger.d('Target temporary file: $tempFilePath');

    bool windowHidden = false;
    try {
      // 1. 隐藏自己的窗口以确保不出现在截图中
      windowHidden = await _hideWindowForCapture(modeLabel);

      // 2. 等待绘制完成
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. 执行截图操作
      final screenCapturer = screen_capturer.ScreenCapturer.instance;
      final captureData = await screenCapturer.capture(
        mode: screen_capturer.CaptureMode.region,
        imagePath: tempFilePath,
      );

      // 4. 处理截图结果
      if (captureData != null && captureData.imagePath != null) {
        double captureScale = currentScale;

        // 5. 读取图片数据
        final file = File(captureData.imagePath!);
        if (!await file.exists()) {
          _logger.e('Captured file does not exist: ${captureData.imagePath}');
          return null;
        }

        final imageBytes = await file.readAsBytes();
        if (imageBytes.isEmpty) {
          _logger.e('Captured file is empty');
          return null;
        }

        // 6. 获取选择区域信息
        Rect? logicalRect;
        CaptureRegion? region;

        // 注意：新版的screen_capturer API没有提供imagePosition
        // 使用图像尺寸和固定位置来创建区域信息
        if (captureData.imageWidth != null && captureData.imageHeight != null) {
          final width = captureData.imageWidth!.toDouble();
          final height = captureData.imageHeight!.toDouble();

          // 由于没有位置信息，将位置设置为0,0
          logicalRect = Rect.fromLTWH(0, 0, width, height);

          region = CaptureRegion(
            x: 0,
            y: 0,
            width: width,
            height: height,
          );
        }

        _logger.i(
            'Region capture successful, size: ${imageBytes.length} bytes, dimensions: ${captureData.imageWidth}x${captureData.imageHeight}');

        // 7. 创建截图结果对象
        return CaptureResult(
          imageBytes: imageBytes,
          imagePath: captureData.imagePath,
          region: region,
          logicalRect: logicalRect,
          scale: captureScale,
        );
      } else {
        _logger.e('Failed to capture region');
        return null;
      }
    } catch (e) {
      _logger.e('Error in region capture', error: e);
      return null;
    } finally {
      // 恢复窗口显示，无论截图是否成功
      await _restoreWindowAfterCapture(windowHidden, modeLabel);
    }
  }

  /// 窗口截图 - 内部实现
  Future<CaptureResult?> _captureWindowInternal() async {
    final double currentScale = _getCurrentDevicePixelRatio();
    const String modeLabel = 'window';
    _logger.d('Starting $modeLabel capture (internal)...');
    final tempFilePath = await _getTemporaryFilePath();
    _logger.d('Target temporary file: $tempFilePath');

    bool windowHidden = false;
    try {
      // 1. 隐藏自己的窗口以确保不出现在截图中
      windowHidden = await _hideWindowForCapture(modeLabel);

      // 2. 等待绘制完成
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. 执行截图操作
      final screenCapturer = screen_capturer.ScreenCapturer.instance;
      final captureData = await screenCapturer.capture(
        mode: screen_capturer.CaptureMode.window,
        imagePath: tempFilePath,
      );

      // 4. 处理截图结果
      if (captureData != null && captureData.imagePath != null) {
        double captureScale = currentScale;

        // 5. 读取图片数据
        final file = File(captureData.imagePath!);
        if (!await file.exists()) {
          _logger.e('Captured file does not exist: ${captureData.imagePath}');
          return null;
        }

        final imageBytes = await file.readAsBytes();
        if (imageBytes.isEmpty) {
          _logger.e('Captured file is empty');
          return null;
        }

        // 6. 获取选择区域信息
        Rect? logicalRect;
        CaptureRegion? region;

        // 注意：新版的screen_capturer API没有提供imagePosition
        // 使用图像尺寸和固定位置来创建区域信息
        if (captureData.imageWidth != null && captureData.imageHeight != null) {
          final width = captureData.imageWidth!.toDouble();
          final height = captureData.imageHeight!.toDouble();

          // 由于没有位置信息，将位置设置为0,0
          logicalRect = Rect.fromLTWH(0, 0, width, height);

          region = CaptureRegion(
            x: 0,
            y: 0,
            width: width,
            height: height,
          );
        }

        _logger.i(
            'Window capture successful, size: ${imageBytes.length} bytes, dimensions: ${captureData.imageWidth}x${captureData.imageHeight}');

        // 7. 创建截图结果对象
        return CaptureResult(
          imageBytes: imageBytes,
          imagePath: captureData.imagePath,
          region: region,
          logicalRect: logicalRect,
          scale: captureScale,
        );
      } else {
        _logger.e('Failed to capture window');
        return null;
      }
    } catch (e) {
      _logger.e('Error in window capture', error: e);
      return null;
    } finally {
      // 恢复窗口显示，无论截图是否成功
      await _restoreWindowAfterCapture(windowHidden, modeLabel);
    }
  }
}
