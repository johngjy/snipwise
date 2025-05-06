import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/canvas_transform_notifier.dart';

/// CanvasTransformConnector类
/// 负责连接CanvasTransform和FlutterPainter的变换操作
///
/// 主要功能：
/// 1. 将CanvasTransform的变换应用到FlutterPainter
/// 2. 提供处理缩放和平移手势的方法
/// 3. 处理鼠标滚轮缩放
class CanvasTransformConnector {
  final Ref ref;

  CanvasTransformConnector(this.ref);

  /// 处理缩放开始事件
  void handleScaleStart(ScaleStartDetails details) {
    ref.read(canvasTransformProvider.notifier).startScale(details.focalPoint);
  }

  /// 处理缩放更新事件
  void handleScaleUpdate(ScaleUpdateDetails details) {
    // 处理缩放
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
  void handleScaleEnd(ScaleEndDetails details) {
    ref.read(canvasTransformProvider.notifier).endScale();
  }

  /// 处理鼠标滚轮缩放
  void handleMouseWheelZoom(PointerScrollEvent event, Offset localPosition) {
    // 检查设备类型（触控板或鼠标）
    final isTrackpad = event.kind == PointerDeviceKind.trackpad;

    if (kDebugMode) {
      print(
          'Mouse Wheel Event: delta=${event.scrollDelta}, position=$localPosition, kind=${event.kind}');
    }

    // 获取滚动增量
    final double deltaX = event.scrollDelta.dx;
    final double deltaY = event.scrollDelta.dy;

    // 检测是否为水平滚动 - 主要用于触控板的手势判断
    final bool isHorizontalScroll = deltaX.abs() > deltaY.abs();

    // 触控板处理逻辑
    if (isTrackpad) {
      // 处理触控板手势
      if (isHorizontalScroll) {
        // 水平滚动 - 可作为左右平移
        ref.read(canvasTransformProvider.notifier).updateTranslation(
              Offset(-deltaX, 0),
            );
      } else {
        // 垂直滚动 - 作为缩放处理
        // 计算缩放系数 - 触控板滚动通常较小，使用更敏感的缩放因子
        final scaleFactor = deltaY > 0 ? 0.98 : 1.02; // 触控板使用较小的增量

        // 获取当前缩放级别
        final currentZoomLevel = ref.read(canvasTransformProvider).zoomLevel;

        // 计算新的缩放级别
        final newZoomLevel = currentZoomLevel * scaleFactor;

        // 设置新的缩放级别，使用鼠标位置作为缩放中心点
        ref.read(canvasTransformProvider.notifier).setZoomLevel(
              newZoomLevel,
              focalPoint: localPosition,
            );
      }
    }
    // 鼠标滚轮处理逻辑
    else {
      // 适当增加缩放的敏感度，使缩放更为明显
      final scaleFactor = deltaY > 0 ? 0.92 : 1.08; // 8%的缩放变化

      // 获取当前缩放级别
      final currentZoomLevel = ref.read(canvasTransformProvider).zoomLevel;

      // 计算新的缩放级别
      final newZoomLevel = currentZoomLevel * scaleFactor;

      // 设置新的缩放级别，使用鼠标位置作为缩放中心点
      ref.read(canvasTransformProvider.notifier).setZoomLevel(
            newZoomLevel,
            focalPoint: localPosition,
          );
    }
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
