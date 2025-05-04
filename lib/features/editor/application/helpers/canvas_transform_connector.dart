import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../notifiers/canvas_transform_notifier.dart';
import '../states/canvas_transform_state.dart' as cts;

/// CanvasTransformConnector类
/// 负责连接CanvasTransform和FlutterPainter的变换操作
///
/// 主要功能：
/// 1. 将CanvasTransform的变换应用到FlutterPainter
/// 2. 提供处理缩放和平移手势的方法
/// 3. 处理鼠标滚轮缩放
/// 4. 支持触控设备的特殊交互
class CanvasTransformConnector {
  final Ref ref;

  // 内容边界 - 用于限制偏移量以防内容完全离开视图
  Size _contentSize = const Size(800, 600);
  Size _viewportSize = const Size(1024, 768);

  // 设备类型检测
  bool _isTrackpad = false;

  CanvasTransformConnector(this.ref);

  /// 设置视图大小，用于边界检查
  void setViewportSize(Size size) {
    _viewportSize = size;
  }

  /// 设置内容大小，用于边界检查
  void setContentSize(Size size) {
    _contentSize = size;
  }

  /// 处理缩放开始事件
  void handleScaleStart(ScaleStartDetails details) {
    ref.read(canvasTransformProvider.notifier).startScale(details.focalPoint);
  }

  /// 处理缩放更新事件
  void handleScaleUpdate(ScaleUpdateDetails details) {
    // 检测是否为触控板/触屏设备的缩放手势
    final bool isMultiTouch = details.pointerCount > 1;

    // 处理缩放
    if (details.scale != 1.0) {
      ref.read(canvasTransformProvider.notifier).updateScale(
            details.scale,
            details.focalPoint,
          );
    }

    // 处理平移 - 只有在单指操作或非缩放时处理平移
    if (details.focalPointDelta != Offset.zero &&
        (!isMultiTouch || details.scale == 1.0)) {
      final transformState = ref.read(canvasTransformProvider);

      // 只有在缩放级别大于1.0或内容超出视口时才允许拖动
      if (transformState.zoomLevel > 1.0 || _isContentOverflowing()) {
        // 计算安全的偏移量，避免内容完全移出视图
        final safeOffset = _calculateSafeOffset(
            transformState.canvasOffset, details.focalPointDelta);

        ref
            .read(canvasTransformProvider.notifier)
            .updateTranslation(safeOffset);
      }
    }
  }

  /// 处理缩放结束事件
  void handleScaleEnd(ScaleEndDetails details) {
    ref.read(canvasTransformProvider.notifier).endScale();
  }

  /// 处理鼠标滚轮缩放
  /// 根据鼠标滚轮的滚动方向和位置调整缩放
  void handleMouseWheelZoom(PointerScrollEvent event, Offset localPosition) {
    // 检测设备类型
    if (event.kind == PointerDeviceKind.trackpad) {
      _isTrackpad = true;
      _handleTrackpadScroll(event, localPosition);
    } else {
      _isTrackpad = false;
      _handleMouseWheelScroll(event, localPosition);
    }
  }

  /// 处理触控板滚动
  void _handleTrackpadScroll(PointerScrollEvent event, Offset localPosition) {
    // 检测主要滚动方向
    final bool isHorizontalScroll =
        event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs();

    if (isHorizontalScroll) {
      // 水平滚动处理为水平平移
      final transformState = ref.read(canvasTransformProvider);
      final safeOffset = _calculateSafeOffset(
          transformState.canvasOffset, Offset(-event.scrollDelta.dx, 0));
      ref.read(canvasTransformProvider.notifier).updateTranslation(safeOffset);
    } else {
      // 垂直滚动处理为缩放
      _updateZoomLevelWithSafetyChecks(
          event.scrollDelta.dy > 0 ? 0.95 : 1.05, localPosition);
    }
  }

  /// 处理鼠标滚轮滚动
  void _handleMouseWheelScroll(PointerScrollEvent event, Offset localPosition) {
    // 鼠标滚轮滚动处理为缩放
    _updateZoomLevelWithSafetyChecks(
        event.scrollDelta.dy > 0 ? 0.9 : 1.1, localPosition);
  }

  /// 使用安全检查更新缩放级别
  void _updateZoomLevelWithSafetyChecks(
      double scaleFactor, Offset localPosition) {
    // 确保localPosition在有效区域内
    if (!_isPositionInContent(localPosition)) {
      // 如果不在内容区域内，使用内容中心作为焦点
      localPosition = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    }

    // 当前缩放级别
    final currentState = ref.read(canvasTransformProvider);
    final currentZoom = currentState.zoomLevel;

    // 计算新的缩放级别
    final newZoom = currentZoom * scaleFactor;

    // 检查是否会缩放到极端值
    if ((newZoom < cts.CanvasTransformState.minZoom && scaleFactor < 1.0) ||
        (newZoom > cts.CanvasTransformState.maxZoom && scaleFactor > 1.0)) {
      // 达到缩放极限，不再更新
      return;
    }

    _updateZoomLevel(newZoom, localPosition);
  }

  /// 更新缩放级别的内部方法
  void _updateZoomLevel(double zoomLevel, Offset localPosition) {
    final transformNotifier = ref.read(canvasTransformProvider.notifier);

    // 约束缩放级别在合理范围内
    final constrainedZoom = zoomLevel.clamp(
      cts.CanvasTransformState.minZoom,
      cts.CanvasTransformState.maxZoom,
    );

    // 变化太小，忽略
    if ((constrainedZoom - ref.read(canvasTransformProvider).zoomLevel).abs() <
        0.001) {
      return;
    }

    // 当前状态
    final currentState = ref.read(canvasTransformProvider);
    final currentOffset = currentState.canvasOffset;

    // 计算新的缩放比例
    final scaleRatio = constrainedZoom / currentState.zoomLevel;

    // 计算焦点相对于当前偏移量的位置
    final focalPointX = localPosition.dx - currentOffset.dx;
    final focalPointY = localPosition.dy - currentOffset.dy;

    // 计算新的偏移量以保持焦点位置
    final newOffsetX = localPosition.dx - focalPointX * scaleRatio;
    final newOffsetY = localPosition.dy - focalPointY * scaleRatio;

    // 确保新的偏移量不会将内容完全移出视图
    final safeOffset =
        _ensureContentVisible(Offset(newOffsetX, newOffsetY), constrainedZoom);

    // 更新状态
    transformNotifier.setZoomAndOffset(constrainedZoom, safeOffset);
  }

  /// 计算安全的偏移量，避免内容完全移出视图
  Offset _calculateSafeOffset(Offset currentOffset, Offset delta) {
    final transformState = ref.read(canvasTransformProvider);
    final zoomLevel = transformState.zoomLevel;

    // 计算内容的缩放后尺寸
    final scaledContentWidth = _contentSize.width * zoomLevel;
    final scaledContentHeight = _contentSize.height * zoomLevel;

    // 计算新的偏移值
    final newOffsetX = currentOffset.dx + delta.dx;
    final newOffsetY = currentOffset.dy + delta.dy;

    // 确保至少有20%的内容始终可见
    final minVisiblePortion = 0.2;
    final maxOffsetX =
        _viewportSize.width - scaledContentWidth * minVisiblePortion;
    final minOffsetX = scaledContentWidth * (1 - minVisiblePortion) * -1;

    final maxOffsetY =
        _viewportSize.height - scaledContentHeight * minVisiblePortion;
    final minOffsetY = scaledContentHeight * (1 - minVisiblePortion) * -1;

    // 应用约束
    final safeX = newOffsetX.clamp(minOffsetX, maxOffsetX);
    final safeY = newOffsetY.clamp(minOffsetY, maxOffsetY);

    return Offset(safeX, safeY);
  }

  /// 确保内容始终保持可见
  Offset _ensureContentVisible(Offset offset, double zoom) {
    // 内容尺寸
    final scaledWidth = _contentSize.width * zoom;
    final scaledHeight = _contentSize.height * zoom;

    // 确保至少有20%的内容始终可见
    final minVisiblePortion = 0.2;
    final maxOffsetX = _viewportSize.width - scaledWidth * minVisiblePortion;
    final minOffsetX = scaledWidth * (1 - minVisiblePortion) * -1;

    final maxOffsetY = _viewportSize.height - scaledHeight * minVisiblePortion;
    final minOffsetY = scaledHeight * (1 - minVisiblePortion) * -1;

    // 应用约束
    final safeX = offset.dx.clamp(minOffsetX, maxOffsetX);
    final safeY = offset.dy.clamp(minOffsetY, maxOffsetY);

    return Offset(safeX, safeY);
  }

  /// 检查内容是否溢出视口
  bool _isContentOverflowing() {
    final transformState = ref.read(canvasTransformProvider);
    final zoom = transformState.zoomLevel;

    // 计算缩放后的内容尺寸
    final scaledWidth = _contentSize.width * zoom;
    final scaledHeight = _contentSize.height * zoom;

    // 如果内容大于视口，则认为溢出
    return scaledWidth > _viewportSize.width ||
        scaledHeight > _viewportSize.height;
  }

  /// 检查位置是否在内容区域内
  bool _isPositionInContent(Offset position) {
    final transformState = ref.read(canvasTransformProvider);
    final offset = transformState.canvasOffset;
    final zoom = transformState.zoomLevel;

    // 计算内容的边界
    final contentRect = Rect.fromLTWH(offset.dx, offset.dy,
        _contentSize.width * zoom, _contentSize.height * zoom);

    return contentRect.contains(position);
  }

  /// 处理缩放菜单选项
  void handleZoomMenuOption(String option) {
    switch (option) {
      case 'fit':
        _fitScreenshot();
        break;
      case 'actual':
        _actualSize();
        break;
      case 'zoom_in':
        _zoomIn();
        break;
      case 'zoom_out':
        _zoomOut();
        break;
    }
  }

  /// 重置变换
  void resetTransform() {
    ref.read(canvasTransformProvider.notifier).resetTransform();
  }

  /// 适应屏幕大小
  void _fitScreenshot() {
    // 这里应根据实际需求实现适应屏幕的逻辑
    // 暂时简单地将缩放级别设为0.8
    ref.read(canvasTransformProvider.notifier).setZoomLevel(0.8);
  }

  /// 实际大小（100%缩放）
  void _actualSize() {
    ref.read(canvasTransformProvider.notifier).setZoomLevel(1.0);
  }

  /// 放大
  void _zoomIn() {
    final currentZoom = ref.read(canvasTransformProvider).zoomLevel;
    final newZoom = currentZoom * 1.2; // 放大20%
    ref.read(canvasTransformProvider.notifier).setZoomLevel(newZoom);
  }

  /// 缩小
  void _zoomOut() {
    final currentZoom = ref.read(canvasTransformProvider).zoomLevel;
    final newZoom = currentZoom * 0.8; // 缩小20%
    ref.read(canvasTransformProvider.notifier).setZoomLevel(newZoom);
  }
}

/// CanvasTransformConnector提供者
final canvasTransformConnectorProvider =
    Provider<CanvasTransformConnector>((ref) {
  return CanvasTransformConnector(ref);
});
