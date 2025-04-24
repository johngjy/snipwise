import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart' show WindowManager;
import 'package:screen_capturer/screen_capturer.dart' as capturer;
import 'package:logger/logger.dart';
import '../data/models/capture_mode.dart';
import '../data/models/capture_result.dart';
import '../presentation/widgets/rectangle_selection.dart';
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

      // 在截图前最小化窗口
      await _windowManager.minimize();

      // 等待一小段时间让窗口完全最小化
      await Future.delayed(const Duration(milliseconds: 500));

      CaptureResult? result;
      switch (mode) {
        case CaptureMode.rectangle:
          result = await _captureRectangle();
          break;
        case CaptureMode.freeform:
          result = await _captureFreeform();
          break;
        case CaptureMode.window:
          result = await _captureWindow();
          break;
        case CaptureMode.fullscreen:
          result = await _captureFullscreen();
          break;
        case CaptureMode.fixedSize:
          if (fixedSize != null) {
            result = await _captureFixedSize(fixedSize);
          }
          break;
        case CaptureMode.scrolling:
          result = await _captureScrolling();
          break;
      }

      // 恢复窗口
      await _windowManager.restore();

      return result;
    } catch (e) {
      _logger.e('Error capturing screenshot', error: e);
      // 确保窗口被恢复
      await _windowManager.restore();
      return null;
    }
  }

  /// 矩形区域截图
  Future<CaptureResult?> _captureRectangle() async {
    try {
      // 获取临时文件路径
      final tempFilePath = await _getTemporaryFilePath();

      // 获取全屏截图作为背景
      final screenCapture = await capturer.ScreenCapturer.instance.capture(
        mode: capturer.CaptureMode.screen,
        copyToClipboard: false,
        silent: true,
        imagePath: tempFilePath,
      );

      if (screenCapture == null || screenCapture.imageBytes == null) {
        _logger.e('Failed to capture screen: no image data');
        return null;
      }

      final completer = Completer<CaptureResult?>();

      // 创建一个新的 MaterialApp 来显示选择界面
      if (navigatorKey.currentContext != null) {
        _logger.d('准备显示矩形选择界面，图片字节大小: ${screenCapture.imageBytes!.length}');

        try {
          showDialog<void>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            useSafeArea: false, // 确保全屏显示
            builder: (context) => Material(
              type: MaterialType.transparency,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
                child: RectangleSelection(
                  backgroundImage: screenCapture.imageBytes!,
                  onSelected: (rect) async {
                    Navigator.of(context).pop();
                    _logger.d('用户选择了区域: $rect');
                    final result = await _completeRectangleCapture(
                      screenCapture,
                      rect,
                    );
                    completer.complete(result);
                  },
                  onCancel: () {
                    _logger.d('用户取消了选择');
                    Navigator.of(context).pop();
                    completer.complete(null);
                  },
                ),
              ),
            ),
          );
        } catch (e) {
          _logger.e('显示选择界面失败: $e', error: e);
          completer.complete(null);
        }
      } else {
        _logger.e('No valid context found for showing selection dialog');
        completer.complete(null);
      }

      return completer.future;
    } catch (e) {
      _logger.e('Error capturing rectangle', error: e);
      return null;
    }
  }

  /// 完成矩形区域截图
  Future<CaptureResult?> _completeRectangleCapture(
    dynamic screenCapture,
    Rect selectedRect,
  ) async {
    try {
      // 验证输入参数
      if (screenCapture == null || screenCapture.imageBytes == null) {
        _logger.e('Screen capture or image bytes is null');
        return null;
      }

      // 确保选择区域有有效的维度
      if (selectedRect.width <= 0 || selectedRect.height <= 0) {
        _logger.e(
            'Invalid rectangle dimensions: ${selectedRect.width}x${selectedRect.height}');

        // 给用户提供一个最小的有效截图，而不是返回null
        try {
          final originalImage =
              await decodeImageFromList(screenCapture.imageBytes!);
          return await _createMinimalCaptureResult(originalImage);
        } catch (e) {
          _logger.e('Failed to create minimal capture: $e');
          return null;
        }
      }

      _logger.d('Processing selection: $selectedRect');

      // 先解码原始图像
      ui.Image? originalImage;
      try {
        originalImage = await decodeImageFromList(screenCapture.imageBytes!);
      } catch (e) {
        _logger.e('Failed to decode image: $e');
        return null;
      }

      if (originalImage == null) {
        _logger.e('Failed to decode original image: result is null');
        return null;
      }

      // 记录原始图像尺寸
      final originalWidth = originalImage.width;
      final originalHeight = originalImage.height;
      _logger
          .d('Original image dimensions: ${originalWidth}x${originalHeight}');

      // 安全检查：确保原始图像有效
      if (originalWidth <= 0 || originalHeight <= 0) {
        _logger.e(
            'Invalid original image dimensions: ${originalWidth}x${originalHeight}');
        return null;
      }

      // 计算源矩形的安全值 - 确保在图像内部
      final double safeLeft = selectedRect.left.clamp(0.0, originalWidth - 1.0);
      final double safeTop = selectedRect.top.clamp(0.0, originalHeight - 1.0);

      // 明确确保宽高至少为1，且不超出图像范围
      final double safeWidth =
          math.max(1.0, math.min(selectedRect.width, originalWidth - safeLeft));
      final double safeHeight = math.max(
          1.0, math.min(selectedRect.height, originalHeight - safeTop));

      // 构建安全的源矩形
      final Rect srcRect =
          Rect.fromLTWH(safeLeft, safeTop, safeWidth, safeHeight);
      _logger.d('Using adjusted source rect: $srcRect');

      // 额外安全检查：如果源矩形仍然无效，则使用最小图像
      if (srcRect.width < 1 || srcRect.height < 1) {
        _logger.e('Adjusted source rect still invalid: $srcRect');
        return await _createMinimalCaptureResult(originalImage);
      }

      try {
        // 绘制选中区域
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);

        canvas.drawImageRect(
          originalImage,
          srcRect,
          dstRect,
          Paint(),
        );

        // 完成绘制并获取图像
        final picture = recorder.endRecording();

        // 确保宽高是整数且至少为1像素
        final int width = math.max(1, srcRect.width.toInt());
        final int height = math.max(1, srcRect.height.toInt());

        _logger.d('Creating image with dimensions: $width x $height');

        ui.Image? image;
        try {
          image = await picture.toImage(width, height);
        } catch (e) {
          _logger.e('Error in toImage: $e', error: e);
          // 如果转换失败，尝试创建最小结果
          return await _createMinimalCaptureResult(originalImage);
        }

        if (image == null) {
          _logger.e('Failed to create image from picture: result is null');
          return await _createMinimalCaptureResult(originalImage);
        }

        // 获取图像数据
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          _logger.e('Failed to get byte data from image');
          return await _createMinimalCaptureResult(originalImage);
        }

        // 获取临时文件路径用于保存结果
        final tempFilePath = await _getTemporaryFilePath();

        // 保存图像到文件
        final file = File(tempFilePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        _logger.d('Successfully created capture result');

        // 使用安全的维度创建CaptureRegion
        return CaptureResult(
          imageBytes: byteData.buffer.asUint8List(),
          imagePath: tempFilePath,
          region: CaptureRegion(
            x: srcRect.left,
            y: srcRect.top,
            width: srcRect.width,
            height: srcRect.height,
          ),
        );
      } catch (e) {
        _logger.e('Error in processing capture: $e', error: e);
        // 如果处理过程中出错，仍然尝试返回最小图像
        return await _createMinimalCaptureResult(originalImage);
      }
    } catch (e) {
      _logger.e('Error completing rectangle capture: $e', error: e);
      return null;
    }
  }

  /// 创建最小的1x1像素捕获结果（作为失败时的备选方案）
  Future<CaptureResult?> _createMinimalCaptureResult(
      ui.Image originalImage) async {
    try {
      _logger.d('Creating minimal capture result as fallback');

      // 创建一个小图像（使用16x16而不是1x1，可能更适合显示）
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 尝试从原始图像中截取有意义的部分
      final srcRect = Rect.fromLTWH(
          0,
          0,
          math.min(16, originalImage.width.toDouble()),
          math.min(16, originalImage.height.toDouble()));
      const dstRect = Rect.fromLTWH(0, 0, 16, 16);

      canvas.drawImageRect(
        originalImage,
        srcRect,
        dstRect,
        Paint(),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(16, 16);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _logger.e('Failed to get fallback image data');
        return null;
      }

      // 获取临时文件路径
      final tempFilePath = await _getTemporaryFilePath();

      // 保存到文件
      final file = File(tempFilePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return CaptureResult(
        imageBytes: byteData.buffer.asUint8List(),
        imagePath: tempFilePath,
        region: const CaptureRegion(
          x: 0,
          y: 0,
          width: 16,
          height: 16,
        ),
      );
    } catch (e) {
      _logger.e('Error creating minimal capture result: $e', error: e);
      return null;
    }
  }

  /// 捕获选定区域的截图
  Future<CaptureResult?> _captureSelectedRegion(CaptureRegion region) async {
    try {
      // 获取临时文件路径
      final tempFilePath = await _getTemporaryFilePath();

      // 创建一个 RepaintBoundary 来渲染选中区域
      final boundary = RepaintBoundary(
        child: Positioned(
          left: region.x.toDouble(),
          top: region.y.toDouble(),
          width: region.width.toDouble(),
          height: region.height.toDouble(),
          child: SizedBox(
            width: region.width.toDouble(),
            height: region.height.toDouble(),
          ),
        ),
      );

      // 将 RepaintBoundary 转换为图像
      final buildContext = navigatorKey.currentContext;
      if (buildContext == null) return null;

      // 使用 BuildContext 前再次检查是否已被销毁
      if (!buildContext.mounted) return null;

      final renderObject = boundary.createRenderObject(buildContext);
      renderObject.layout(BoxConstraints.tight(Size(
        region.width.toDouble(),
        region.height.toDouble(),
      )));

      final image = await renderObject.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return CaptureResult(
          imageBytes: byteData.buffer.asUint8List(),
          imagePath: tempFilePath,
          region: region,
        );
      }
      return null;
    } catch (e) {
      _logger.e('Error capturing selected region', error: e);
      return null;
    }
  }

  /// 自由形状截图
  Future<CaptureResult?> _captureFreeform() async {
    try {
      final completer = Completer<CaptureResult?>();

      // 创建一个覆盖全屏的透明窗口来显示选择界面
      late final OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => FreeformSelection(
          onSelectionComplete: (result) async {
            overlayEntry.remove();
            if (result.region == null || result.path == null) {
              completer.complete(null);
              return;
            }

            final capturedRegion = await _captureSelectedRegion(CaptureRegion(
              x: result.region!.x,
              y: result.region!.y,
              width: result.region!.width,
              height: result.region!.height,
            ));
            if (capturedRegion == null || capturedRegion.region == null) {
              completer.complete(null);
              return;
            }

            final size = Size(
              capturedRegion.region!.width,
              capturedRegion.region!.height,
            );

            final maskedImage = await _applyFreeformMask(
              capture: capturedRegion,
              size: size,
              path: result.path!,
            );
            completer.complete(maskedImage);
          },
          onSelectionCancel: () {
            overlayEntry.remove();
            completer.complete(null);
          },
        ),
      );

      // 显示选择界面
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = WidgetsBinding.instance.rootElement;
        if (context != null) {
          Overlay.of(context).insert(overlayEntry);
        }
      });

      return completer.future;
    } catch (e) {
      _logger.e('Error capturing freeform', error: e);
      return null;
    }
  }

  /// 应用自由形状蒙版
  Future<CaptureResult?> _applyFreeformMask({
    required CaptureResult capture,
    required Size size,
    required Path path,
  }) async {
    if (capture.imageBytes == null) return null;

    final buildContext = navigatorKey.currentContext;
    if (buildContext == null) return null;

    // 创建一个 RepaintBoundary 来渲染蒙版区域
    final boundary = RepaintBoundary(
      child: CustomPaint(
        painter: _MaskPainter(
          imageBytes: capture.imageBytes!,
          maskPath: path,
        ),
        size: size,
      ),
    );

    // 将 RepaintBoundary 转换为图像
    final renderObject = boundary.createRenderObject(buildContext);
    renderObject.layout(BoxConstraints.tight(size));

    final image = await renderObject.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    return CaptureResult(
      imageBytes: byteData.buffer.asUint8List(),
      imagePath: capture.imagePath,
      region: capture.region,
    );
  }

  /// 窗口截图
  Future<CaptureResult?> _captureWindow() async {
    try {
      // 获取临时文件路径
      final tempFilePath = await _getTemporaryFilePath();

      // 获取当前活动窗口
      final capture = await capturer.ScreenCapturer.instance.capture(
        mode: capturer.CaptureMode.window,
        copyToClipboard: true,
        silent: true,
        imagePath: tempFilePath,
      );

      if (capture != null) {
        // 获取窗口大小
        final window = await _windowManager.getBounds();
        return CaptureResult(
          imageBytes: capture.imageBytes,
          imagePath: tempFilePath,
          region: CaptureRegion(
            x: window.left,
            y: window.top,
            width: window.width,
            height: window.height,
          ),
        );
      }
      _logger.e('Failed to capture window: no capture data');
      return null;
    } catch (e) {
      _logger.e('Error capturing window', error: e);
      return null;
    }
  }

  /// 全屏截图
  Future<CaptureResult?> _captureFullscreen() async {
    try {
      // 获取临时文件路径
      final tempFilePath = await _getTemporaryFilePath();

      final capture = await capturer.ScreenCapturer.instance.capture(
        mode: capturer.CaptureMode.screen,
        copyToClipboard: true,
        silent: true,
        imagePath: tempFilePath,
      );

      if (capture != null) {
        // 安全地获取浏览上下文
        final context = navigatorKey.currentContext;
        if (context == null) {
          _logger.e('无法获取有效的导航上下文');
          return null;
        }

        if (!context.mounted) {
          _logger.e('导航上下文已不再有效');
          return null;
        }

        final window = View.of(context);
        final size = window.physicalSize;
        return CaptureResult(
          imageBytes: capture.imageBytes,
          imagePath: tempFilePath,
          region: CaptureRegion(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height,
          ),
        );
      }
      _logger.e('Failed to capture fullscreen: no capture data');
      return null;
    } catch (e) {
      _logger.e('Error capturing fullscreen', error: e);
      return null;
    }
  }

  /// 固定尺寸截图
  Future<CaptureResult?> _captureFixedSize(Size size) async {
    try {
      // 获取全屏截图作为背景
      final screenCapture = await capturer.ScreenCapturer.instance.capture(
        mode: capturer.CaptureMode.screen,
        copyToClipboard: false,
        silent: true,
      );

      if (screenCapture == null || screenCapture.imageBytes == null) {
        return null;
      }

      final completer = Completer<CaptureResult?>();

      // 创建一个新的 MaterialApp 来显示选择界面
      if (navigatorKey.currentContext != null) {
        showDialog<void>(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) => Material(
            type: MaterialType.transparency,
            child: RectangleSelection(
              backgroundImage: screenCapture.imageBytes!,
              onSelected: (rect) async {
                Navigator.pop(context);
                final result = await _captureSelectedRegion(CaptureRegion(
                  x: rect.left,
                  y: rect.top,
                  width: size.width,
                  height: size.height,
                ));
                completer.complete(result);
              },
              onCancel: () {
                Navigator.pop(context);
                completer.complete(null);
              },
            ),
          ),
        );
      } else {
        completer.complete(null);
      }

      return completer.future;
    } catch (e) {
      _logger.e('Error capturing fixed size', error: e);
      return null;
    }
  }

  /// 滚动截图
  Future<CaptureResult?> _captureScrolling() async {
    try {
      // 获取当前窗口的滚动信息
      final initialCapture = await capturer.ScreenCapturer.instance.capture(
        mode: capturer.CaptureMode.screen,
        copyToClipboard: true,
        silent: true,
      );

      if (initialCapture == null || initialCapture.imageBytes == null) {
        return null;
      }

      // 解码图像以获取尺寸
      final image = await decodeImageFromList(initialCapture.imageBytes!);

      // 创建一个临时的图像列表来存储滚动截图
      final List<CaptureResult> captures = [];
      captures.add(CaptureResult(
        imageBytes: initialCapture.imageBytes,
        imagePath: initialCapture.imagePath,
        region: CaptureRegion(
          x: 0,
          y: 0,
          width: image.width.toDouble(),
          height: image.height.toDouble(),
        ),
      ));

      // 注意: 未来实现自动滚动和截图拼接逻辑
      // 1. 获取滚动容器的总高度
      // 2. 计算需要滚动的次数
      // 3. 每次滚动后截图并添加到captures列表
      // 4. 最后拼接所有图片

      return captures.first; // 临时返回第一张图片
    } catch (e) {
      _logger.e('Error capturing scrolling', error: e);
      return null;
    }
  }

  /// 处理截图结果
  Future<void> handleCaptureResult(
      BuildContext context, CaptureResult? result) async {
    try {
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
    } catch (e) {
      _logger.e('处理截图结果时出错', error: e);
      if (context.mounted) {
        await _showErrorDialog(context, '处理截图结果时出错: $e');
      }
    }
  }

  /// 显示截图预览浮窗
  void _showScreenshotPreview(BuildContext context, CaptureResult result) {
    try {
      // 获取屏幕尺寸
      final screenSize = MediaQuery.of(context).size;

      _logger.d('创建预览浮窗，屏幕尺寸: ${screenSize.width}x${screenSize.height}');

      // 声明OverlayEntry，但延迟初始化
      late final OverlayEntry overlayEntry;

      // 初始化OverlayEntry
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: 20, // 距离左侧20像素
          top: (screenSize.height - 600) / 2, // 垂直居中，最大高度600
          child: Material(
            color: Colors.transparent,
            child: ScreenshotPreview(
              imageData: result.imageBytes!,
              imagePath: result.imagePath,
              onClose: () {
                // 移除浮窗
                _logger.d('关闭预览浮窗');
                overlayEntry.remove();
              },
            ),
          ),
        ),
      );

      _logger.d('将预览浮窗添加到Overlay');

      // 将浮窗添加到Overlay
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

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> captureSelectedRegion(
      BuildContext context, CaptureRegion region) async {
    try {
      final result = await _captureSelectedRegion(region);
      if (result == null) {
        if (context.mounted) {
          await _showErrorDialog(context, 'Failed to capture screen region');
        }
        return;
      }
      // ... existing code ...
    } catch (e) {
      if (context.mounted) {
        await _showErrorDialog(context, 'An error occurred: $e');
      }
    }
  }
}

/// 蒙版绘制器
class _MaskPainter extends CustomPainter {
  final Uint8List imageBytes;
  final Path maskPath;
  ui.Image? _image;

  _MaskPainter({
    required this.imageBytes,
    required this.maskPath,
  }) {
    _loadImage();
  }

  void _loadImage() {
    decodeImageFromList(imageBytes).then((image) {
      _image = image;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_image != null) {
      canvas.clipPath(maskPath);
      canvas.drawImage(_image!, Offset.zero, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
