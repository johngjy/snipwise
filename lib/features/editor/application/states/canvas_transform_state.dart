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

  /// 最小缩放级别
  static const double minZoom = 0.1;

  /// 最大缩放级别
  static const double maxZoom = 5.0;

  const CanvasTransformState({
    this.scaleFactor = 1.0,
    this.canvasOffset = Offset.zero,
    this.zoomLevel = 1.0,
  });

  /// 创建初始状态
  factory CanvasTransformState.initial() => const CanvasTransformState();

  /// 使用copyWith创建新实例
  CanvasTransformState copyWith({
    double? scaleFactor,
    Offset? canvasOffset,
    double? zoomLevel,
  }) {
    return CanvasTransformState(
      scaleFactor: scaleFactor ?? this.scaleFactor,
      canvasOffset: canvasOffset ?? this.canvasOffset,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  @override
  List<Object> get props => [scaleFactor, canvasOffset, zoomLevel];
}
