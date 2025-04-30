import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:screen_capturer/screen_capturer.dart' as screen_capturer;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/platform_channel.dart';
import '../data/models/capture_mode.dart';
import '../data/models/capture_result.dart';

/// 截图服务类
class CaptureService {
  /// 单例实例
  static final CaptureService instance = CaptureService._internal();
  final _windowManager = WindowManager.instance;
  final _platformService = PlatformChannelService.instance;
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
    _logger.d('尝试隐藏窗口进行截图: $captureModeLabel');
    try {
      // 使用平台通道服务隐藏窗口，而不是最小化
      final result = await _platformService.hideWindow();
      if (result) {
        _logger.d('窗口已通过原生通道隐藏用于$captureModeLabel截图');
      } else {
        _logger.w('通过原生通道隐藏窗口失败');
        // 回退到旧方法
        await _windowManager.minimize();
        _logger.d('回退: 窗口已最小化用于$captureModeLabel截图');
      }
      return true;
    } catch (windowError) {
      _logger.w('隐藏窗口失败: $windowError - 继续尝试截图');
      return false;
    }
  }

  /// 辅助方法：截图后恢复窗口
  Future<void> _restoreWindowAfterCapture(
      bool windowWasHidden, String captureModeLabel) async {
    _logger.d('$captureModeLabel截图完成: 恢复窗口...');
    if (windowWasHidden) {
      try {
        // 等待足够长时间以确保截图操作完成
        await Future.delayed(const Duration(milliseconds: 300));

        // 使用平台通道服务显示并激活窗口
        final result = await _platformService.showAndActivateWindow();
        if (result) {
          _logger.d('窗口已通过原生通道显示并激活');
        } else {
          _logger.w('通过原生通道显示窗口失败，尝试使用窗口管理器');
          // 回退到旧方法
          await _windowManager.show();
          await Future.delayed(const Duration(milliseconds: 200));
          await _windowManager.focus();
          _logger.d('回退: 窗口已通过窗口管理器显示');
        }
      } catch (restoreError) {
        _logger.e('恢复窗口时发生错误: $restoreError');
        // 尝试备用恢复方法
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          await _windowManager.show();
          _logger.d('备用窗口恢复成功');
        } catch (e) {
          _logger.e('备用窗口恢复失败: $e');
        }
      }
    } else {
      _logger.d('窗口未隐藏，无需恢复');
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

      // 2. 隐藏窗口
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

      // 5. 处理截图结果 (保持不变)
      if (capturedData == null) {
        _logger.w(
            'Fullscreen capture returned null data. Capture might have failed or been cancelled.');
        return null;
      }

      _logger.d(
          'screen_capturer.capture finished. Image path: ${capturedData.imagePath}, Bytes length: ${capturedData.imageBytes?.length}');

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

      // 6. 检查图像数据，如果直接返回的数据为空，尝试从文件读取
      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.w(
            'No direct imageBytes returned. Attempting to read from file: $imagePath');
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
            if (imageBytes.isNotEmpty) {
              _logger
                  .d('Successfully read ${imageBytes.length} bytes from file.');
            } else {
              _logger.e('File exists but is empty: $imagePath');
              imageBytes = null;
            }
          } else {
            _logger.e('Capture file does not exist at path: $imagePath');
            imageBytes = null;
          }
        } catch (fileError) {
          _logger.e('Error reading capture file: $imagePath', error: fileError);
          imageBytes = null;
        }
      }

      // 7. 如果最终没有图像数据，则截图失败
      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.e('Failed to obtain image data for fullscreen capture.');
        return null;
      }

      // 8. 构建并返回 CaptureResult
      _logger.d(
          'Fullscreen capture successful. Image size: ${imageBytes.length} bytes. Scale: $currentScale');
      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: capturedData.imageWidth?.toDouble() ?? 0.0,
          height: capturedData.imageHeight?.toDouble() ?? 0.0,
        ),
        scale: currentScale,
      );
    } catch (e, stackTrace) {
      _logger.e('Error during $modeLabel capture internal process',
          error: e, stackTrace: stackTrace);
      return null;
    } finally {
      // 9. 恢复窗口
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
      // 1. 检查权限 (保持不变)
      try {
        final isAccessAllowed =
            await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
        if (!isAccessAllowed) {
          _logger.w(
              'No screen capture permission before window capture. Requesting access...');
          await screen_capturer.ScreenCapturer.instance.requestAccess();

          // 权限请求后我们需要重新检查
          final accessGranted =
              await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
          if (!accessGranted) {
            _logger.e(
                'User denied screen capture permission during window capture.');
            return null;
          }
        }
      } catch (permissionError) {
        _logger.w(
            'Error checking permission during $modeLabel capture: $permissionError - will try to capture anyway');
      }

      // 2. 隐藏窗口
      windowHidden = await _hideWindowForCapture(modeLabel);

      // 3. 延迟 (保持不变)
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. 调用 screen_capturer (保持不变)
      _logger.d('Calling screen_capturer.capture(mode: window)...');
      final capturedData =
          await screen_capturer.ScreenCapturer.instance.capture(
        mode: screen_capturer.CaptureMode.window,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: false,
      );

      // 5. 处理截图结果 (保持不变)
      if (capturedData == null) {
        _logger.i('Window capture cancelled by user or failed (null data).');
        return null; // 用户可能取消了选择
      }

      _logger.d(
          'screen_capturer.capture finished. Image path: ${capturedData.imagePath}, Bytes length: ${capturedData.imageBytes?.length}');

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

      // 6. 检查图像数据，如果直接返回的数据为空，尝试从文件读取
      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.w(
            'No direct imageBytes returned for window capture. Attempting to read from file: $imagePath');
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
            if (imageBytes.isNotEmpty) {
              _logger
                  .d('Successfully read ${imageBytes.length} bytes from file.');
            } else {
              _logger.e('Window capture file exists but is empty: $imagePath');
              imageBytes = null;
            }
          } else {
            _logger.e('Window capture file does not exist at path: $imagePath');
            imageBytes = null;
          }
        } catch (fileError) {
          _logger.e('Error reading window capture file: $imagePath',
              error: fileError);
          imageBytes = null;
        }
      }

      // 7. 如果最终没有图像数据，则截图失败
      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.e('Failed to obtain image data for window capture.');
        return null;
      }

      // 8. 构建并返回 CaptureResult
      _logger.d(
          'Window capture successful. Image size: ${imageBytes.length} bytes. Scale: $currentScale');
      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: capturedData.imageWidth?.toDouble() ?? 0.0,
          height: capturedData.imageHeight?.toDouble() ?? 0.0,
        ),
        scale: currentScale,
      );
    } catch (e, stackTrace) {
      _logger.e('Error during $modeLabel capture internal process',
          error: e, stackTrace: stackTrace);
      return null;
    } finally {
      // 9. 恢复窗口
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
    _logger.d('Current screen scale (DPR): $currentScale');

    bool windowHidden = false;
    try {
      // 1. 检查权限
      try {
        final isAccessAllowed =
            await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
        _logger.d('Screen capture access allowed: $isAccessAllowed');

        if (!isAccessAllowed) {
          _logger.w(
              'No screen capture permission before capture. Requesting access...');
          await screen_capturer.ScreenCapturer.instance.requestAccess();

          // 权限请求后我们需要重新检查
          final accessGranted =
              await screen_capturer.ScreenCapturer.instance.isAccessAllowed();
          if (!accessGranted) {
            _logger.e('User denied screen capture permission during capture.');
            return null;
          }
        }
      } catch (permissionError) {
        _logger.w(
            'Error checking permission during $modeLabel capture: $permissionError - will try to capture anyway');
      }

      // 2. 隐藏窗口
      windowHidden = await _hideWindowForCapture(modeLabel);

      // 3. 延迟
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. 调用 screen_capturer
      _logger.d('Calling screen_capturer.capture(mode: region)...');
      final capturedData =
          await screen_capturer.ScreenCapturer.instance.capture(
        mode: screen_capturer.CaptureMode.region,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: false,
      );

      // 5. 处理截图结果
      if (capturedData == null) {
        _logger.i('Region capture cancelled by user or failed (null data).');
        return null; // 用户可能取消了选择
      }

      _logger.d(
          'screen_capturer.capture finished. Image path: ${capturedData.imagePath}, Bytes length: ${capturedData.imageBytes?.length}');

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

      // 获取物理像素位置和尺寸
      double physicalX = 0;
      double physicalY = 0;
      double physicalWidth = capturedData.imageWidth?.toDouble() ?? 0.0;
      double physicalHeight = capturedData.imageHeight?.toDouble() ?? 0.0;

      // 计算逻辑矩形 - 将物理像素坐标转换为逻辑坐标
      Rect? logicalRect;
      if (physicalWidth > 0 && physicalHeight > 0) {
        logicalRect = Rect.fromLTWH(
            physicalX / currentScale,
            physicalY / currentScale,
            physicalWidth / currentScale,
            physicalHeight / currentScale);
        _logger.d('Calculated logical rect: $logicalRect');
      }

      // 6. 检查图像数据，如果直接返回的数据为空，尝试从文件读取
      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.w(
            'No direct imageBytes returned for region capture. Attempting to read from file: $imagePath');
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
            if (imageBytes.isNotEmpty) {
              _logger
                  .d('Successfully read ${imageBytes.length} bytes from file.');
            } else {
              _logger.e('Region capture file exists but is empty: $imagePath');
              imageBytes = null;
            }
          } else {
            _logger.e('Region capture file does not exist at path: $imagePath');
            imageBytes = null;
          }
        } catch (fileError) {
          _logger.e('Error reading region capture file: $imagePath',
              error: fileError);
          imageBytes = null;
        }
      }

      // 7. 如果最终没有图像数据，则截图失败
      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.e('Failed to obtain image data for region capture.');
        return null;
      }

      // 8. 构建并返回 CaptureResult
      _logger.d(
          'Region capture successful. Image size: ${imageBytes.length} bytes. Scale: $currentScale');
      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: physicalWidth,
          height: physicalHeight,
        ),
        scale: currentScale,
        logicalRect: logicalRect,
      );
    } catch (e, stackTrace) {
      _logger.e('Error during $modeLabel capture internal process',
          error: e, stackTrace: stackTrace);
      return null;
    } finally {
      // 9. 恢复窗口
      await _restoreWindowAfterCapture(windowHidden, modeLabel);
    }
  }

  /// 显示截图预览
  Future<void> showScreenshotPreviewDialog(
      BuildContext context, CaptureMode mode) async {
    _logger.d('Preparing to capture screenshot, mode: $mode');

    // 执行截图 (调用我们的核心 capture 方法)
    final CaptureResult? result = await capture(mode);

    // 检查 context 是否仍然有效
    if (!context.mounted) {
      _logger.w('Context unmounted after capture, cannot navigate to editor.');
      return;
    }

    // 检查截图结果
    if (result == null) {
      _logger.w(
          'Capture result is null (failed or cancelled), capture operation aborted.');
      return;
    }

    if (result.imageBytes == null || result.imageBytes!.isEmpty) {
      _logger.w('Capture result has no valid image data.');
      await _showErrorDialog(
          context, 'Failed to get valid image data from screenshot.');
      return;
    }

    _logger.d(
        'Capture successful. Image size: ${result.imageBytes!.length} bytes. Navigating to editor.');

    // 直接导航到编辑页面，而不是显示预览
    _navigateToEditor(context, result);
  }

  /// 执行截图并导航到编辑器
  Future<void> captureAndNavigateToEditor(
      BuildContext context, CaptureMode mode) async {
    _logger.d('Preparing to capture screenshot, mode: $mode');

    // 执行截图 (调用我们的核心 capture 方法)
    final CaptureResult? result = await capture(mode);

    // 检查 context 是否仍然有效
    if (!context.mounted) {
      _logger.w('Context unmounted after capture, cannot navigate to editor.');
      return;
    }

    // 检查截图结果
    if (result == null) {
      _logger.w(
          'Capture result is null (failed or cancelled), capture operation aborted.');
      return;
    }

    if (result.imageBytes == null || result.imageBytes!.isEmpty) {
      _logger.w('Capture result has no valid image data.');
      await _showErrorDialog(
          context, 'Failed to get valid image data from screenshot.');
      return;
    }

    _logger.d(
        'Capture successful. Image size: ${result.imageBytes!.length} bytes. Navigating to editor.');

    // 直接导航到编辑页面，而不是显示预览
    _navigateToEditor(context, result);
  }

  /// 导航到编辑页面
  Future<bool> _navigateToEditor(
    BuildContext context,
    CaptureResult result,
  ) async {
    try {
      if (!context.mounted) {
        _logger.e('Context is not mounted. Cannot navigate to editor.');
        return false;
      }

      _logger.d(
          'Navigating to editor with image data of ${result.imageBytes?.length} bytes, scale: ${result.scale}, logicalRect: ${result.logicalRect}');

      final args = {
        'imageData': result.imageBytes,
        'imagePath': result.imagePath,
        'scale': result.scale,
        'logicalRect': result.logicalRect,
      };

      Navigator.of(context).pushNamed('/editor', arguments: args);
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to navigate to editor',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 显示错误对话框 (保留)
  Future<void> _showErrorDialog(BuildContext context, String message) async {
    if (!context.mounted) return; // 检查context有效性
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('截图错误'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
