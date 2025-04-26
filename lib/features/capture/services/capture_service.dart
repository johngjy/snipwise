import 'dart:async';
// import 'dart:ui' as ui; // Unused import
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart' show WindowManager;
import 'package:logger/logger.dart';
import 'package:screen_capturer/screen_capturer.dart' as screen_capturer;
import '../data/models/capture_mode.dart';
import '../data/models/capture_result.dart';
// import '../presentation/widgets/freeform_selection.dart'; // Unused import
// import '../presentation/widgets/screenshot_preview.dart'; // Unused import
// import 'dart:math' as math; // Unused import

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
    return path.join(tempDir.path, 'screenshot_$timestamp.png');
  }

  /// 辅助方法：隐藏窗口用于截图
  Future<bool> _hideWindowForCapture(String captureModeLabel) async {
    _logger.d('Attempting to hide window for $captureModeLabel capture...');
    try {
      await _windowManager.minimize();
      _logger.d('Window minimized for $captureModeLabel capture.');
      return true;
    } catch (windowError) {
      _logger.w(
          'Failed to minimize window for $captureModeLabel: $windowError - proceeding anyway');
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
        await Future.delayed(const Duration(milliseconds: 300));

        // 直接恢复窗口显示
        await _windowManager.show();
        await Future.delayed(const Duration(milliseconds: 200));

        // 尝试获取焦点
        await _windowManager.focus();
        _logger
            .d('Window successfully restored after $captureModeLabel capture.');
      } catch (restoreError) {
        _logger
            .e('Error restoring window after $captureModeLabel: $restoreError');
        // 尝试备用恢复方法
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          await _windowManager.show();
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
      case CaptureMode.rectangle:
        return _captureRegionInternal();

      case CaptureMode.window:
        return _captureWindowInternal();

      case CaptureMode.fullscreen:
        return _captureFullscreenInternal();

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

      // Removed unreachable default case
      // default:
      //   _logger.e('Unknown capture mode: $mode');
      //   return null;
    }
  }

  /// 全屏截图 - 内部实现
  Future<CaptureResult?> _captureFullscreenInternal() async {
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

      // 8. 构建并返回 CaptureResult (保持不变)
      _logger.d(
          'Fullscreen capture successful. Image size: ${imageBytes.length} bytes.');
      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: capturedData.imageWidth?.toDouble() ?? 0.0,
          height: capturedData.imageHeight?.toDouble() ?? 0.0,
        ),
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

      // 8. 构建并返回 CaptureResult (保持不变)
      _logger.d(
          'Window capture successful. Image size: ${imageBytes.length} bytes.');
      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        // 窗口截图返回的是目标窗口的图像
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: capturedData.imageWidth?.toDouble() ?? 0.0, // 使用插件返回的宽度
          height: capturedData.imageHeight?.toDouble() ?? 0.0, // 使用插件返回的高度
        ),
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
    const String modeLabel = 'region';
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

      // 3. 延迟 (保持不变)
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. 调用 screen_capturer (保持不变)
      _logger.d('Calling screen_capturer.capture(mode: region)...');
      final capturedData =
          await screen_capturer.ScreenCapturer.instance.capture(
        mode: screen_capturer.CaptureMode.region,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: false,
      );

      // 5. 处理截图结果 (保持不变)
      if (capturedData == null) {
        _logger.i('Region capture cancelled by user or failed (null data).');
        return null; // 用户可能取消了选择
      }

      _logger.d(
          'screen_capturer.capture finished. Image path: ${capturedData.imagePath}, Bytes length: ${capturedData.imageBytes?.length}');

      Uint8List? imageBytes = capturedData.imageBytes;
      String imagePath = capturedData.imagePath ?? tempFilePath;

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

      // 8. 构建并返回 CaptureResult (保持不变)
      _logger.d(
          'Region capture successful. Image size: ${imageBytes.length} bytes.');
      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: imagePath,
        // 对于区域截图，返回的图像通常就是选定区域本身
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: capturedData.imageWidth?.toDouble() ?? 0.0,
          height: capturedData.imageHeight?.toDouble() ?? 0.0,
        ),
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
  void _navigateToEditor(BuildContext context, CaptureResult result) {
    try {
      // 确保我们有有效的 context
      if (!context.mounted) {
        _logger.e('Cannot navigate to editor, context is unmounted.');
        return;
      }

      // 使用 Navigator 导航到编辑页面
      Navigator.pushNamed(
        context,
        '/editor', // 根据您的路由配置调整路由名称
        arguments: {
          'imageData': result.imageBytes,
          'imagePath': result.imagePath,
          'region': result.region,
        },
      );

      _logger.d('Navigated to editor page with screenshot data.');
    } catch (e, stackTrace) {
      _logger.e('Error navigating to editor page',
          error: e, stackTrace: stackTrace);

      // 向用户显示错误
      if (context.mounted) {
        _showErrorDialog(context, '无法打开编辑器: ${e.toString()}');
      }
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
