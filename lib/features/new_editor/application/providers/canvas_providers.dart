import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../states/canvas_state.dart';
import '../notifiers/canvas_notifier.dart';
import 'state_providers.dart';
import 'wallpaper_providers.dart';

/// 可绘制对象边界提供者
/// 用于跟踪绘制内容的边界矩形
final drawableBoundsProvider = StateProvider<Rect?>((ref) => null);

/// 画布尺寸提供者
/// 提供当前画布的尺寸（不包含内边距）
final canvasSizeProvider = Provider<Size>((ref) {
  final canvasState = ref.watch(canvasProvider);
  return canvasState.originalImageSize ?? const Size(800, 600);
});

/// 画布内边距提供者
/// 提供当前画布的内边距
final canvasPaddingProvider = Provider<EdgeInsets>((ref) {
  final canvasState = ref.watch(canvasProvider);
  return canvasState.padding;
});

/// 画布总尺寸提供者
/// 提供当前画布的总尺寸（包含内边距）
final canvasTotalSizeProvider = Provider<Size>((ref) {
  final canvasState = ref.watch(canvasProvider);
  final size = canvasState.originalImageSize ?? const Size(800, 600);
  final padding = canvasState.padding;

  return Size(
    size.width + padding.left + padding.right,
    size.height + padding.top + padding.bottom,
  );
});

/// 画布背景装饰提供者
/// 根据壁纸设置提供背景装饰
@Deprecated('请使用wallpaperDecorationProvider替代')
final canvasBackgroundDecorationProvider = Provider<BoxDecoration?>((ref) {
  // 转发到新的壁纸装饰提供者
  return ref.watch(wallpaperDecorationProvider);
});

/// 画布适应缩放比例提供者
/// 计算使内容适应视口的缩放比例
final contentFitScaleProvider =
    Provider.family<double, Size>((ref, availableSize) {
  final logger = Logger();
  final canvasState = ref.watch(canvasProvider);

  // 如果画布尺寸未设置，返回默认缩放比例
  if (canvasState.totalSize == null) {
    return 1.0;
  }

  final contentSize = canvasState.totalSize!;

  // 计算宽高比
  final widthRatio = availableSize.width / contentSize.width;
  final heightRatio = availableSize.height / contentSize.height;

  // 取较小值确保内容完全可见
  final fitScale = widthRatio < heightRatio ? widthRatio : heightRatio;

  // 限制最小缩放级别为 0.1，避免内容过小
  final clampedScale = fitScale < 0.1 ? 0.1 : fitScale;

  // 限制最大缩放级别为 1.0，避免内容过大超出视口
  final finalScale = clampedScale > 1.0 ? 1.0 : clampedScale;

  logger.d('计算内容适应缩放: 可用尺寸=${availableSize.width}x${availableSize.height}, '
      '内容尺寸=${contentSize.width}x${contentSize.height}, '
      '最终缩放=$finalScale');

  return finalScale;
});

/// 画布是否溢出视口提供者
/// 判断当前画布内容是否超出可视区域
final canvasOverflowProvider = Provider<bool>((ref) {
  final canvasState = ref.watch(canvasProvider);
  return canvasState.isOverflowing;
});

/// 画布变换状态类
class CanvasTransformState {
  /// 缩放级别
  final double zoomLevel;

  /// 画布偏移量
  final Offset canvasOffset;

  /// 是否正在缩放
  final bool isScaling;

  /// 缩放开始时的焦点
  final Offset? scaleStartFocalPoint;

  /// 缩放开始时的缩放级别
  final double scaleStartZoomLevel;

  /// 构造函数
  const CanvasTransformState({
    this.zoomLevel = 1.0,
    this.canvasOffset = Offset.zero,
    this.isScaling = false,
    this.scaleStartFocalPoint,
    this.scaleStartZoomLevel = 1.0,
  });

  /// 创建副本
  CanvasTransformState copyWith({
    double? zoomLevel,
    Offset? canvasOffset,
    bool? isScaling,
    Offset? scaleStartFocalPoint,
    double? scaleStartZoomLevel,
  }) {
    return CanvasTransformState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      canvasOffset: canvasOffset ?? this.canvasOffset,
      isScaling: isScaling ?? this.isScaling,
      scaleStartFocalPoint: scaleStartFocalPoint ?? this.scaleStartFocalPoint,
      scaleStartZoomLevel: scaleStartZoomLevel ?? this.scaleStartZoomLevel,
    );
  }
}

/// 画布变换通知器
class CanvasTransformNotifier extends StateNotifier<CanvasTransformState> {
  /// 记录上次缩放值
  double _lastScale = 1.0;

  /// 构造函数
  CanvasTransformNotifier() : super(const CanvasTransformState());

  /// 设置缩放级别
  void setZoomLevel(double zoomLevel) {
    state = state.copyWith(zoomLevel: zoomLevel);
  }

  /// 设置偏移量
  void setOffset(Offset offset) {
    state = state.copyWith(canvasOffset: offset);
  }

  /// 开始缩放
  void startScale(Offset focalPoint) {
    state = state.copyWith(
      isScaling: true,
      scaleStartFocalPoint: focalPoint,
      scaleStartZoomLevel: state.zoomLevel,
    );
    _lastScale = 1.0;
  }

  /// 更新缩放
  void updateScale(double scale, Offset focalPoint) {
    if (!state.isScaling) return;

    final double deltaScale = scale / _lastScale;
    _lastScale = scale;

    final newZoomLevel = (state.scaleStartZoomLevel * scale).clamp(0.1, 5.0);
    state = state.copyWith(zoomLevel: newZoomLevel);
  }

  /// 更新平移
  void updateTranslation(Offset delta) {
    final newOffset = state.canvasOffset + delta;
    state = state.copyWith(canvasOffset: newOffset);
  }

  /// 结束缩放
  void endScale() {
    state = state.copyWith(
      isScaling: false,
      scaleStartFocalPoint: null,
    );
  }
}

/// 画布变换状态提供者
final canvasTransformProvider =
    StateNotifierProvider<CanvasTransformNotifier, CanvasTransformState>((ref) {
  return CanvasTransformNotifier();
});

/// 画布缩放比例提供者
final canvasScaleProvider = StateProvider<double>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  return transformState.zoomLevel;
});
