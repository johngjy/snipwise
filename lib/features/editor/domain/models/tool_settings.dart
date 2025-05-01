import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/color_serializer.dart';

part 'tool_settings.freezed.dart';
part 'tool_settings.g.dart';

/// 工具设置 - 定义各类绘图工具的配置参数
@freezed
class ToolSettings with _$ToolSettings {
  const factory ToolSettings({
    /// 线条宽度
    @Default(2.0) double strokeWidth,

    /// 线条颜色
    @ColorSerializer() @Default(Colors.red) Color strokeColor,

    /// 填充颜色
    @NullableColorSerializer() Color? fillColor,

    /// 圆角半径 (用于矩形)
    @Default(0.0) double cornerRadius,

    /// 文本大小
    @Default(14.0) double fontSize,

    /// 文本字体
    @Default('Roboto') String fontFamily,

    /// 文本颜色
    @ColorSerializer() @Default(Colors.black) Color textColor,

    /// 文本对齐方式
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(TextAlign.left)
    TextAlign textAlign,
  }) = _ToolSettings;

  /// 从JSON创建
  factory ToolSettings.fromJson(Map<String, dynamic> json) =>
      _$ToolSettingsFromJson(json);

  /// 复制并更新工具设置
  const ToolSettings._();

  /// 创建矩形工具默认设置
  factory ToolSettings.rectangle() => const ToolSettings(
        strokeWidth: 2.0,
        strokeColor: Colors.red,
        fillColor: Colors.transparent,
      );

  /// 创建箭头工具默认设置
  factory ToolSettings.arrow() => const ToolSettings(
        strokeWidth: 2.0,
        strokeColor: Colors.red,
      );

  /// 创建自由绘图工具默认设置
  factory ToolSettings.freedraw() => const ToolSettings(
        strokeWidth: 2.0,
        strokeColor: Colors.blue,
      );

  /// 创建文本工具默认设置
  factory ToolSettings.text() => const ToolSettings(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        textColor: Colors.black,
        textAlign: TextAlign.left,
      );
}
