import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/editor_providers.dart';
import 'wallpaper_canvas_container.dart';
import '../../application/helpers/canvas_transform_connector.dart';
import '../../application/notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider, canvasScaleProvider;

/// 截图显示区域组件 - 处理图像显示、缩放和交互
class ScreenshotDisplayArea extends ConsumerStatefulWidget {
  /// 图像数据
  final Uint8List? imageData;

  /// 捕获比例
  final double capturedScale;

  /// 变换控制器
  final TransformationController transformController;

  /// 鼠标滚轮事件处理
  final void Function(PointerScrollEvent) onMouseScroll;

  /// 构建时可用的编辑区域尺寸
  final Size availableSize;

  /// 图像逻辑大小
  final Size? imageLogicalSize;

  const ScreenshotDisplayArea({
    super.key,
    required this.imageData,
    required this.capturedScale,
    required this.transformController,
    required this.onMouseScroll,
    required this.availableSize,
    this.imageLogicalSize,
  });

  /// 计算适合窗口的缩放级别
  static double calculateFitZoomLevel(
      Size availableSize, Size imageLogicalSize) {
    if (imageLogicalSize.width <= 0 ||
        imageLogicalSize.height <= 0 ||
        availableSize.width <= 0 ||
        availableSize.height <= 0) {
      return 1.0; // 避免除以零或无效计算
    }

    // 获取图片原始尺寸
    final double imageWidth = imageLogicalSize.width;
    final double imageHeight = imageLogicalSize.height;

    // 获取可用白色背景区域的尺寸，考虑边距
    final double availableWidth = availableSize.width * 0.94; // 减去6%的水平边距
    final double availableHeight = availableSize.height * 0.94; // 减去6%的垂直边距

    // 计算宽高比
    final double viewAspectRatio = availableWidth / availableHeight;
    final double imageAspectRatio = imageWidth / imageHeight;

    double scale;
    // 根据宽高比决定是以宽度为基准还是以高度为基准进行缩放
    if (viewAspectRatio > imageAspectRatio) {
      // 视图比图片更宽，以高度为基准进行缩放
      scale = availableHeight / imageHeight;
    } else {
      // 视图比图片更高或宽高比接近，以宽度为基准进行缩放
      scale = availableWidth / imageWidth;
    }

    return scale;
  }

  @override
  ConsumerState<ScreenshotDisplayArea> createState() =>
      _ScreenshotDisplayAreaState();
}

class _ScreenshotDisplayAreaState extends ConsumerState<ScreenshotDisplayArea> {
  // 静态变量用于缩放状态防抖
  static double _lastLoggedScale = 0.0;

  @override
  Widget build(BuildContext context) {
    // 监听画布变换状态和缩放比例
    final canvasTransform = ref.watch(canvasTransformProvider);
    final zoomLevel = canvasTransform.zoomLevel;

    // 直接监听缩放状态
    final scale = ref.watch(canvasScaleProvider);

    // 添加缩放状态变化防抖，仅当调试模式下且缩放值有明显变化时才输出日志
    // 使用静态变量跟踪上次记录的缩放值
    if (scale != _lastLoggedScale && (scale - _lastLoggedScale).abs() > 0.01) {
      _lastLoggedScale = scale;
      if (kDebugMode) {
        debugPrint(
            'ScreenshotDisplayArea: 缩放状态变化 - scale=$scale, zoomLevel=$zoomLevel');
      }
    }

    // 将图像数据和尺寸更新到全局状态
    // 使用 addPostFrameCallback 避免在构建过程中修改状态
    if (widget.imageData != null) {
      // 使用变量保存当前引用，避免在回调中直接使用 ref
      final editorStateNotifier = ref.read(editorStateProvider.notifier);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          // 更新当前图像数据
          editorStateNotifier.setCurrentImageData(widget.imageData);

          // 如果有图像逻辑尺寸，更新画布尺寸
          if (widget.imageLogicalSize != null) {
            editorStateNotifier
                .updateOriginalImageSize(widget.imageLogicalSize!);
          }
        } catch (e) {
          // 安全处理可能的错误（例如 StateError）
          if (kDebugMode) {
            print('更新图像数据错误: $e');
          }
        }
      });
    }

    // 获取是否显示wallpaper面板
    final isWallpaperPanelVisible = ref.watch(wallpaperPanelVisibleProvider);

    // 使用提供的可用空间尺寸，而不是屏幕尺寸
    final availableSize = widget.availableSize;

    if (kDebugMode) {
      print(
          'ScreenshotDisplayArea: 可用尺寸=$availableSize, wallpaper面板=${isWallpaperPanelVisible ? "显示" : "隐藏"}');
    }

    // 设置容器以自动填充可用空间
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEEEEEE), // 与编辑器背景颜色相同
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            // 更详细的调试信息
            if (kDebugMode) {
              final kind = pointerSignal.kind.toString();
              final dx = pointerSignal.scrollDelta.dx.toStringAsFixed(2);
              final dy = pointerSignal.scrollDelta.dy.toStringAsFixed(2);
              print(
                  'ScreenshotDisplayArea: 接收到滚动事件 kind=$kind, delta=($dx,$dy)');
            }
            // 传递给上层处理
            widget.onMouseScroll(pointerSignal);
          }
        },
        child: GestureDetector(
          // 处理触控板缩放手势
          onScaleStart: (details) {
            if (kDebugMode) {
              print(
                  'ScreenshotDisplayArea: 缩放开始 at ${details.focalPoint}, pointerCount=${details.pointerCount}');
            }
            ref
                .read(canvasTransformConnectorProvider)
                .handleScaleStart(details);
          },
          onScaleUpdate: (details) {
            // 仅在缩放比例变化时输出调试信息，避免日志过多
            if (kDebugMode &&
                (details.scale != 1.0 ||
                    details.focalPointDelta != Offset.zero)) {
              print(
                  'ScreenshotDisplayArea: 缩放更新 scale=${details.scale}, delta=${details.focalPointDelta}');
            }
            ref
                .read(canvasTransformConnectorProvider)
                .handleScaleUpdate(details);
          },
          onScaleEnd: (details) {
            ref.read(canvasTransformConnectorProvider).handleScaleEnd(details);
          },
          child: Center(
            // 使用完整的Transform支持平移+缩放
            child: Transform(
              // Matrix4变换顺序：先平移后缩放
              transform: Matrix4.identity()
                ..translate(
                  canvasTransform.canvasOffset.dx,
                  canvasTransform.canvasOffset.dy,
                )
                ..scale(scale),
              alignment: Alignment.topLeft,
              child: WallpaperCanvasContainer(
                key: ValueKey(
                    'canvas_${widget.imageData?.hashCode ?? 'no_image'}'),
                availableAreaSize:
                    availableSize, // 传递可用区域尺寸给WallpaperCanvasContainer
                onSizeChanged: (size) {
                  if (kDebugMode) {
                    print(
                        'Canvas size changed: $size, wallpaper面板=${isWallpaperPanelVisible ? "显示" : "隐藏"}');
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
