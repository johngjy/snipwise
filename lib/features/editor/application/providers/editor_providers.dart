import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../managers/canvas_manager.dart';
import '../notifiers/annotation_notifier.dart';
import '../notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider, canvasScaleProvider;
import '../notifiers/editor_state_notifier.dart';
import '../notifiers/layout_notifier.dart';
import '../notifiers/tool_notifier.dart';
import '../notifiers/wallpaper_settings_notifier.dart';
import '../states/annotation_state.dart';
import '../states/canvas_transform_state.dart';
import '../states/editor_state.dart';
import '../states/layout_state.dart';
import '../states/tool_state.dart';
import '../states/wallpaper_settings_state.dart';
import 'wallpaper_providers.dart' as wp; // 导入壁纸提供者

/// 布局管理Provider
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(() {
  return LayoutNotifier();
});

/// 编辑器状态Provider
final editorStateProvider =
    NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});

/// 标注管理Provider
final annotationProvider =
    NotifierProvider<AnnotationNotifier, AnnotationState>(() {
  return AnnotationNotifier();
});

/// 工具管理Provider
final toolProvider = NotifierProvider<ToolNotifier, ToolState>(() {
  return ToolNotifier();
});

/// Wallpaper设置Provider
final wallpaperSettingsProvider =
    StateNotifierProvider<WallpaperSettingsNotifier, WallpaperSettingsState>(
        (ref) {
  return WallpaperSettingsNotifier();
});

/// Wallpaper面板可见性Provider
final wallpaperPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// 当前工具Provider
final currentToolProvider = Provider<String>((ref) {
  final toolState = ref.watch(toolProvider);
  // 从工具状态映射为字符串，便于UI使用
  final tool = toolState.currentTool;
  switch (tool) {
    case EditorTool.select:
      return 'select';
    case EditorTool.rectangle:
      return 'rectangle';
    case EditorTool.ellipse:
      return 'ellipse';
    case EditorTool.line:
      return 'line';
    case EditorTool.arrow:
      return 'arrow';
    case EditorTool.text:
      return 'text';
    case EditorTool.highlight:
      return 'highlight';
    case EditorTool.freehand:
      return 'freehand';
    case EditorTool.erase:
      return 'rubber';
    case EditorTool.crop:
      return 'crop';
    default:
      return 'select';
  }
});

/// Canvas尺寸提供者
final canvasSizeProvider = Provider<Size>((ref) {
  final editorState = ref.watch(editorStateProvider);
  return editorState.originalImageSize ?? const Size(800, 600);
});

/// 画布总尺寸提供者（包含内边距）
final canvasTotalSizeProvider = StateProvider<Size>((ref) {
  final canvasSize = ref.watch(canvasSizeProvider);
  final padding = ref.watch(canvasPaddingProvider);
  return Size(
    canvasSize.width + padding.left + padding.right,
    canvasSize.height + padding.top + padding.bottom,
  );
});

/// 画布内边距提供者 - 直接使用wallpaperSettingsProvider中的padding值
final canvasPaddingProvider = Provider<EdgeInsets>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
  return EdgeInsets.all(wallpaperSettings.padding);
});

/// 统一内边距提供者 - 返回wallpaperSettings中的padding值，保持向后兼容
final uniformPaddingProvider = Provider<double>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
  return wallpaperSettings.padding;
});

/// 画布背景装饰提供者
final canvasBackgroundDecorationProvider = Provider<BoxDecoration?>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);

  // 如果没有应用壁纸，返回null
  if (wallpaperSettings.type == WallpaperType.none) {
    return null;
  }

  // 根据壁纸类型创建不同的装饰
  switch (wallpaperSettings.type) {
    case WallpaperType.plainColor:
      return BoxDecoration(
        color: wallpaperSettings.backgroundColor,
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
        boxShadow: wallpaperSettings.shadowRadius > 0
            ? [
                BoxShadow(
                  color: wallpaperSettings.shadowColor,
                  blurRadius: wallpaperSettings.shadowRadius,
                  offset: wallpaperSettings.shadowOffset,
                ),
              ]
            : null,
      );

    case WallpaperType.gradient:
      final gradientIndex = wallpaperSettings.selectedGradientIndex;
      if (gradientIndex != null && gradientIndex < gradientPresets.length) {
        return BoxDecoration(
          gradient: gradientPresets[gradientIndex].gradient,
          borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
          boxShadow: wallpaperSettings.shadowRadius > 0
              ? [
                  BoxShadow(
                    color: wallpaperSettings.shadowColor,
                    blurRadius: wallpaperSettings.shadowRadius,
                    offset: wallpaperSettings.shadowOffset,
                  ),
                ]
              : null,
        );
      }
      return BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
      );

    case WallpaperType.blurred:
      Color blurColor = Colors.white;
      if (wallpaperSettings.selectedBlurIndex != null &&
          wallpaperSettings.selectedBlurIndex! < blurredPresets.length) {
        blurColor = blurredPresets[wallpaperSettings.selectedBlurIndex!];
      }
      return BoxDecoration(
        color: blurColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
        boxShadow: wallpaperSettings.shadowRadius > 0
            ? [
                BoxShadow(
                  color: wallpaperSettings.shadowColor,
                  blurRadius: wallpaperSettings.shadowRadius,
                  offset: wallpaperSettings.shadowOffset,
                ),
              ]
            : null,
        backgroundBlendMode: BlendMode.overlay,
      );

    case WallpaperType.wallpaper:
      // 自定义壁纸暂不实现，返回默认装饰
      return BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
        boxShadow: wallpaperSettings.shadowRadius > 0
            ? [
                BoxShadow(
                  color: wallpaperSettings.shadowColor,
                  blurRadius: wallpaperSettings.shadowRadius,
                  offset: wallpaperSettings.shadowOffset,
                ),
              ]
            : null,
      );

    default:
      return null;
  }
});

/// 绘图对象边界Provider
/// 用于跟踪当前绘图对象的边界矩形，支持自动扩展画布
final drawableBoundsProvider = StateProvider<Rect?>((ref) => null);

/// 滚动条显示Provider
final showScrollbarsProvider = Provider<bool>((ref) {
  // 直接 watch NotifierProvider 来获取状态
  final layoutState = ref.watch(layoutProvider);
  final transformState = ref.watch(canvasTransformProvider);
  final editorState = ref.watch(editorStateProvider);

  // 如果没有图像数据，不显示滚动条
  if (editorState.currentImageData == null ||
      editorState.originalImageSize == null) {
    return false;
  }

  final imageSize = editorState.originalImageSize!;
  final canvasSize = layoutState.currentCanvasViewSize;
  final zoomLevel = transformState.zoomLevel;

  // 计算缩放后的内容尺寸
  final scaledWidth = imageSize.width * zoomLevel;
  final scaledHeight = imageSize.height * zoomLevel;

  // 考虑背景边距
  final paddingHorizontal =
      editorState.wallpaperPadding.left + editorState.wallpaperPadding.right;
  final paddingVertical =
      editorState.wallpaperPadding.top + editorState.wallpaperPadding.bottom;

  final totalWidth = scaledWidth + paddingHorizontal;
  final totalHeight = scaledHeight + paddingVertical;

  // 如果内容宽度大于画布宽度，或者内容高度大于画布高度，则显示滚动条
  final needsScrollbars = totalWidth > canvasSize.width ||
      totalHeight > canvasSize.height ||
      transformState.canvasOffset != Offset.zero;

  return needsScrollbars;
});

/// 更新画布内边距
/// 可以更新单个边或所有边的内边距
void updateCanvasPadding(
  WidgetRef ref, {
  double? all,
  double? left,
  double? top,
  double? right,
  double? bottom,
}) {
  // 直接更新wallpaperSettingsProvider的padding
  if (all != null) {
    ref.read(wallpaperSettingsProvider.notifier).setPadding(all);
    return;
  }

  // 如果需要独立设置各边的内边距，可以在此扩展
  // 当前wallpaperSettingsState只支持统一的内边距，所以这里暂不实现
}

/// 获取画布尺寸信息
/// 返回原始尺寸、内边距和总尺寸
Map<String, dynamic> getCanvasSizeInfo(WidgetRef ref) {
  final originalSize = ref.read(canvasSizeProvider);
  final padding = ref.read(canvasPaddingProvider);
  final totalSize = ref.read(canvasTotalSizeProvider);

  return {
    'originalSize': originalSize,
    'padding': padding,
    'totalSize': totalSize,
    'scale': ref.read(canvasScaleProvider),
  };
}
