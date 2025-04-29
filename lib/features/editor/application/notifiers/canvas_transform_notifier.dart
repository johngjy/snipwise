import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/canvas_transform_state.dart';

/// 画布变换管理器Notifier
class CanvasTransformNotifier extends Notifier<CanvasTransformState> {
  @override
  CanvasTransformState build() => CanvasTransformState.initial();

  /// 设置初始缩放
  void setInitialScale(double scale) {
    state = state.copyWith(
      scaleFactor: scale,
      canvasOffset: Offset.zero,
      zoomLevel: scale, // 确保同步更新zoomLevel
    );
  }

  /// 更新缩放
  void updateZoom(double newScale, Offset focalPoint) {
    final double clampedScale = newScale.clamp(
      CanvasTransformState.minZoom,
      CanvasTransformState.maxZoom,
    );

    final double dx = focalPoint.dx;
    final double dy = focalPoint.dy;

    // 计算用于缩放的变换矩阵
    final Offset oldOffset = state.canvasOffset;
    final Offset newOffset = Offset(
      dx - (dx - oldOffset.dx) * (clampedScale / state.scaleFactor),
      dy - (dy - oldOffset.dy) * (clampedScale / state.scaleFactor),
    );

    state = state.copyWith(
      scaleFactor: clampedScale,
      canvasOffset: newOffset,
      zoomLevel: clampedScale, // 更新zoomLevel
    );
  }

  /// 更新偏移
  void updateOffset(Offset delta) {
    final Offset newOffset = state.canvasOffset.translate(
      delta.dx,
      delta.dy,
    );

    state = state.copyWith(canvasOffset: newOffset);
  }

  /// 重置变换
  void resetTransform() {
    state = state.copyWith(
      scaleFactor: 1.0,
      canvasOffset: Offset.zero,
      zoomLevel: 1.0, // 重置zoomLevel
    );
  }

  /// 适应窗口
  void fitToWindow(Size imageSize, Size availableSize) {
    final double fitZoom = _calculateFitZoomLevel(availableSize, imageSize);

    // 重置变换并应用新的缩放
    resetTransform();
    setZoomLevel(fitZoom);
  }

  /// 设置缩放级别（直接设置视觉缩放值）
  void setZoomLevel(double newZoom, {Offset? focalPoint}) {
    // 确保缩放值在最小和最大范围内
    final clampedZoom = newZoom.clamp(
        CanvasTransformState.minZoom, CanvasTransformState.maxZoom);

    // 获取当前和目标缩放比例，计算缩放增量
    final double currentZoom = state.zoomLevel;
    final double scaleDelta = clampedZoom / currentZoom;

    // 如果没有实质变化，直接返回
    if (clampedZoom == currentZoom || clampedZoom <= 0) {
      return;
    }

    // 如果提供了焦点（如鼠标位置），则围绕该点缩放
    if (focalPoint != null) {
      // 计算以焦点为中心的变换
      final double dx = focalPoint.dx;
      final double dy = focalPoint.dy;

      // 计算新的画布偏移量
      final Offset currentOffset = state.canvasOffset;
      final Offset newOffset = Offset(
        dx - (dx - currentOffset.dx) * scaleDelta,
        dy - (dy - currentOffset.dy) * scaleDelta,
      );

      // 更新状态
      state = state.copyWith(
        scaleFactor: state.scaleFactor * scaleDelta,
        canvasOffset: newOffset,
        zoomLevel: clampedZoom,
      );
    } else {
      // 没有焦点时直接缩放，保持中心点不变
      state = state.copyWith(
        scaleFactor: state.scaleFactor * scaleDelta,
        zoomLevel: clampedZoom,
      );
    }
  }

  /// 计算适合窗口的缩放级别
  double _calculateFitZoomLevel(Size availableSize, Size imageSize) {
    if (imageSize.width <= 0 ||
        imageSize.height <= 0 ||
        availableSize.width <= 0 ||
        availableSize.height <= 0) {
      return 1.0; // 避免除以零或无效计算
    }

    // 应用视觉边距
    final double availableWidth = availableSize.width * 0.94; // 减去6%的水平边距
    final double availableHeight = availableSize.height * 0.94; // 减去6%的垂直边距

    // 计算宽高比
    final double viewAspectRatio = availableWidth / availableHeight;
    final double imageAspectRatio = imageSize.width / imageSize.height;

    double fitZoom;
    if (viewAspectRatio > imageAspectRatio) {
      // 视图比图片更宽，以高度为基准进行缩放
      fitZoom = availableHeight / imageSize.height;
    } else {
      // 视图比图片更高或宽高比接近，以宽度为基准进行缩放
      fitZoom = availableWidth / imageSize.width;
    }

    return fitZoom;
  }
}
