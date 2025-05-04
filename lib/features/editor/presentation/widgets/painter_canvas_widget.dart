import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../application/notifiers/canvas_transform_notifier.dart';
import '../../application/providers/editor_providers.dart';
import '../../application/providers/painter_providers.dart';
import '../../application/states/wallpaper_settings_state.dart';

/// PainterCanvasWidget 组件
/// 统一封装截图显示与FlutterPainter绘图区域
///
/// 该组件负责：
/// 1. 显示 wallpaper 背景图
/// 2. 集成 FlutterPainter 绘图功能
/// 3. 提供灵活可配置的 padding（与wallpaper设置保持同步）
/// 4. 支持通过 FlutterPainter 内置功能进行缩放和平移
/// 5. 将画布尺寸与wallpaper设置同步
/// 6. 当标注拖动到边界外时自动扩展 wallpaper padding
/// 7. 维护标注物相对于Screenshot的坐标系统
class PainterCanvasWidget extends ConsumerWidget {
  /// 屏幕截图数据
  final Uint8List? screenshotBytes;

  /// 截图宽度
  final double screenshotWidth;

  /// 截图高度
  final double screenshotHeight;

  /// 是否显示边框
  final bool showBorder;

  /// 边框颜色
  final Color borderColor;

  /// 边框宽度
  final double borderWidth;

  /// 尺寸变化回调
  final Function(Size)? onSizeChanged;

  /// 坐标系转换回调
  final Function(Offset, Offset)? onCoordinateTransformed;

  /// 构造函数
  const PainterCanvasWidget({
    super.key,
    required this.screenshotBytes,
    required this.screenshotWidth,
    required this.screenshotHeight,
    this.showBorder = true,
    this.borderColor = Colors.black12,
    this.borderWidth = 1.0,
    this.onSizeChanged,
    this.onCoordinateTransformed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取PainterController
    final controller = ref.watch(painterControllerProvider);

    // 获取Wallpaper设置
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);

    // 获取画布变换状态
    final canvasTransform = ref.watch(canvasTransformProvider);

    // 获取当前缩放比例
    final scale = ref.watch(canvasScaleProvider);

    // 同步更新截图尺寸到编辑器状态
    _updateScreenshotSize(ref);

    // 确保背景图像已设置到PainterController
    _updateBackgroundImage(ref);

    // 监听绘制内容边界变化
    ref.listen(drawableBoundsProvider, (previous, current) {
      if (previous != current && current != null) {
        _adjustCanvasForDrawableBounds(ref, current);
      }
    });

    // 计算内边距 - 使用wallpaper设置中的padding
    final padding = EdgeInsets.all(wallpaperSettings.padding);

    // 计算总宽度和总高度（包含内边距）
    final totalWidth = screenshotWidth + padding.left + padding.right;
    final totalHeight = screenshotHeight + padding.top + padding.bottom;
    final totalSize = Size(totalWidth, totalHeight);

    // 同步尺寸信息到Provider
    _updateCanvasSize(ref, totalSize);

    // 创建容器，包含背景和FlutterPainter
    return Stack(
      clipBehavior: Clip.none, // 允许子组件超出边界
      children: [
        // 底层容器 - 用于绘制Wallpaper背景
        Container(
          width: totalWidth,
          height: totalHeight,
          decoration: _buildBackgroundDecoration(wallpaperSettings),
          // 使用key确保在状态变化时重建
          key: ValueKey('painter_canvas_${scale.toStringAsFixed(3)}'),
        ),

        // 中层 - Screenshot定位
        Positioned(
          left: padding.left,
          top: padding.top,
          child: Container(
            width: screenshotWidth,
            height: screenshotHeight,
            decoration: showBorder
                ? BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  )
                : null,
            child: screenshotBytes != null
                ? Image.memory(
                    screenshotBytes!,
                    fit: BoxFit.fill,
                    width: screenshotWidth,
                    height: screenshotHeight,
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // 顶层 - FlutterPainter绘图层
        Positioned.fill(
          child: GestureDetector(
            onScaleStart: (details) => _handleScaleStart(ref, details),
            onScaleUpdate: (details) => _handleScaleUpdate(ref, details),
            onScaleEnd: (details) => _handleScaleEnd(ref),
            child: FlutterPainter(
              controller: controller,
              onDrawableCreated: (drawable) =>
                  _onDrawableCreated(ref, drawable),
              onDrawableDeleted: (drawable) =>
                  _onDrawableDeleted(ref, drawable),
              onSelectedObjectDrawableChanged: (drawable) =>
                  _onSelectedObjectDrawableChanged(ref, drawable),
            ),
          ),
        ),

        // 调试信息（仅在调试模式显示）- 简化显示
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
      ],
    );
  }

  /// 构建背景装饰
  BoxDecoration _buildBackgroundDecoration(WallpaperSettingsState settings) {
    switch (settings.type) {
      case WallpaperType.none:
        return const BoxDecoration(color: Colors.transparent);

      case WallpaperType.plainColor:
        return BoxDecoration(
          color: settings.backgroundColor,
          borderRadius: BorderRadius.circular(settings.cornerRadius),
          boxShadow: settings.shadowRadius > 0
              ? [
                  BoxShadow(
                    color: settings.shadowColor,
                    blurRadius: settings.shadowRadius,
                    offset: settings.shadowOffset,
                  )
                ]
              : null,
        );

      case WallpaperType.gradient:
        final gradientIndex = settings.selectedGradientIndex;
        if (gradientIndex != null && gradientIndex < gradientPresets.length) {
          return BoxDecoration(
            gradient: gradientPresets[gradientIndex].gradient,
            borderRadius: BorderRadius.circular(settings.cornerRadius),
            boxShadow: settings.shadowRadius > 0
                ? [
                    BoxShadow(
                      color: settings.shadowColor,
                      blurRadius: settings.shadowRadius,
                      offset: settings.shadowOffset,
                    )
                  ]
                : null,
          );
        }
        return BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(settings.cornerRadius),
        );

      case WallpaperType.wallpaper:
      case WallpaperType.blurred:
        // 这些类型需要图像数据，由上层组件通过背景Provider提供
        return BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(settings.cornerRadius),
          boxShadow: settings.shadowRadius > 0
              ? [
                  BoxShadow(
                    color: settings.shadowColor,
                    blurRadius: settings.shadowRadius,
                    offset: settings.shadowOffset,
                  )
                ]
              : null,
        );
    }
  }

  /// 更新截图尺寸到编辑器状态
  void _updateScreenshotSize(WidgetRef ref) {
    final size = Size(screenshotWidth, screenshotHeight);

    // 使用 editorStateProvider 更新截图尺寸
    ref.read(editorStateProvider.notifier).updateOriginalImageSize(size);
  }

  /// 更新背景图像到PainterController
  void _updateBackgroundImage(WidgetRef ref) {
    final logger = Logger();
    logger.d('PainterCanvasWidget._updateBackgroundImage 被调用');

    if (screenshotBytes != null) {
      logger.d(
          '截图数据非空，长度: ${screenshotBytes!.length}，图像尺寸: ${screenshotWidth}x${screenshotHeight}');

      // 检查是否已经设置了相同的背景图像
      final controller = ref.read(painterControllerProvider);
      final currentBackground = controller.value.background;

      // 检查当前背景详情
      if (currentBackground != null) {
        try {
          final dynamic background = currentBackground;
          final dynamic image = background.image;
          logger.d('当前背景已设置，类型: ${background.runtimeType}');
          if (image != null) {
            logger.d(
                '背景图像类型: ${image.runtimeType}, 长度: ${image is Uint8List ? image.length : "未知"}');
          } else {
            logger.w('背景图像为null');
          }
        } catch (e) {
          logger.e('获取背景详情出错', error: e);
        }
      } else {
        logger.w('当前背景为null');
      }

      // 使用基础类型检查替代具体类型
      final shouldUpdate = currentBackground == null ||
          !listEquals((currentBackground as dynamic).image, screenshotBytes);

      logger.d('是否需要更新背景: $shouldUpdate');

      if (shouldUpdate) {
        logger.d('开始异步更新背景图像，截图数据哈希值: ${screenshotBytes.hashCode}');

        // 将数据长度记录下来供后续比较
        final dataLength = screenshotBytes!.length;

        // 异步更新背景图像
        ref
            .read(painterProvidersUtilsProvider)
            .updateBackgroundImage(
              controller,
              screenshotBytes!,
            )
            .then((_) {
          // 更新完成后再次检查背景是否真的被设置
          final newBackground = controller.value.background;
          if (newBackground != null) {
            logger.d('背景图像更新完成，新背景类型: ${newBackground.runtimeType}');

            try {
              final dynamic image = (newBackground as dynamic).image;
              if (image != null) {
                final imageLength = image is Uint8List ? image.length : "未知";
                logger.d('新背景图像长度: $imageLength, 原始数据长度: $dataLength');
                logger.d(
                    '图像数据是否相同: ${image is Uint8List && image.length == dataLength}');
              } else {
                logger.w('更新后背景图像为null');
              }
            } catch (e) {
              logger.e('检查新背景出错', error: e);
            }
          } else {
            logger.e('背景更新后仍为null，更新失败');
          }
        }).catchError((error) {
          logger.e('背景图像更新失败', error: error);
        });
      } else {
        logger.d('背景图像无需更新，跳过');
      }
    } else {
      logger.w('截图数据为空，无法更新背景图像');
    }
  }

  /// 更新画布尺寸到Provider
  void _updateCanvasSize(WidgetRef ref, Size size) {
    // 使用postFrameCallback延迟更新，避免在build期间修改provider状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (size != ref.read(canvasTotalSizeProvider)) {
        ref.read(canvasTotalSizeProvider.notifier).state = size;

        // 触发尺寸变化回调
        if (onSizeChanged != null) {
          onSizeChanged!(size);
        }
      }
    });
  }

  /// 处理缩放开始事件
  void _handleScaleStart(WidgetRef ref, ScaleStartDetails details) {
    final focalPoint = details.focalPoint;
    ref.read(canvasTransformProvider.notifier).startScale(focalPoint);
  }

  /// 处理缩放更新事件
  void _handleScaleUpdate(WidgetRef ref, ScaleUpdateDetails details) {
    // 使用details.scale来更新缩放值
    if (details.scale != 1.0) {
      ref.read(canvasTransformProvider.notifier).updateScale(
            details.scale,
            details.focalPoint,
          );
    }

    // 处理平移
    if (details.focalPointDelta != Offset.zero) {
      ref.read(canvasTransformProvider.notifier).updateTranslation(
            details.focalPointDelta,
          );
    }
  }

  /// 处理缩放结束事件
  void _handleScaleEnd(WidgetRef ref) {
    ref.read(canvasTransformProvider.notifier).endScale();
  }

  /// 当创建新的 Drawable 对象时调用
  void _onDrawableCreated(WidgetRef ref, Drawable drawable) {
    // 延迟检查边界，等待对象完全渲染
    Future.delayed(const Duration(milliseconds: 100), () {
      if (drawable is ObjectDrawable) {
        final controller = ref.read(painterControllerProvider);
        _trackDrawableBounds(ref, controller.value.drawables);
      }
    });
  }

  /// 当删除 Drawable 对象时调用
  void _onDrawableDeleted(WidgetRef ref, Drawable drawable) {
    final controller = ref.read(painterControllerProvider);
    _trackDrawableBounds(ref, controller.value.drawables);
  }

  /// 当选中的对象变化时调用
  void _onSelectedObjectDrawableChanged(
      WidgetRef ref, ObjectDrawable? drawable) {
    ref.read(selectedObjectDrawableProvider.notifier).state = drawable;
  }

  /// 跟踪所有 drawable 的边界矩形
  void _trackDrawableBounds(WidgetRef ref, List<Drawable> drawables) {
    if (drawables.isEmpty) {
      ref.read(drawableBoundsProvider.notifier).state = null;
      return;
    }

    // 计算所有 drawable 的边界矩形
    Rect? boundingRect = _calculateBoundingRect(drawables);

    if (boundingRect != null) {
      ref.read(drawableBoundsProvider.notifier).state = boundingRect;

      if (kDebugMode) {
        print(
            'PainterCanvasWidget: 绘制对象边界 = $boundingRect, 对象数量: ${drawables.length}');
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
            print('获取drawable边界失败: $e');
          }
        }
      }
    }

    if (!hasValidBounds) return null;

    return Rect.fromLTRB(minX.isFinite ? minX : 0, minY.isFinite ? minY : 0,
        maxX.isFinite ? maxX : 0, maxY.isFinite ? maxY : 0);
  }

  /// 根据绘制内容边界调整画布大小
  void _adjustCanvasForDrawableBounds(WidgetRef ref, Rect bounds) {
    // 获取当前 Wallpaper 设置
    final wallpaperSettings = ref.read(wallpaperSettingsProvider);
    final padding = wallpaperSettings.padding;

    // 计算预留边距（边界与画布边缘之间的最小距离）
    const double margin = 30.0;

    // 计算标注物相对于Screenshot的坐标
    final relativeLeft = bounds.left - padding;
    final relativeTop = bounds.top - padding;
    final relativeRight = bounds.right - padding;
    final relativeBottom = bounds.bottom - padding;

    // 判断是否需要扩展画布
    bool needMorePadding = false;
    double newPadding = padding;

    // 检查左边界
    if (relativeLeft < margin) {
      newPadding = math.max(newPadding, padding + (margin - relativeLeft));
      needMorePadding = true;
    }

    // 检查上边界
    if (relativeTop < margin) {
      newPadding = math.max(newPadding, padding + (margin - relativeTop));
      needMorePadding = true;
    }

    // 检查右边界
    if (relativeRight > screenshotWidth - margin) {
      newPadding = math.max(
          newPadding, padding + (relativeRight - (screenshotWidth - margin)));
      needMorePadding = true;
    }

    // 检查下边界
    if (relativeBottom > screenshotHeight - margin) {
      newPadding = math.max(
          newPadding, padding + (relativeBottom - (screenshotHeight - margin)));
      needMorePadding = true;
    }

    // 如果需要更多内边距，更新Wallpaper设置
    if (needMorePadding) {
      ref.read(wallpaperSettingsProvider.notifier).setPadding(newPadding);

      if (kDebugMode) {
        print('PainterCanvasWidget: 自动扩展内边距 - 旧=$padding, 新=$newPadding');
      }

      // 通知坐标转换
      if (onCoordinateTransformed != null) {
        final oldOffset = Offset(padding, padding);
        final newOffset = Offset(newPadding, newPadding);
        onCoordinateTransformed!(oldOffset, newOffset);
      }
    }
  }
}

/// Drawable边界提供者 - 用于跟踪绘制内容的边界
final drawableBoundsProvider = StateProvider<Rect?>((ref) => null);

/// 选中对象提供者 - 跟踪当前选中的Drawable对象
final selectedObjectDrawableProvider =
    StateProvider<ObjectDrawable?>((ref) => null);
