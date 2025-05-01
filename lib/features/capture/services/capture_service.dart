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

import '../data/models/capture_mode.dart';
import '../data/models/capture_result.dart';

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
      // 1. 检查权限 (保持不变)
      try {
        final isAccessAllowed =
            await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
        if (!isAccessAllowed) {
          _logger.w(
              'No screen capture permission before fullscreen capture. Requesting access...');
          await screen_capturer.ScreenCapturer.instance.requestAccess();

          final accessGranted =
              await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
          if (!accessGranted) {
            _logger.e(
                'User denied screen capture permission during fullscreen capture.');
            return null;
          }
        }
      } catch (permissionError) {
        _logger.w(
            'Error checking permission during $modeLabel capture: $permissionError - will try to capture anyway');
      }

      // 2. 隐藏窗口，使用透明化而不是最小化
      windowHidden = await _hideWindowForCapture(modeLabel);
      // 即使隐藏失败，windowHidden 可能是 false，但我们仍然继续

      // 3. 短暂延迟 (保持不变)
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. 调用 screen_capturer (保持不变)
      _logger.d('Calling screen_capturer.capture(mode: screen)...');
      final capturedData =
          await screen_capturer.ScreenCapturer.instance.capture(
        mode: screen_capturer.CaptureMode.screen,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: true,
      );

      // 5. 处理截图结果
      if (capturedData == null) {
        _logger
            .i('Fullscreen capture cancelled by user or failed (null data).');
        return null; // 用户可能取消了选择
      }

      _logger.d(
          'screen_capturer.capture finished. Image path: ${capturedData.imagePath}, Bytes length: ${capturedData.imageBytes?.length}');

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

      if (imageBytes == null && imagePath.isNotEmpty) {
        try {
          _logger.d('Reading image bytes from file: $imagePath');
          imageBytes = await File(imagePath).readAsBytes();
          _logger.d('Successfully read ${imageBytes.length} bytes from file.');
        } catch (e) {
          _logger.e('Failed to read image file: $e');
          return null;
        }
      }

      if (imageBytes == null) {
        _logger.e('Fullscreen capture failed to get image bytes.');
        return null;
      }

      // 6. 获取屏幕尺寸 (逻辑尺寸) - 使用 screen_retriever
      final display = await screenRetriever.getPrimaryDisplay();
      final screenWidth = display.size.width;
      final screenHeight = display.size.height;
      final logicalRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);
      _logger.d(
        'Primary display logical size: ${screenWidth}x$screenHeight, scale: ${display.scaleFactor}',
      );

      // 7. 创建并返回结果
      final result = CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        logicalRect: logicalRect,
        scale: currentScale,
      );
      _logger.i('Fullscreen capture successful');
      return result;
    } catch (e) {
      _logger.e('Fullscreen capture error', error: e);
      return null;
    } finally {
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
      windowHidden = await _hideWindowForCapture(modeLabel);
      await Future.delayed(const Duration(milliseconds: 200));

      _logger.d('Calling screen_capturer.capture(mode: region)...');
      final capturedData =
          await screen_capturer.ScreenCapturer.instance.capture(
        mode: screen_capturer.CaptureMode.region,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: true,
      );

      if (capturedData == null) {
        _logger.i('Region capture cancelled or failed (null data).');
        return null;
      }

      _logger.d(
        'Region capture finished. Image path: ${capturedData.imagePath}, imageWidth: ${capturedData.imageWidth}, imageHeight: ${capturedData.imageHeight}, Bytes length: ${capturedData.imageBytes?.length}',
      );

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

      if (imageBytes == null && imagePath.isNotEmpty) {
        try {
          _logger.d('Reading image bytes from file: $imagePath');
          imageBytes = await File(imagePath).readAsBytes();
          _logger.d('Successfully read ${imageBytes.length} bytes from file.');
        } catch (e) {
          _logger.e('Failed to read image file: $e');
          return null;
        }
      }

      if (imageBytes == null) {
        _logger.e('Region capture failed to get image bytes.');
        return null;
      }

      if (capturedData.imageWidth == null || capturedData.imageHeight == null) {
        _logger.e('Region capture failed to get capture dimensions.');
        return null;
      }

      // 计算逻辑Rect - 使用imageWidth和imageHeight
      final physicalWidth = capturedData.imageWidth!.toDouble();
      final physicalHeight = capturedData.imageHeight!.toDouble();
      // 对于区域截图，我们假设左上角是 (0,0) 因为没有提供rect
      final logicalRect = Rect.fromLTWH(
        0,
        0,
        physicalWidth / currentScale,
        physicalHeight / currentScale,
      );
      _logger.d(
        'Calculated logical Rect: $logicalRect from physical size: ${physicalWidth}x$physicalHeight with scale: $currentScale',
      );

      final result = CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        logicalRect: logicalRect,
        scale: currentScale,
      );

      _logger.i('Region capture successful');
      return result;
    } catch (e) {
      _logger.e('Region capture error', error: e);
      return null;
    } finally {
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
      windowHidden = await _hideWindowForCapture(modeLabel);
      await Future.delayed(const Duration(milliseconds: 200));

      _logger.d('Calling screen_capturer.capture(mode: window)...');
      final capturedData =
          await screen_capturer.ScreenCapturer.instance.capture(
        mode: screen_capturer.CaptureMode.window,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: true,
      );

      if (capturedData == null) {
        _logger.i('Window capture cancelled or failed (null data).');
        return null;
      }

      _logger.d(
        'Window capture finished. Image path: ${capturedData.imagePath}, imageWidth: ${capturedData.imageWidth}, imageHeight: ${capturedData.imageHeight}, Bytes length: ${capturedData.imageBytes?.length}',
      );

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

      if (imageBytes == null && imagePath.isNotEmpty) {
        try {
          _logger.d('Reading image bytes from file: $imagePath');
          imageBytes = await File(imagePath).readAsBytes();
          _logger.d('Successfully read ${imageBytes.length} bytes from file.');
        } catch (e) {
          _logger.e('Failed to read image file: $e');
          return null;
        }
      }

      if (imageBytes == null) {
        _logger.e('Window capture failed to get image bytes.');
        return null;
      }

      if (capturedData.imageWidth == null || capturedData.imageHeight == null) {
        _logger.e('Window capture failed to get capture dimensions.');
        return null;
      }

      // 计算逻辑Rect - 使用imageWidth和imageHeight
      final physicalWidth = capturedData.imageWidth!.toDouble();
      final physicalHeight = capturedData.imageHeight!.toDouble();
      // 对于窗口截图，我们假设左上角是 (0,0) 因为没有提供rect
      final logicalRect = Rect.fromLTWH(
        0,
        0,
        physicalWidth / currentScale,
        physicalHeight / currentScale,
      );
      _logger.d(
        'Calculated logical Rect: $logicalRect from physical size: ${physicalWidth}x$physicalHeight with scale: $currentScale',
      );

      final result = CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        logicalRect: logicalRect,
        scale: currentScale,
      );

      _logger.i('Window capture successful');
      return result;
    } catch (e) {
      _logger.e('Window capture error', error: e);
      return null;
    } finally {
      await _restoreWindowAfterCapture(windowHidden, modeLabel);
    }
  }
}
