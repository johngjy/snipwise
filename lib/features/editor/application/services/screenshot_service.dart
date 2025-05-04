import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// 本地导入
import '../../../../core/services/clipboard_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../capture/data/models/capture_mode.dart' as app_capture;
import '../../../capture/services/capture_service.dart';
import '../core/editor_state_core.dart' as core;
import '../providers/editor_providers.dart' as old_providers;
import '../providers/core_providers.dart' as new_providers;
import '../notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider;
import 'new_button_menu_service.dart';

/// 截图来源枚举
enum ScreenshotSource {
  /// 从屏幕截图
  fromScreen,

  /// 从文件加载
  fromFile,
}

/// 截图服务类，处理截图和相关操作
class ScreenshotService {
  static final ScreenshotService _instance = ScreenshotService._internal();

  factory ScreenshotService() => _instance;

  ScreenshotService._internal();

  final Logger _logger = Logger();

  /// 使用指定的捕获模式进行截图
  Future<void> captureWithMode(
      app_capture.CaptureMode mode, WidgetRef ref) async {
    // 隐藏新建按钮菜单
    NewButtonMenuService().hideNewButtonMenu(ref);

    final editorState = ref.read(new_providers.editorStateProvider);

    // 如果当前有未保存的截图，先保存然后执行新截图
    if (editorState.currentImageData != null) {
      // 自动保存当前截图，然后执行新截图
      try {
        await saveImage(ref);
        _logger.d('已自动保存当前截图，准备执行新的截图');
        // 执行新截图
        await performCapture(mode, ref);
      } catch (e) {
        _logger.e('自动保存截图失败，但仍继续执行新的截图', error: e);
        // 即使保存失败，也尝试执行截图
        await performCapture(mode, ref);
      }
    } else {
      // 直接执行截图，不需要保存
      await performCapture(mode, ref);
    }
  }

  /// 执行截图动作
  Future<void> performCapture(
      app_capture.CaptureMode mode, WidgetRef ref) async {
    _logger.i('直接执行截图: $mode');

    try {
      final result = await CaptureService.instance.capture(mode);

      if (result != null && result.hasData) {
        // 获取新截图数据
        final capturedImageData = result.imageBytes;
        final capturedScale = result.scale;

        final codec = await ui.instantiateImageCodec(capturedImageData!);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;
        final imageSize = Size(
          uiImage.width.toDouble(),
          uiImage.height.toDouble(),
        );

        ref
            .read(new_providers.editorStateProvider.notifier)
            .loadFullScreenshotData(
                capturedImageData, uiImage, imageSize, capturedScale);

        // 使用更强大的状态重置方法
        await resetStatesForNewScreenshot(
          ref,
          capturedImageData,
          result.logicalRect?.size ?? imageSize,
        );
      } else {
        _logger.w('截图未返回结果或已取消');
      }
    } catch (e, stackTrace) {
      _logger.e('截图过程中发生错误', error: e, stackTrace: stackTrace);
    }
  }

  /// 为新截图重置所有相关状态并调整窗口尺寸
  /// 这是一个完整的状态重置流程，确保二次截图时UI正确更新
  Future<void> resetStatesForNewScreenshot(
      WidgetRef ref, Uint8List imageData, Size imageSize) async {
    _logger.d('开始为新截图重置状态: 图像尺寸=$imageSize');

    try {
      // 1. 使用EditorStateCore进行全局统一重置
      ref.read(core.editorStateCoreProvider).resetAllState();

      // 2. 获取屏幕尺寸信息
      final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final Size screenSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      _logger.d('重置状态 - 获取屏幕尺寸: $screenSize');

      // 3. 初始化布局计算器
      ref.read(new_providers.layoutProvider.notifier).initialize(screenSize);

      // 4. 加载新截图数据
      final capturedScale =
          ref.read(new_providers.editorStateProvider).capturedScale;
      // 使用EditorStateCore加载截图
      final initialScale =
          ref.read(core.editorStateCoreProvider).loadScreenshot(
                imageData,
                imageSize,
                capturedScale: capturedScale,
              );
      _logger.d('初始缩放比例: $initialScale');

      // 5. 获取计算出的新窗口尺寸
      final editorWindowSize =
          ref.read(new_providers.layoutProvider).editorWindowSize;
      _logger.d('新窗口尺寸: $editorWindowSize');

      // 6. 调整窗口尺寸
      await WindowService.instance.resizeWindow(editorWindowSize);
      await windowManager.center();
      _logger.d('窗口大小调整完成');

      // 7. 确保变换正确设置 (已经由EditorStateCore处理，此处可选)
      ref.read(new_providers.canvasTransformProvider.notifier).resetTransform();

      // 打印关键状态值，用于验证
      final editorState = ref.read(new_providers.editorStateProvider);
      final layoutState = ref.read(new_providers.layoutProvider);
      final transformState = ref.read(new_providers.canvasTransformProvider);

      _logger
          .d('状态验证 - EditorState.imageSize: ${editorState.originalImageSize}');
      _logger
          .d('状态验证 - LayoutState.windowSize: ${layoutState.editorWindowSize}');
      _logger.d('状态验证 - CanvasTransform.scale: ${transformState.zoomLevel}');
    } catch (e, stackTrace) {
      _logger.e('重置状态过程中发生错误', error: e, stackTrace: stackTrace);
      ref.read(new_providers.editorStateProvider.notifier).setLoading(false);
    }
  }

  /// 保存编辑后的图片
  Future<void> saveImage(WidgetRef ref) async {
    final editorState = ref.read(new_providers.editorStateProvider);
    final imageData = editorState.currentImageData;
    if (imageData == null) {
      _logger.w('No image data available to save');
      return;
    }

    String? filePath;
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        _logger.e('Failed to get downloads directory');
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${directory.path}/screenshot_$timestamp.png';
      await io.File(filePath).writeAsBytes(imageData);

      _logger.d('Image saved to: $filePath');
      return;
    } catch (e) {
      _logger.e('Error saving image: $e');
      throw Exception('保存图片失败: $e');
    }
  }

  /// 复制图片到剪贴板
  Future<bool> copyToClipboard(WidgetRef ref) async {
    final editorState = ref.read(new_providers.editorStateProvider);
    final imageData = editorState.currentImageData;
    if (imageData == null) {
      _logger.w('No image data available to copy');
      return false;
    }

    try {
      final ClipboardService clipboardService = ClipboardService();
      final success = await clipboardService.copyImage(imageData);
      _logger.d('Image copied to clipboard: $success');
      return success;
    } catch (e) {
      _logger.e('Error copying image to clipboard: $e');
      return false;
    }
  }

  /// 从指定渠道捕获屏幕截图
  Future<void> captureOnMethod(WidgetRef ref, ScreenshotSource source) async {
    _logger.d('开始捕获图像，源: $source');
    ref.read(new_providers.editorStateProvider.notifier).setLoading(true);

    try {
      Uint8List? imageData;

      if (source == ScreenshotSource.fromFile) {
        // 从文件中加载图像
        _logger.d('开始从文件加载图像');
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) {
            _logger.d('从文件加载图像: $path');
            final file = io.File(path);
            imageData = await file.readAsBytes();
            _logger.d('文件读取完成，数据长度: ${imageData.length}');
          } else {
            throw Exception('File path is null');
          }
        }
      } else {
        // 捕获屏幕截图
        _logger.d('开始捕获屏幕截图');
        final capturer = ScreenCapturer.instance;
        final result = await capturer.capture(
          mode: CaptureMode.screen,
          silent: true,
          copyToClipboard: false,
        );

        // 正确处理CapturedData对象
        if (result != null) {
          imageData = result.imageBytes; // 从CapturedData直接获取图像字节
          _logger.d('截图捕获完成: 成功, 数据长度: ${imageData?.length ?? 0}');

          // 如果imageBytes为空但有路径，尝试从文件读取
          if (imageData == null && result.imagePath != null) {
            _logger.d('尝试从文件读取图像: ${result.imagePath}');
            final file = io.File(result.imagePath!);
            imageData = await file.readAsBytes();
            _logger.d('从文件读取完成，数据长度: ${imageData.length}');
          }
        } else {
          _logger.w('截图捕获完成: 失败，result为null');
        }
      }

      if (imageData != null) {
        // 处理图像并更新编辑器状态
        _logger.d('开始处理图像');
        await processImage(ref, imageData);
        _logger.d('图像处理完成');
      } else {
        throw Exception('Failed to capture or load image');
      }
    } catch (e, stackTrace) {
      _logger.e('捕获和处理图像失败', error: e, stackTrace: stackTrace);
      // 重置加载状态
      ref.read(new_providers.editorStateProvider.notifier).setLoading(false);
    }
  }

  /// 处理图像并更新编辑器状态
  Future<void> processImage(WidgetRef ref, Uint8List imageData) async {
    _logger.d('ScreenshotService.processImage 被调用，图像数据长度: ${imageData.length}');

    try {
      // 解码图像以获取尺寸
      _logger.d('开始解码图像');
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      _logger.d('图像解码完成: ${uiImage.width}x${uiImage.height}');

      final imageSize = Size(
        uiImage.width.toDouble(),
        uiImage.height.toDouble(),
      );

      // 重置所有状态
      _logger.d('重置编辑器状态');
      resetStatesForNewScreenshot(ref, imageData, imageSize);

      // 加载截图并计算布局
      _logger.d('加载截图并计算布局');
      final editorStateCore = ref.read(core.editorStateCoreProvider);
      final initialScaleFactor =
          editorStateCore.loadScreenshot(imageData, imageSize);
      _logger.d('布局计算完成，初始缩放因子: $initialScaleFactor');

      // 更新FlutterPainter的背景图像
      _logger.d('开始更新FlutterPainter背景');
      await editorStateCore.updateBackgroundImage(imageData);
      _logger.d('FlutterPainter背景更新完成');

      // 通知UI更新
      ref.read(new_providers.editorStateProvider.notifier).setLoading(false);
      _logger.d('图像加载和处理流程完成');
    } catch (e, stackTrace) {
      _logger.e('处理图像失败', error: e, stackTrace: stackTrace);
      ref.read(new_providers.editorStateProvider.notifier).setLoading(false);
      // 不重新抛出异常，允许应用继续运行
    }
  }
}
