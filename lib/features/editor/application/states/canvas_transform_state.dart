import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 画布变换状态类
class CanvasTransformState extends Equatable {
  /// 缩放比例
  final double scaleFactor;

  /// 画布偏移量
  final Offset canvasOffset;

  /// 当前缩放级别（用于UI显示）
  final double zoomLevel;

  /// 是否正在缩放
  final bool isScaling;

  /// 缩放开始时的焦点
  final Offset? scaleStartFocalPoint;

  /// 缩放开始时的缩放级别
  final double scaleStartZoomLevel;

  /// 最小缩放级别
  static const double minZoom = 0.3;

  /// 最大缩放级别
  static const double maxZoom = 5.0;

  const CanvasTransformState({
    this.scaleFactor = 1.0,
    this.canvasOffset = Offset.zero,
    this.zoomLevel = 1.0,
    this.isScaling = false,
    this.scaleStartFocalPoint,
    this.scaleStartZoomLevel = 1.0,
  });

  /// 创建初始状态
  factory CanvasTransformState.initial() => const CanvasTransformState();

  /// 使用copyWith创建新实例
  CanvasTransformState copyWith({
    double? scaleFactor,
    Offset? canvasOffset,
    double? zoomLevel,
    bool? isScaling,
    Offset? scaleStartFocalPoint,
    double? scaleStartZoomLevel,
  }) {
    return CanvasTransformState(
      scaleFactor: scaleFactor ?? this.scaleFactor,
      canvasOffset: canvasOffset ?? this.canvasOffset,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isScaling: isScaling ?? this.isScaling,
      scaleStartFocalPoint: scaleStartFocalPoint ?? this.scaleStartFocalPoint,
      scaleStartZoomLevel: scaleStartZoomLevel ?? this.scaleStartZoomLevel,
    );
  }

  @override
  List<Object?> get props => [
        scaleFactor,
        canvasOffset,
        zoomLevel,
        isScaling,
        scaleStartFocalPoint,
        scaleStartZoomLevel
      ];
}
