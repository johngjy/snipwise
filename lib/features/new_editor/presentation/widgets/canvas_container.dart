import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:logger/logger.dart';

import '../../application/providers/state_providers.dart';
import '../../application/providers/canvas_providers.dart' as cp;
import '../../application/providers/painter_providers.dart';
import '../../application/managers/canvas_manager.dart';
import '../../application/core/editor_state_core.dart';
import '../../application/states/canvas_state.dart';
import '../../application/states/wallpaper_state.dart';
import '../../application/providers/wallpaper_providers.dart';

/// 画布容器组件
/// 显示截图和背景，处理交互事件，支持绘图功能
class CanvasContainer extends ConsumerStatefulWidget {
  /// 可用区域尺寸
  final Size availableSize;

  /// 监听滚动事件的回调
  final void Function(PointerScrollEvent)? onScroll;

  /// 自定义背景颜色
  final Color? backgroundColor;

  /// 背景图填充模式
  final BoxFit backgroundFit;

  /// 是否显示边框
  final bool showBorder;

  /// 边框颜色
  final Color borderColor;

  /// 边框宽度
  final double borderWidth;

  /// 最小内边距
  final double minPadding;

  /// 尺寸变化回调
  final Function(Size)? onSizeChanged;

  /// 构造函数
  const CanvasContainer({
    Key? key,
    required this.availableSize,
    this.onScroll,
    this.backgroundColor,
    this.backgroundFit = BoxFit.fill,
    this.showBorder = true,
    this.borderColor = Colors.black12,
    this.borderWidth = 1.0,
    this.minPadding = 0.0,
    this.onSizeChanged,
  }) : super(key: key);

  @override
  ConsumerState<CanvasContainer> createState() => _CanvasContainerState();
}

class _CanvasContainerState extends ConsumerState<CanvasContainer> {
  final Logger _logger = Logger();
  Size? _lastLoggedSize;
  double _lastLoggedScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCanvas();
    });
  }

  /// 初始化画布
  void _initializeCanvas() {
    // 使用Canvas管理器实现最佳缩放和布局
    final canvasManager = ref.read(canvasManagerProvider);
    canvasManager.fitContentToViewport(widget.availableSize);
  }

  @override
  Widget build(BuildContext context) {
    // 使用编辑器核心状态
    final editorCore = ref.watch(editorStateCoreProvider);

    // 监听画布状态
    final canvasState = ref.watch(canvasProvider);

    // 获取画布背景装饰
    final backgroundDecoration = ref.watch(wallpaperDecorationProvider);

    // 获取画布是否溢出视口
    final isOverflowing = ref.watch(cp.canvasOverflowProvider);

    // 获取画布内边距
    final padding = ref.watch(cp.canvasPaddingProvider);

    // 获取当前缩放级别
    final transform = ref.watch(cp.canvasTransformProvider);
    final scale = transform.zoomLevel;

    // 计算总宽度和总高度（包含内边距）
    final contentSize = canvasState.totalSize ??
        Size(
          widget.availableSize.width * 0.8,
          widget.availableSize.height * 0.8,
        );

    // 计算内容适应缩放比例
    double contentFitScale = 1.0;
    if (widget.availableSize != null) {
      contentFitScale =
          ref.watch(cp.contentFitScaleProvider(widget.availableSize));
    }

    // 通知尺寸变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onSizeChanged != null &&
          (_lastLoggedSize == null || _lastLoggedSize != contentSize)) {
        widget.onSizeChanged!(contentSize);
        _lastLoggedSize = contentSize;
      }
    });

    // 当可用区域尺寸变化时，更新视口尺寸
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.availableSize != canvasState.viewportSize) {
        ref.read(canvasProvider.notifier).setViewportSize(widget.availableSize);
      }
    });

    _logger.d(
        '画布容器: 构建，画布尺寸=${contentSize.width}x${contentSize.height}, 缩放=$scale');

    // 根据可用空间调整缩放
    final shouldAutoScale = contentFitScale < 1.0;

    // 判断是否需要支持拖动
    final bool needsDrag = ref.watch(cp.canvasOverflowProvider);

    // 创建Transform.scale自动适应可用空间
    Widget stack = Transform.scale(
      scale: shouldAutoScale ? contentFitScale : 1.0,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none, // 允许子组件超出边界
        children: [
          // 底层容器 - 壁纸背景
          Container(
            width: contentSize.width,
            height: contentSize.height,
            decoration: backgroundDecoration ??
                BoxDecoration(color: widget.backgroundColor ?? Colors.white),
            // 使用key确保在状态变化时重建
            key: ValueKey('canvas_container_${scale.toStringAsFixed(3)}'),
          ),

          // 截图层
          if (canvasState.originalImageSize != null)
            Positioned(
              left: padding.left,
              top: padding.top,
              child: _buildScreenshotImage(canvasState),
            ),

          // 顶层 - FlutterPainter绘图层
          Positioned.fill(
            child: GestureDetector(
              // 缩放和拖拽的组合手势处理
              onScaleStart: (details) => _handleCombinedGestureStart(details),
              onScaleUpdate: (details) => _handleCombinedGestureUpdate(details),
              onScaleEnd: (details) => _handleCombinedGestureEnd(details),
              // 捕获区域是整个容器，确保任何地方点击都可以拖动
              behavior: HitTestBehavior.translucent,
              child: MouseRegion(
                cursor: scale > 1.0
                    ? SystemMouseCursors.grab
                    : SystemMouseCursors.basic,
                // 确保鼠标样式也覆盖整个区域
                opaque: false,
                child: FlutterPainter(
                  controller: ref.read(painterControllerProvider),
                  onDrawableCreated: (drawable) => _onDrawableCreated(drawable),
                  onDrawableDeleted: (drawable) => _onDrawableDeleted(drawable),
                  onSelectedObjectDrawableChanged: (drawable) =>
                      _onSelectedObjectDrawableChanged(drawable),
                ),
              ),
            ),
          ),

          // 显示调试区域
          if (isOverflowing)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(5),
                color: Colors.black45,
                child: const Text(
                  '内容溢出视图',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );

    // 当画布放大时，添加拖拽功能
    if (needsDrag) {
      // 调整鼠标样式以提供视觉反馈
      stack = MouseRegion(
        cursor: SystemMouseCursors.grab, // 使用抓取光标提示可拖动
        child: stack,
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEEEEEE), // 与编辑器背景颜色相同
      child: Listener(
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent && widget.onScroll != null) {
            widget.onScroll!(signal);
          }
        },
        child: Center(child: stack),
      ),
    );
  }

  /// 构建截图图像
  Widget _buildScreenshotImage(CanvasState canvasState) {
    if (canvasState.imageData == null ||
        canvasState.originalImageSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: canvasState.originalImageSize!.width,
      height: canvasState.originalImageSize!.height,
      decoration: widget.showBorder
          ? BoxDecoration(
              border: Border.all(
                color: widget.borderColor,
                width: widget.borderWidth,
              ),
            )
          : null,
      child: Image.memory(
        canvasState.imageData!,
        fit: widget.backgroundFit,
        width: canvasState.originalImageSize!.width,
        height: canvasState.originalImageSize!.height,
      ),
    );
  }

  /// 当创建新的 Drawable 对象时调用
  void _onDrawableCreated(Drawable drawable) {
    if (!mounted) return;

    // 延迟检查边界，等待对象完全渲染
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (drawable is ObjectDrawable) {
        final controller = ref.read(painterControllerProvider);
        _trackDrawableBounds(controller.drawables);
      }
    });
  }

  /// 当删除 Drawable 对象时调用
  void _onDrawableDeleted(Drawable drawable) {
    if (!mounted) return;
    final controller = ref.read(painterControllerProvider);
    _trackDrawableBounds(controller.drawables);
  }

  /// 当选中的对象变化时调用
  void _onSelectedObjectDrawableChanged(ObjectDrawable? drawable) {
    if (!mounted) return;
    ref.read(selectedObjectDrawableProvider.notifier).state = drawable;
  }

  /// 跟踪所有 drawable 的边界矩形
  void _trackDrawableBounds(List<Drawable> drawables) {
    if (!mounted) return;
    if (drawables.isEmpty) {
      ref.read(cp.drawableBoundsProvider.notifier).state = null;
      return;
    }

    // 计算所有 drawable 的边界矩形
    Rect? boundingRect = _calculateBoundingRect(drawables);

    if (boundingRect != null) {
      ref.read(cp.drawableBoundsProvider.notifier).state = boundingRect;

      _logger.d('画布容器: 绘制对象边界 = $boundingRect, 对象数量: ${drawables.length}');
    }
  }

  /// 计算所有 drawable 的边界矩形
  Rect? _calculateBoundingRect(List<Drawable> drawables) {
    if (drawables.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    bool hasValidBounds = false;

    for (var drawable in drawables) {
      if (drawable is ObjectDrawable) {
        try {
          final position = drawable.position;
          final size = drawable.getSize();

          minX = math.min(minX, position.dx);
          minY = math.min(minY, position.dy);
          maxX = math.max(maxX, position.dx + size.width);
          maxY = math.max(maxY, position.dy + size.height);

          hasValidBounds = true;
        } catch (e) {
          _logger.d('获取drawable边界失败: $e');
        }
      }
    }

    if (!hasValidBounds) return null;

    return Rect.fromLTRB(minX.isFinite ? minX : 0, minY.isFinite ? minY : 0,
        maxX.isFinite ? maxX : 0, maxY.isFinite ? maxY : 0);
  }

  /// 处理缩放开始事件
  void _handleCombinedGestureStart(ScaleStartDetails details) {
    if (!mounted) return;
    final focalPoint = details.focalPoint;
    ref.read(cp.canvasTransformProvider.notifier).startScale(focalPoint);
  }

  /// 处理组合手势更新事件（既处理缩放也处理拖拽）
  void _handleCombinedGestureUpdate(ScaleUpdateDetails details) {
    if (!mounted) return;
    // 获取当前缩放级别
    final currentScale = ref.read(cp.canvasTransformProvider).zoomLevel;
    final isZoomedOut = currentScale > 1.0;

    // 判断单指拖动还是多指缩放
    final bool isScaleOperation = details.scale != 1.0; // 真正的缩放操作
    final bool isPanOperation =
        details.pointerCount == 1 && details.focalPointDelta != Offset.zero;

    try {
      // 处理缩放操作 - 只响应真正的缩放（scale不为1.0）
      if (isScaleOperation) {
        ref.read(cp.canvasTransformProvider.notifier).updateScale(
              details.scale,
              details.focalPoint,
            );
      }
      // 处理拖拽操作 - 放大状态下才能拖拽
      else if (isPanOperation && isZoomedOut) {
        ref.read(cp.canvasTransformProvider.notifier).updateTranslation(
              details.focalPointDelta,
            );
      }
    } catch (e) {
      _logger.d('处理手势时出错: $e');
    }
  }

  /// 处理缩放结束事件
  void _handleCombinedGestureEnd(ScaleEndDetails details) {
    if (!mounted) return;
    ref.read(cp.canvasTransformProvider.notifier).endScale();
  }
}
