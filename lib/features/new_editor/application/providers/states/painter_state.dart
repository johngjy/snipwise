import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';

part 'painter_state.freezed.dart';

/// 绘制模式枚举
enum DrawingMode {
  none,
  selection,
  pen,
  line,
  rectangle,
  oval,
  text,
  eraser,
  arrow,
}

/// 绘图工具状态
@freezed
class PainterState with _$PainterState {
  const factory PainterState({
    /// 当前绘制模式
    @Default(DrawingMode.none) DrawingMode drawingMode,

    /// 线条宽度
    @Default(2.0) double strokeWidth,

    /// 线条颜色
    @Default(Colors.red) Color strokeColor,

    /// 填充颜色
    @Default(Colors.blue) Color fillColor,

    /// 是否填充
    @Default(false) bool isFilled,

    /// 是否显示调色板
    @Default(false) bool showColorPicker,

    /// 文本缓存
    @Default([]) List<String> textCache,

    /// 是否显示文本缓存对话框
    @Default(false) bool showTextCacheDialog,

    /// 选中的绘图对象
    ObjectDrawable? selectedObject,

    /// 绘图控制器
    PainterController? controller,
  }) = _PainterState;
}
