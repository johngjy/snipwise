import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/canvas_transform_state.dart' as cts;
import '../states/wallpaper_settings_state.dart';
import '../notifiers/wallpaper_settings_notifier.dart';
import 'core_providers.dart';

/// 画布尺寸提供者
/// 基于编辑器状态获取原始截图尺寸
final canvasSizeProvider = Provider<Size>((ref) {
  final editorState = ref.watch(editorStateProvider);
  return editorState.originalImageSize ?? const Size(800, 600);
});

/// 画布缩放比例提供者
/// 从画布变换状态中提取当前缩放比例，便于UI组件访问
final canvasScaleProvider = StateProvider<double>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  return transformState.zoomLevel;
});

/// 画布内边距提供者
/// 从壁纸设置中提取内边距数据，转换为EdgeInsets
final canvasPaddingProvider = Provider<EdgeInsets>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
  return EdgeInsets.all(wallpaperSettings.padding);
});

/// 统一内边距值提供者
/// 保持向后兼容，直接返回壁纸设置中的padding值
final uniformPaddingProvider = Provider<double>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
  return wallpaperSettings.padding;
});

/// 画布总尺寸提供者（包含内边距）
/// 计算原始尺寸加上内边距后的总尺寸
final canvasTotalSizeProvider = Provider<Size>((ref) {
  final canvasSize = ref.watch(canvasSizeProvider);
  final padding = ref.watch(canvasPaddingProvider);
  return Size(
    canvasSize.width + padding.left + padding.right,
    canvasSize.height + padding.top + padding.bottom,
  );
});

/// 壁纸背景图像提供者
/// 从编辑器状态提取当前图像数据
final wallpaperImageProvider = Provider<Uint8List?>((ref) {
  final editorState = ref.watch(editorStateProvider);
  return editorState.currentImageData;
});

/// 绘图对象边界提供者
/// 用于跟踪当前绘图对象的边界矩形，支持自动扩展画布
final drawableBoundsProvider = StateProvider<Rect?>((ref) => null);

/// 画布是否超出可视区域提供者
/// 用于判断是否需要显示滚动条
final canvasOverflowProvider = Provider<bool>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  final layoutState = ref.watch(layoutProvider);
  final canvasSize = ref.watch(canvasTotalSizeProvider);

  // 缩放超过1.0或内容超出可视区域，判定为溢出
  final isScaledUp = transformState.zoomLevel > 1.0;
  final isWidthOverflow = canvasSize.width * transformState.zoomLevel >
      layoutState.currentCanvasViewSize.width;
  final isHeightOverflow = canvasSize.height * transformState.zoomLevel >
      layoutState.currentCanvasViewSize.height;

  return isScaledUp || isWidthOverflow || isHeightOverflow;
});

/// 内容适应缩放因子提供者
/// 计算使内容适应可用空间的缩放比例
final contentFitScaleProvider =
    Provider.family<double, Size>((ref, availableSize) {
  final contentSize = ref.watch(canvasTotalSizeProvider);

  // 如果内容超出可用区域，计算需要的缩放系数
  if (contentSize.width > availableSize.width ||
      contentSize.height > availableSize.height) {
    final widthRatio = availableSize.width / contentSize.width;
    final heightRatio = availableSize.height / contentSize.height;
    // 取较小值确保完全可见
    return math.min(widthRatio, heightRatio);
  }

  // 默认不缩放
  return 1.0;
});

/// 显示滚动条提供者
/// 判断是否需要显示滚动条
final showScrollbarsProvider = Provider<bool>((ref) {
  return ref.watch(canvasOverflowProvider);
});

/// 画布背景装饰提供者
/// 根据壁纸设置创建对应的背景装饰效果
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
      // 自定义壁纸
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
