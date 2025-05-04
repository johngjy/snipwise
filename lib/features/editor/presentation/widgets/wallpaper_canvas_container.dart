import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../application/core/editor_state_core.dart' as core;
import '../../application/providers/core_providers.dart';
import '../../application/providers/canvas_providers.dart' as cp;
import '../../application/providers/wallpaper_providers.dart' as wp;
import '../../application/providers/painter_providers.dart';
import '../../application/managers/canvas_manager.dart';
import '../../application/states/wallpaper_settings_state.dart';

/// WallpaperCanvasContainer 组件
/// 统一封装截图显示与注释区域渲染
///
/// 该组件负责：
/// 1. 显示 wallpaper 背景图
/// 2. 集成 FlutterPainter 绘图功能
/// 3. 提供灵活可配置的 padding（整体调节 + 四向独立控制）
/// 4. 支持通过 FlutterPainter 内置功能进行缩放和平移
/// 5. 将画布尺寸导出给上级状态计算使用
/// 6. 在重新截图时能够及时更新图像
/// 7. 当标注拖动到边界外时自动扩展 wallpaper 大小
/// 8. 维护标注物相对于Screenshot的坐标系统
/// 9. 自动根据可用空间大小进行适当缩放，确保内容完全可见
class WallpaperCanvasContainer extends ConsumerStatefulWidget {
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

  /// a最小内边距
  final double minPadding;

  /// 尺寸变化回调
  final Function(Size)? onSizeChanged;

  /// 坐标系转换回调
  final Function(Offset, Offset)? onCoordinateTransformed;

  /// 可用屏幕区域尺寸，用于自动调整缩放以适配
  final Size? availableAreaSize;

  /// 构造函数
  const WallpaperCanvasContainer({
    super.key,
    this.backgroundColor,
    this.backgroundFit = BoxFit.cover,
    this.showBorder = true,
    this.borderColor = Colors.black12,
    this.borderWidth = 1.0,
    this.minPadding = 0.0,
    this.onSizeChanged,
    this.onCoordinateTransformed,
    this.availableAreaSize,
  });

  @override
  ConsumerState<WallpaperCanvasContainer> createState() =>
      _WallpaperCanvasContainerState();
}

class _WallpaperCanvasContainerState
    extends ConsumerState<WallpaperCanvasContainer> {
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
    if (widget.availableAreaSize != null) {
      // 使用Canvas管理器实现最佳缩放和布局
      final canvasManager = ref.read(canvasManagerProvider);
      canvasManager.fitContentToViewport(widget.availableAreaSize!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用编辑器核心状态
    final editorCore = ref.watch(core.editorStateCoreProvider);

    // 监听编辑器状态变化，确保重新截图时能及时更新
    ref.listen(editorStateProvider, (previous, current) {
      if (previous?.currentImageData != current.currentImageData) {
        if (kDebugMode) {
          _logger.d('WallpaperCanvasContainer: 图像数据已更新');
        }
        // 图像更新时使用Canvas管理器重置画布尺寸
        if (widget.availableAreaSize != null) {
          final canvasManager = ref.read(canvasManagerProvider);
          canvasManager.fitContentToViewport(widget.availableAreaSize!);
        }
      }
    });

    // 监听绘制内容边界变化
    ref.listen(cp.drawableBoundsProvider, (previous, current) {
      if (previous != current && current != null) {
        // 使用Canvas管理器调整画布以适应绘制物边界
        final canvasManager = ref.read(canvasManagerProvider);
        canvasManager.adjustCanvasForDrawableBounds(current);
      }
    });

    // 使用新的Provider架构获取状态
    final canvasSize = ref.watch(cp.canvasSizeProvider);
    final padding = ref.watch(cp.canvasPaddingProvider);
    final wallpaperImage = ref.watch(wp.wallpaperImageProvider);
    final scale = ref.watch(canvasTransformProvider).zoomLevel;
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
    final backgroundDecoration =
        ref.watch(cp.canvasBackgroundDecorationProvider);

    // 计算总宽度和总高度（包含内边距）
    final totalWidth = canvasSize.width + padding.left + padding.right;
    final totalHeight = canvasSize.height + padding.top + padding.bottom;
    final totalSize = Size(totalWidth, totalHeight);

    // 计算内容适应缩放比例
    double contentFitScale = 1.0;
    if (widget.availableAreaSize != null) {
      contentFitScale =
          ref.watch(cp.contentFitScaleProvider(widget.availableAreaSize!));

      if (kDebugMode && (contentFitScale < 0.99 || contentFitScale > 1.01)) {
        _logger.d('内容适应缩放: $contentFitScale');
        _logger.d('内容尺寸: $totalSize, 可用区域: ${widget.availableAreaSize}');
      }
    }

    // 通知尺寸变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onSizeChanged != null &&
          (_lastLoggedSize == null || _lastLoggedSize != totalSize)) {
        widget.onSizeChanged!(totalSize);
        _lastLoggedSize = totalSize;
      }
    });

    // 根据可用空间调整缩放
    final shouldAutoScale = contentFitScale < 1.0;

    // 如果没有壁纸背景图像，显示占位符
    if (wallpaperImage == null) {
      _logger.w('WallpaperCanvasContainer: 壁纸图像为空，显示占位符');
      return SizedBox(
        width: totalWidth * (shouldAutoScale ? contentFitScale : 1.0),
        height: totalHeight * (shouldAutoScale ? contentFitScale : 1.0),
        child: const Center(
          child: Text('请选择或捕获一张图片'),
        ),
      );
    } else {
      _logger
          .d('WallpaperCanvasContainer: 壁纸图像非空，数据长度=${wallpaperImage.length}');
    }

    // 判断是否需要支持拖动
    final bool needsDrag = ref.watch(cp.canvasOverflowProvider);

    // 创建Transform.scale自动适应可用空间
    Widget stack = Transform.scale(
      scale: shouldAutoScale ? contentFitScale : 1.0,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none, // 允许子组件超出边界
        children: [
          // 底层容器 - 用于绘制Wallpaper背景
          Container(
            width: totalWidth,
            height: totalHeight,
            decoration: backgroundDecoration != null
                ? _getBackgroundDecoration(backgroundDecoration,
                    widget.backgroundColor, wallpaperSettings)
                : BoxDecoration(color: widget.backgroundColor ?? Colors.white),
            // 使用key确保在状态变化时重建
            key: ValueKey('wallpaper_canvas_${scale.toStringAsFixed(3)}'),
          ),

          // 无论壁纸类型如何，总是显示截图
          Positioned(
            left: padding.left,
            top: padding.top,
            child: Container(
              width: canvasSize.width,
              height: canvasSize.height,
              decoration: widget.showBorder
                  ? BoxDecoration(
                      border: Border.all(
                        color: widget.borderColor,
                        width: widget.borderWidth,
                      ),
                    )
                  : null,
              child: wallpaperImage != null
                  ? Image.memory(
                      wallpaperImage,
                      fit: widget.backgroundFit,
                      key: ValueKey('${wallpaperImage.hashCode}_$scale'),
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode) {
                          _logger.d('WallpaperCanvasContainer: 图像加载错误 $error');
                        }
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text(
                              '图像加载失败',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
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

          // 调试信息（仅在调试模式显示）- 移除百分比和内边距信息
          if (kDebugMode)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withAlpha((255 * 0.1).round()),
                child: const Text(
                  '调试模式',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),

          // 可选的边界指示（调试用）
          if (kDebugMode) _buildDebugBoundaryIndicator(),
        ],
      ),
    );

    // 当画布放大时，添加拖拽功能
    if (needsDrag) {
      // 不再添加额外提示文字，整个Stack已经包含手势检测
      // 调整鼠标样式以提供视觉反馈
      stack = MouseRegion(
        cursor: SystemMouseCursors.grab, // 使用抓取光标提示可拖动
        child: stack,
      );
    }

    return Center(child: stack); // 使用 Center 水平垂直居中
  }

  /// 获取背景装饰
  BoxDecoration _getBackgroundDecoration(BoxDecoration defaultDecoration,
      Color? explicitBackgroundColor, WallpaperSettingsState settings) {
    // Use provided background color if available
    if (explicitBackgroundColor != null) {
      return defaultDecoration.copyWith(color: explicitBackgroundColor);
    }
    // Otherwise, use color from settings if type is plainColor
    else if (settings.type == WallpaperType.plainColor) {
      return defaultDecoration.copyWith(color: settings.backgroundColor);
    }
    // Fallback to default decoration
    else {
      return defaultDecoration;
    }
  }

  /// 调试用的边界指示器
  Widget _buildDebugBoundaryIndicator() {
    final bounds = ref.watch(cp.drawableBoundsProvider);
    final padding = ref.watch(cp.canvasPaddingProvider);

    if (bounds == null) return const SizedBox.shrink();

    return Positioned(
      left: padding.left + bounds.left - 2,
      top: padding.top + bounds.top - 2,
      child: Container(
        width: bounds.width + 4,
        height: bounds.height + 4,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.red.withAlpha((255 * 0.5).round()), width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
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
        _trackDrawableBounds(controller.value.drawables);
      }
    });
  }

  /// 当删除 Drawable 对象时调用
  void _onDrawableDeleted(Drawable drawable) {
    if (!mounted) return;
    final controller = ref.read(painterControllerProvider);
    _trackDrawableBounds(controller.value.drawables);
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

      if (kDebugMode) {
        _logger.d(
            'WallpaperCanvasContainer: 绘制对象边界 = $boundingRect, 对象数量: ${drawables.length}');
      }
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
          if (kDebugMode) {
            _logger.d('获取drawable边界失败: $e');
          }
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
    ref.read(canvasTransformProvider.notifier).startScale(focalPoint);
  }

  /// 处理组合手势更新事件（既处理缩放也处理拖拽）
  void _handleCombinedGestureUpdate(ScaleUpdateDetails details) {
    if (!mounted) return;
    // 获取当前缩放级别
    final currentScale = ref.read(canvasTransformProvider).zoomLevel;
    final isZoomedOut = currentScale > 1.0;

    // 判断单指拖动还是多指缩放
    final bool isScaleOperation = details.scale != 1.0; // 真正的缩放操作
    final bool isPanOperation =
        details.pointerCount == 1 && details.focalPointDelta != Offset.zero;

    if (kDebugMode &&
        (isScaleOperation ||
            (isPanOperation && details.focalPointDelta.distance > 5))) {
      _logger.d(
          '手势更新: 缩放=${details.scale}, 指针数=${details.pointerCount}, 移动=${details.focalPointDelta}');
    }

    try {
      // 处理缩放操作 - 只响应真正的缩放（scale不为1.0）
      if (isScaleOperation) {
        ref.read(canvasTransformProvider.notifier).updateScale(
              details.scale,
              details.focalPoint,
            );
      }
      // 处理拖拽操作 - 放大状态下才能拖拽
      else if (isPanOperation && isZoomedOut) {
        ref.read(canvasTransformProvider.notifier).updateTranslation(
              details.focalPointDelta,
            );
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.d('处理手势时出错: $e');
      }
    }
  }

  /// 处理缩放结束事件
  void _handleCombinedGestureEnd(ScaleEndDetails details) {
    if (!mounted) return;
    ref.read(canvasTransformProvider.notifier).endScale();
  }
}

/// Drawable边界提供者 - 用于跟踪绘制内容的边界
final drawableBoundsProvider = StateProvider<Rect?>((ref) => null);

/// WallpaperCanvasPaddingControls 组件
/// 提供调整画布内边距的控制面板 - 直接操作wallpaperSettingsProvider
class WallpaperCanvasPaddingControls extends ConsumerWidget {
  const WallpaperCanvasPaddingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前wallpaper设置
    final settings = ref.watch(wallpaperSettingsProvider);
    final padding = settings.padding; // 当前wallpaper设置的内边距

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Canvas Padding',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        // 统一内边距控制
        Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.swap_horiz, size: 16),
            const SizedBox(width: 8),
            const Text('All sides:'),
            Expanded(
              child: Slider(
                value: padding,
                min: 0,
                max: 100,
                divisions: 100,
                label: padding.round().toString(),
                onChanged: (value) {
                  // 直接更新wallpaperSettings
                  ref
                      .read(wallpaperSettingsProvider.notifier)
                      .setPadding(value);
                },
              ),
            ),
            SizedBox(
              width: 40,
              child: Text('${padding.round()} px'),
            ),
          ],
        ),

        // 四个方向的设置在当前实现中不可行，因为wallpaperSettings只支持统一的padding
        // 为保持UI一致性，暂时保留但禁用这些控件

        // 顶部内边距控制（已禁用）
        _buildDisabledPaddingControl(
          icon: Icons.arrow_upward,
          label: 'Top:',
          value: padding,
        ),

        // 右侧内边距控制（已禁用）
        _buildDisabledPaddingControl(
          icon: Icons.arrow_forward,
          label: 'Right:',
          value: padding,
        ),

        // 底部内边距控制（已禁用）
        _buildDisabledPaddingControl(
          icon: Icons.arrow_downward,
          label: 'Bottom:',
          value: padding,
        ),

        // 左侧内边距控制（已禁用）
        _buildDisabledPaddingControl(
          icon: Icons.arrow_back,
          label: 'Left:',
          value: padding,
        ),

        // 添加重置按钮
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重置边距'),
            onPressed: () => _resetPadding(ref),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 32),
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// 重置所有内边距为默认值
  void _resetPadding(WidgetRef ref) {
    const defaultPadding = 20.0;
    ref.read(wallpaperSettingsProvider.notifier).setPadding(defaultPadding);
  }

  /// 构建禁用的内边距控制行
  Widget _buildDisabledPaddingControl({
    required IconData icon,
    required String label,
    required double value,
  }) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
            width: 50,
            child: Text(label, style: TextStyle(color: Colors.grey))),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: null, // 禁用滑块
          ),
        ),
        SizedBox(
          width: 40,
          child:
              Text('${value.round()} px', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
