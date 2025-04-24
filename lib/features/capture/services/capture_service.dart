import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'; // For Uint8List
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart' show WindowManager;
import 'package:logger/logger.dart';
import 'package:screen_capturer/screen_capturer.dart' as capturer;
import '../data/models/capture_mode.dart';
import '../data/models/capture_result.dart';
import '../presentation/widgets/freeform_selection.dart';
import '../presentation/widgets/screenshot_preview.dart';
import 'dart:math' as math;

/// 截图服务类
class CaptureService {
  /// 单例实例
  static final CaptureService instance = CaptureService._internal();
  final _windowManager = WindowManager.instance;
  final _logger = Logger();

  /// 全局导航键
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 平台通道
  static const platform = MethodChannel('com.snipwise/screenshot');

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

  /// 执行截图
  Future<CaptureResult?> capture(CaptureMode mode,
      {Size? fixedSize, Duration? delay}) async {
    try {
      // 如果设置了延时，等待指定时间
      if (delay != null) {
        await Future.delayed(delay);
      }

      CaptureResult? result;

      // 优先使用 screen_capturer 进行系统级截图 (适用于矩形区域、窗口和全屏)
      if (mode == CaptureMode.rectangle ||
          mode == CaptureMode.window ||
          mode == CaptureMode.fullscreen) {
        _logger.d('使用系统级截图模式: $mode');
        result = await _captureUsingScreenCapturer(mode);

        // 如果系统级截图失败，回退到旧方法
        if (result == null) {
          _logger.w('系统级截图失败，回退到应用级实现');
          result = await _fallbackCapture(mode);
        }
      } else {
        // 对于其他模式，使用现有实现
        result = await _fallbackCapture(mode);
      }

      return result;
    } catch (e) {
      _logger.e('Error capturing screenshot', error: e);
      return null;
    }
  }

  /// 回退到旧的截图实现
  Future<CaptureResult?> _fallbackCapture(CaptureMode mode) async {
    try {
      CaptureResult? result;
      switch (mode) {
        case CaptureMode.rectangle:
          result = await _captureRectangleInteractive(); // 调用旧的交互式方法
          break;
        case CaptureMode.freeform:
          // 自由形状使用修改后的逻辑
          result = await _captureFreeform();
          break;
        case CaptureMode.window:
          result = await _captureWindow();
          break;
        case CaptureMode.fullscreen:
          result = await _captureFullscreen();
          break;
        case CaptureMode.fixedSize:
          _logger.w(
              'Fixed size capture not yet implemented with native interaction.');
          result = null; // 暂不支持
          break;
        case CaptureMode.scrolling:
          result = await _captureScrolling();
          break;
      }
      return result;
    } catch (e) {
      _logger.e('Error in fallback capture', error: e);
      return null;
    }
  }

  /// 新的交互式矩形区域截图 (使用平台通道)
  Future<CaptureResult?> _captureRectangleInteractive() async {
    _logger.d('Starting interactive rectangle capture via platform channel...');
    try {
      // 1. 调用原生代码启动交互式选择
      final dynamic selectionResult =
          await platform.invokeMethod('startInteractiveCapture');

      if (selectionResult == null) {
        _logger.d('Interactive capture cancelled by user.');
        return null;
      }

      // 2. 解析返回的区域信息
      if (selectionResult is Map) {
        final rectMap = Map<String, dynamic>.from(selectionResult);
        final double x = rectMap['x'] as double? ?? 0.0;
        final double y = rectMap['y'] as double? ?? 0.0;
        final double width = rectMap['width'] as double? ?? 0.0;
        final double height = rectMap['height'] as double? ?? 0.0;

        // 确保尺寸有效
        if (width <= 0 || height <= 0) {
          _logger.e(
              'Received invalid rect dimensions from native: w=$width, h=$height');
          return null;
        }

        final selectedRegion =
            CaptureRegion(x: x, y: y, width: width, height: height);
        _logger.d('Received rectangle from native: $selectedRegion');

        // 3. 调用原生代码捕获指定区域
        final Uint8List? imageBytes =
            await platform.invokeMethod<Uint8List>('captureScreenRect', {
          'x': selectedRegion.x,
          'y': selectedRegion.y,
          'width': selectedRegion.width,
          'height': selectedRegion.height,
        });

        if (imageBytes == null || imageBytes.isEmpty) {
          _logger.e(
              'Failed to capture screen rect from native: imageBytes is null or empty.');
          return null;
        }

        _logger.d('Received ${imageBytes.length} bytes for captured rect.');

        // 4. 保存到临时文件并创建 CaptureResult
        final tempFilePath = await _getTemporaryFilePath();
        final file = File(tempFilePath);
        await file.writeAsBytes(imageBytes);

        _logger.d('Successfully captured and saved rectangle to $tempFilePath');

        return CaptureResult(
          imageBytes: imageBytes,
          imagePath: tempFilePath,
          region: selectedRegion,
        );
      } else {
        _logger.e(
            'Received unexpected result type from startInteractiveCapture: ${selectionResult.runtimeType}');
        return null;
      }
    } on PlatformException catch (e) {
      _logger.e(
          'Platform channel error during interactive capture: ${e.code} - ${e.message}',
          error: e.details);
      return null;
    } catch (e) {
      _logger.e('Error during interactive rectangle capture', error: e);
      return null;
    }
  }

  /// 全屏截图 (使用平台通道)
  Future<CaptureResult?> _captureFullscreen() async {
    _logger.d('Capturing fullscreen via platform channel...');
    try {
      // 调用原生方法捕获全屏 (传递 null 或特定指示符)
      final Uint8List? imageBytes =
          await platform.invokeMethod<Uint8List>('captureScreenRect', null);

      if (imageBytes == null || imageBytes.isEmpty) {
        _logger.e(
            'Failed to capture fullscreen from native: imageBytes is null or empty.');
        return null;
      }

      _logger.d('Received ${imageBytes.length} bytes for fullscreen capture.');

      final tempFilePath = await _getTemporaryFilePath();
      final file = File(tempFilePath);
      await file.writeAsBytes(imageBytes);

      // 获取屏幕尺寸信息 (如果原生方法不返回，则需要额外调用)
      final Rect screenBounds = await _getScreenBounds();

      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: tempFilePath,
        region: CaptureRegion(
          x: screenBounds.left,
          y: screenBounds.top,
          width: screenBounds.width,
          height: screenBounds.height,
        ),
      );
    } on PlatformException catch (e) {
      _logger.e(
          'Platform channel error during fullscreen capture: ${e.code} - ${e.message}',
          error: e.details);
      return null;
    } catch (e) {
      _logger.e('Error during fullscreen capture', error: e);
      return null;
    }
  }

  /// 获取屏幕边界 (使用平台通道)
  Future<Rect> _getScreenBounds() async {
    _logger.d('Getting screen bounds via platform channel...');
    try {
      final dynamic boundsResult =
          await platform.invokeMethod('getScreenBounds');
      if (boundsResult is Map) {
        final rectMap = Map<String, dynamic>.from(boundsResult);
        final double x = rectMap['x'] as double? ?? 0.0;
        final double y = rectMap['y'] as double? ?? 0.0;
        final double width = rectMap['width'] as double? ?? 0.0;
        final double height = rectMap['height'] as double? ?? 0.0;
        _logger.d('Received screen bounds: x=$x, y=$y, w=$width, h=$height');
        return Rect.fromLTWH(x, y, width, height);
      } else {
        _logger.e(
            'Unexpected result type from getScreenBounds: ${boundsResult.runtimeType}');
      }
    } on PlatformException catch (e) {
      _logger.e(
          'Platform channel error getting screen bounds: ${e.code} - ${e.message}',
          error: e.details);
    } catch (e) {
      _logger.e('Failed to get screen bounds from native', error: e);
    }
    // 回退或默认值
    _logger.w('Falling back to Rect.zero for screen bounds.');
    return Rect.zero;
  }

  /// 窗口截图 (使用平台通道)
  Future<CaptureResult?> _captureWindow() async {
    _logger.d('Capturing active window via platform channel...');
    try {
      final dynamic result = await platform.invokeMethod('captureActiveWindow');

      if (result is Map) {
        final resultMap = Map<String, dynamic>.from(result);
        final Uint8List? imageBytes = resultMap['imageBytes'] as Uint8List?;
        final Map<String, dynamic>? regionMap =
            resultMap['region'] as Map<String, dynamic>?;

        if (imageBytes == null || imageBytes.isEmpty || regionMap == null) {
          _logger.e('Invalid data received from native captureActiveWindow.');
          return null;
        }

        final tempFilePath = await _getTemporaryFilePath();
        final file = File(tempFilePath);
        await file.writeAsBytes(imageBytes);

        final region = CaptureRegion(
          x: regionMap['x'] as double? ?? 0.0,
          y: regionMap['y'] as double? ?? 0.0,
          width: regionMap['width'] as double? ?? 0.0,
          height: regionMap['height'] as double? ?? 0.0,
        );
        _logger.d('Captured active window, region: $region');

        return CaptureResult(
          imageBytes: imageBytes,
          imagePath: tempFilePath,
          region: region,
        );
      } else {
        _logger.e(
            'Unexpected result type from captureActiveWindow: ${result.runtimeType}');
        return null;
      }
    } on PlatformException catch (e) {
      _logger.e(
          'Platform channel error during window capture: ${e.code} - ${e.message}',
          error: e.details);
      return null;
    } catch (e) {
      _logger.e('Error during window capture', error: e);
      return null;
    }
  }

  /// 自由形状截图 (应用内选择 + 原生全屏截图 + 应用内裁剪)
  Future<CaptureResult?> _captureFreeform() async {
    _logger.d('Starting freeform capture (App UI Selection)...');
    try {
      // 1. 获取全屏截图 (使用原生方法)
      final fullscreenResult = await _captureFullscreen();
      if (fullscreenResult == null || fullscreenResult.imageBytes == null) {
        _logger.e('Failed to get fullscreen image for freeform capture.');
        return null;
      }

      final completer = Completer<CaptureResult?>();

      // 2. 显示应用内自由形状选择界面
      if (navigatorKey.currentContext != null &&
          navigatorKey.currentContext!.mounted) {
        _logger.d('Showing freeform selection UI...');
        showDialog<void>(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          useSafeArea: false,
          builder: (context) => Material(
            type: MaterialType.transparency,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
              child: FreeformSelection(
                // 传递背景图 Uint8List
                backgroundImageBytes: fullscreenResult.imageBytes!,
                onSelectionComplete: (result) async {
                  Navigator.of(context).pop();
                  if (result.region == null || result.path == null) {
                    _logger.d('Freeform selection cancelled or invalid.');
                    completer.complete(null);
                    return;
                  }
                  _logger.d(
                      'Freeform selection complete: region=${result.region}, path provided.');

                  // 3. 应用蒙版并裁剪 (使用重构后的方法)
                  final maskedResult = await _applyFreeformMask(
                    originalImageBytes: fullscreenResult.imageBytes!,
                    selectionPath: result.path!,
                    selectionBounds: result.region!.toRect(),
                  );
                  completer.complete(maskedResult);
                },
                onSelectionCancel: () {
                  _logger.d('Freeform selection cancelled by user.');
                  Navigator.of(context).pop();
                  completer.complete(null);
                },
              ),
            ),
          ),
        );
      } else {
        _logger.e('No valid context for freeform selection UI.');
        completer.complete(null);
      }
      return completer.future;
    } catch (e) {
      _logger.e('Error capturing freeform', error: e);
      return null;
    }
  }

  /// 应用自由形状蒙版 (处理 Uint8List)
  Future<CaptureResult?> _applyFreeformMask({
    required Uint8List originalImageBytes,
    required Path selectionPath, // 路径坐标是相对于应用内UI的
    required Rect selectionBounds, // 边界坐标也是相对于应用内UI的
  }) async {
    _logger.d('Applying freeform mask...');
    try {
      // 1. 解码原始全屏图像
      final codec = await ui.instantiateImageCodec(originalImageBytes);
      final frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      if (originalImage.width <= 0 || originalImage.height <= 0) {
        _logger.e('Invalid original image for masking.');
        return null;
      }
      _logger.d(
          'Original image for masking: ${originalImage.width}x${originalImage.height}');

      // 2. 准备绘制
      final recorder = ui.PictureRecorder();
      final width = math.max(1, selectionBounds.width.toInt());
      final height = math.max(1, selectionBounds.height.toInt());
      _logger.d('Mask canvas size: $width x $height');
      final canvas = Canvas(
          recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      // 3. 调整路径坐标 (平移到0,0)
      final Matrix4 transform = Matrix4.identity()
        ..translate(-selectionBounds.left, -selectionBounds.top);
      final translatedPath = selectionPath.transform(transform.storage);

      // 4. 绘制蒙版 (裁剪画布)
      canvas.clipPath(translatedPath);

      // 5. 绘制原始图像的对应部分
      final Rect srcRect = selectionBounds; // 假设选择坐标已对应屏幕坐标
      final Rect dstRect =
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
      canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());

      // 6. 获取结果图像
      final picture = recorder.endRecording();
      final ui.Image maskedImage = await picture.toImage(width, height);
      final byteData =
          await maskedImage.toByteData(format: ui.ImageByteFormat.png);

      // 清理资源
      originalImage.dispose();
      maskedImage.dispose();
      codec.dispose();

      if (byteData == null) {
        _logger.e('Failed to get byte data for masked image.');
        return null;
      }

      // 7. 保存并返回结果
      final tempFilePath = await _getTemporaryFilePath();
      final file = File(tempFilePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      _logger.d('Freeform masked image saved to $tempFilePath');

      return CaptureResult(
        imageBytes: byteData.buffer.asUint8List(),
        imagePath: tempFilePath,
        region: CaptureRegion(
          x: selectionBounds.left,
          y: selectionBounds.top,
          width: selectionBounds.width,
          height: selectionBounds.height,
        ),
      );
    } catch (e) {
      _logger.e('Error applying freeform mask', error: e);
      return null;
    }
  }

  /// 滚动截图 (依赖原生全屏截图)
  Future<CaptureResult?> _captureScrolling() async {
    _logger.d('Starting scrolling capture...');
    try {
      // 1. 获取初始截图（全屏）
      final initialCapture = await _captureFullscreen();
      if (initialCapture == null || initialCapture.imageBytes == null) {
        _logger.e('Failed to get initial fullscreen for scrolling capture.');
        return null;
      }

      _logger.w('Scrolling capture stitching not implemented yet.');

      return initialCapture; // 临时返回第一张图片
    } catch (e) {
      _logger.e('Error capturing scrolling', error: e);
      return null;
    }
  }

  /// 处理截图结果
  Future<void> handleCaptureResult(
      BuildContext context, CaptureResult? result) async {
    if (result == null) {
      _logger.w('截图结果为空');
      if (context.mounted) {
        await _showErrorDialog(context, '截图失败，请重试');
      }
      return;
    }

    if (result.imageBytes == null || result.imageBytes!.isEmpty) {
      _logger.w('截图结果没有图像数据');
      if (context.mounted) {
        await _showErrorDialog(context, '截图没有有效的图像数据');
      }
      return;
    }

    _logger.d('准备显示截图预览浮窗，图片大小: ${result.imageBytes!.length} 字节');

    if (!context.mounted) {
      _logger.e('Context 不再有效，无法显示预览');
      return;
    }

    // 使用悬浮窗显示截图预览
    _showScreenshotPreview(context, result);
  }

  /// 显示截图预览浮窗
  void _showScreenshotPreview(BuildContext context, CaptureResult result) {
    try {
      final screenSize = MediaQuery.of(context).size;
      _logger.d('创建预览浮窗，屏幕尺寸: ${screenSize.width}x${screenSize.height}');
      late final OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: 20,
          top: (screenSize.height - 600) / 2,
          child: Material(
            color: Colors.transparent,
            child: ScreenshotPreview(
              imageData: result.imageBytes!,
              imagePath: result.imagePath,
              onClose: () {
                _logger.d('关闭预览浮窗');
                overlayEntry.remove();
              },
            ),
          ),
        ),
      );

      _logger.d('将预览浮窗添加到Overlay');
      final overlay = Overlay.of(context);
      if (overlay != null) {
        overlay.insert(overlayEntry);
        _logger.d('预览浮窗已添加到界面');
      } else {
        _logger.e('无法获取有效的Overlay，预览浮窗添加失败');
      }
    } catch (e) {
      _logger.e('显示截图预览失败', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('显示截图预览失败: $e')),
        );
      }
    }
  }

  /// 显示错误对话框
  Future<void> _showErrorDialog(BuildContext context, String message) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 使用 screen_capturer 进行区域截图
  Future<CaptureResult?> _captureUsingScreenCapturer(CaptureMode mode) async {
    _logger.d('使用 screen_capturer 进行区域截图，模式: $mode');
    try {
      // 映射应用内的截图模式到 screen_capturer 的模式
      capturer.CaptureMode? scMode;
      switch (mode) {
        case CaptureMode.rectangle:
          scMode = capturer.CaptureMode.region; // 使用 screen_capturer 的区域截图模式
          break;
        case CaptureMode.window:
          scMode = capturer.CaptureMode.window;
          break;
        case CaptureMode.fullscreen:
          scMode = capturer.CaptureMode.screen;
          break;
        default:
          _logger.w('不支持的 screen_capturer 模式: $mode');
          return null;
      }

      if (scMode == null) {
        _logger.e('无法映射截图模式: $mode');
        return null;
      }

      // 临时文件路径，用于保存截图
      final tempFilePath = await _getTemporaryFilePath();

      // 调用 screen_capturer 进行截图
      final capturedData = await capturer.ScreenCapturer.instance.capture(
        mode: scMode,
        imagePath: tempFilePath,
        copyToClipboard: false, // 先不复制到剪贴板，后续由应用自己处理
        silent: false, // 显示系统UI用于选择
      );

      if (capturedData == null || capturedData.imagePath == null) {
        _logger.w('screen_capturer 截图返回结果为空或没有路径 (可能用户取消了操作)');
        return null;
      }

      _logger.d('screen_capturer 截图成功: ${capturedData.imagePath}');

      // 读取截图文件
      final file = File(capturedData.imagePath!);
      if (!await file.exists()) {
        _logger.e('截图文件不存在: ${capturedData.imagePath}');
        return null;
      }

      final imageBytes = await file.readAsBytes();
      if (imageBytes.isEmpty) {
        _logger.e('截图文件为空: ${capturedData.imagePath}');
        return null;
      }

      // 由于 screen_capturer 可能不提供区域信息，这里需要分析图像获取实际区域
      // 对于 region 模式，用户选择的区域就是整个图像，所以宽高是图像的尺寸
      // 这里需要解码图像来获取宽高信息
      final decodedImage = await decodeImageFromList(imageBytes);
      final region = CaptureRegion(
        x: 0, // screen_capturer 不提供具体坐标，这里设为0
        y: 0,
        width: decodedImage.width.toDouble(),
        height: decodedImage.height.toDouble(),
      );

      return CaptureResult(
        imageBytes: imageBytes,
        imagePath: capturedData.imagePath!, // 确保非空
        region: region,
      );
    } catch (e) {
      _logger.e('使用 screen_capturer 截图失败', error: e);
      return null;
    }
  }

  /// 测试 screen_capturer 区域截图功能
  Future<bool> testScreenCapturerRegion() async {
    _logger.d('测试 screen_capturer 区域截图功能');
    try {
      // 调用 screen_capturer 的区域截图功能
      final tempFilePath = await _getTemporaryFilePath();
      final capturedData = await capturer.ScreenCapturer.instance.capture(
        mode: capturer.CaptureMode.region,
        imagePath: tempFilePath,
        copyToClipboard: false,
        silent: false,
      );

      if (capturedData == null || capturedData.imagePath == null) {
        _logger.w('区域截图测试失败：未返回结果或路径为空');
        return false;
      }

      final file = File(capturedData.imagePath!);
      if (!await file.exists() || (await file.length()) == 0) {
        _logger.w('区域截图测试失败：文件不存在或为空');
        return false;
      }

      _logger.d('区域截图测试成功：${capturedData.imagePath}');
      return true;
    } catch (e) {
      _logger.e('区域截图测试出错', error: e);
      return false;
    }
  }
}
