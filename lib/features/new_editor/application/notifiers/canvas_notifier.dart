import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../states/canvas_state.dart';

/// 画布状态更新器
/// 负责管理画布状态的所有更新操作
class CanvasNotifier extends StateNotifier<CanvasState> {
  final Logger _logger = Logger();

  /// 最小缩放级别
  static const double minZoom = 0.3;

  /// 最大缩放级别
  static const double maxZoom = 5.0;

  /// 构造函数
  CanvasNotifier() : super(CanvasState.initial());

  /// 加载截图数据
  void loadScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) {
    _logger.d('加载截图: 尺寸=${size.width}x${size.height}, 比例=$capturedScale');

    // 计算总尺寸 (包含内边距)
    final padding = state.padding;
    final totalWidth = size.width + padding.left + padding.right;
    final totalHeight = size.height + padding.top + padding.bottom;
    final totalSize = Size(totalWidth, totalHeight);

    // 计算适合视口的缩放比例
    final newState = state.copyWith(
      imageData: imageData,
      originalImageSize: size,
      uiImage: uiImage,
      capturedScale: capturedScale,
      totalSize: totalSize,
      isLoading: false,
    );

    // 更新状态
    state = newState;

    // 自动调整缩放和居中
    fitContent();
  }

  /// 设置图像尺寸
  void setImageSize(Size size) {
    _logger.d('设置图像尺寸: ${size.width}x${size.height}');

    // 计算总尺寸（包含内边距）
    final padding = state.padding;
    final totalWidth = size.width + padding.left + padding.right;
    final totalHeight = size.height + padding.top + padding.bottom;
    final totalSize = Size(totalWidth, totalHeight);

    state = state.copyWith(
      originalImageSize: size,
      totalSize: totalSize,
    );
  }

  /// 设置缩放级别
  void setScale(double newScale, {Offset? focalPoint}) {
    // 限制缩放范围
    final clampedScale = newScale.clamp(minZoom, maxZoom);

    if (clampedScale == state.scale) return;

    _logger.d('设置缩放级别: $clampedScale, 焦点: $focalPoint');

    // 如果指定了焦点，则围绕焦点缩放
    if (focalPoint != null) {
      // 计算围绕焦点的缩放
      final double scaleFactor = clampedScale / state.scale;

      // 当前偏移量
      final currentOffset = state.offset;

      // 计算新的偏移量，保持焦点位置不变
      final newOffset = Offset(
        focalPoint.dx - (focalPoint.dx - currentOffset.dx) * scaleFactor,
        focalPoint.dy - (focalPoint.dy - currentOffset.dy) * scaleFactor,
      );

      state = state.copyWith(scale: clampedScale, offset: newOffset);
    } else {
      // 简单更新缩放级别
      state = state.copyWith(scale: clampedScale);
    }
  }

  /// 设置偏移量
  void setOffset(Offset newOffset) {
    if (newOffset == state.offset) return;

    _logger.d('设置偏移量: $newOffset');
    state = state.copyWith(offset: newOffset);
  }

  /// 更新偏移量 (增量)
  void updateOffset(Offset delta) {
    final newOffset = state.offset.translate(delta.dx, delta.dy);
    _logger.d('更新偏移量: $delta, 新偏移: $newOffset');

    state = state.copyWith(offset: newOffset);
  }

  /// 设置内边距并重新计算总尺寸
  void setPadding(EdgeInsets padding) {
    if (padding == state.padding) return;

    _logger.d('设置内边距: $padding');

    // 如果没有原始尺寸，只更新内边距
    if (state.originalImageSize == null) {
      state = state.copyWith(padding: padding);
      return;
    }

    // 计算新的总尺寸
    final totalWidth =
        state.originalImageSize!.width + padding.left + padding.right;
    final totalHeight =
        state.originalImageSize!.height + padding.top + padding.bottom;
    final totalSize = Size(totalWidth, totalHeight);

    state = state.copyWith(
      padding: padding,
      totalSize: totalSize,
    );

    // 更新内边距后重新调整内容适应视口
    fitContent();
  }

  /// 设置视口尺寸
  void setViewportSize(Size size) {
    if (size == state.viewportSize) return;

    _logger.d('设置视口尺寸: ${size.width}x${size.height}');
    state = state.copyWith(viewportSize: size);

    // 视口尺寸改变后重新调整内容适应视口
    fitContent();
  }

  /// 设置加载状态
  void setLoading(bool isLoading) {
    if (isLoading == state.isLoading) return;

    _logger.d('设置加载状态: $isLoading');
    state = state.copyWith(isLoading: isLoading);
  }

  /// 重置变换 (缩放和偏移)
  void resetTransform() {
    _logger.d('重置变换');

    state = state.copyWith(
      scale: 1.0,
      offset: Offset.zero,
    );
  }

  /// 调整内容适应视口
  void fitContent() {
    if (state.originalImageSize == null || state.totalSize == null) return;

    // 计算适合视口的缩放比例
    final fitScale = state.calculateFitScale();

    // 计算使内容居中的偏移量
    final scaledWidth = state.totalSize!.width * fitScale;
    final scaledHeight = state.totalSize!.height * fitScale;

    final offsetX = (state.viewportSize.width - scaledWidth) / 2;
    final offsetY = (state.viewportSize.height - scaledHeight) / 2;

    _logger.d('适应内容: 适合缩放=$fitScale, 居中偏移=($offsetX, $offsetY)');

    state = state.copyWith(
      scale: fitScale,
      offset: Offset(offsetX, offsetY),
    );
  }

  /// 处理围绕焦点的缩放开始
  void startScale(Offset focalPoint) {
    // 保存当前缩放状态，无需更新状态
    _logger.d('开始缩放: 焦点=$focalPoint');
  }

  /// 处理围绕焦点的缩放更新
  void updateScale(double scaleFactor, Offset focalPoint) {
    if (scaleFactor == 1.0) return;

    // 计算新的缩放级别
    final newScale = state.scale * scaleFactor;

    // 使用设置缩放级别方法，确保围绕焦点缩放
    setScale(newScale, focalPoint: focalPoint);
  }

  /// 处理缩放结束
  void endScale() {
    // 缩放结束，可以执行一些清理或优化操作
    _logger.d('结束缩放');
  }

  /// 设置壁纸启用状态
  void setWallpaperEnabled(bool enabled) {
    _logger.d('设置壁纸启用状态: $enabled');

    state = state.copyWith(isWallpaperEnabled: enabled);
  }
}
