import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'canvas_state.freezed.dart';

/// 画布状态
@freezed
class CanvasState with _$CanvasState {
  const factory CanvasState({
    /// 画布缩放比例
    @Default(1.0) double scale,

    /// 画布偏移量
    @Default(Offset.zero) Offset offset,

    /// 画布尺寸
    Size? size,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否显示网格
    @Default(false) bool showGrid,

    /// 是否显示标尺
    @Default(false) bool showRuler,
  }) = _CanvasState;
}
