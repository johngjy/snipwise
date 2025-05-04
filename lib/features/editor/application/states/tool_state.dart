import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 编辑工具枚举，统一工具类型定义
enum EditorTool {
  select, // 选择工具
  rectangle, // 矩形
  ellipse, // 椭圆
  arrow, // 箭头
  line, // 直线
  text, // 文本
  blur, // 模糊
  highlight, // 高亮
  freehand, // 手绘 (Renamed from freestyle for clarity)
  erase, // Add Erase tool
  crop, // 裁剪
  magnifier, // 放大镜
  dimension, // 尺寸标注
  none // 无工具
}

/// 修饰键状态
class ModifierKeys extends Equatable {
  final bool isShiftPressed;
  final bool isCtrlPressed;
  final bool isAltPressed;

  const ModifierKeys({
    this.isShiftPressed = false,
    this.isCtrlPressed = false,
    this.isAltPressed = false,
  });

  /// 创建初始状态
  factory ModifierKeys.initial() => const ModifierKeys();

  /// 使用copyWith创建新实例
  ModifierKeys copyWith({
    bool? isShiftPressed,
    bool? isCtrlPressed,
    bool? isAltPressed,
  }) {
    return ModifierKeys(
      isShiftPressed: isShiftPressed ?? this.isShiftPressed,
      isCtrlPressed: isCtrlPressed ?? this.isCtrlPressed,
      isAltPressed: isAltPressed ?? this.isAltPressed,
    );
  }

  @override
  List<Object?> get props => [isShiftPressed, isCtrlPressed, isAltPressed];
}

/// 工具设置基类
abstract class ToolSettings extends Equatable {
  final String id;

  const ToolSettings({required this.id});

  @override
  List<Object?> get props => [id];
}

/// 形状工具设置
class ShapeToolSettings extends ToolSettings {
  final Color strokeColor;
  final double strokeWidth;
  final bool isFilled;
  final Color fillColor;

  const ShapeToolSettings({
    required super.id,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.isFilled = false,
    this.fillColor = Colors.transparent,
  });

  /// 使用copyWith创建新实例
  ShapeToolSettings copyWith({
    Color? strokeColor,
    double? strokeWidth,
    bool? isFilled,
    Color? fillColor,
  }) {
    return ShapeToolSettings(
      id: id,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isFilled: isFilled ?? this.isFilled,
      fillColor: fillColor ?? this.fillColor,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        strokeColor,
        strokeWidth,
        isFilled,
        fillColor,
      ];
}

/// 文本工具设置
class TextToolSettings extends ToolSettings {
  final TextStyle textStyle;
  final Color backgroundColor;
  final bool hasBackground;

  const TextToolSettings({
    required super.id,
    this.textStyle = const TextStyle(
      fontSize: 16,
      color: Colors.black,
    ),
    this.backgroundColor = Colors.transparent,
    this.hasBackground = false,
  });

  /// 使用copyWith创建新实例
  TextToolSettings copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    bool? hasBackground,
  }) {
    return TextToolSettings(
      id: id,
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hasBackground: hasBackground ?? this.hasBackground,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        textStyle,
        backgroundColor,
        hasBackground,
      ];
}

/// 模糊工具设置
class BlurToolSettings extends ToolSettings {
  final double blurRadius;
  final double brushSize;

  const BlurToolSettings({
    required super.id,
    this.blurRadius = 5.0,
    this.brushSize = 20.0,
  });

  /// 使用copyWith创建新实例
  BlurToolSettings copyWith({
    double? blurRadius,
    double? brushSize,
  }) {
    return BlurToolSettings(
      id: id,
      blurRadius: blurRadius ?? this.blurRadius,
      brushSize: brushSize ?? this.brushSize,
    );
  }

  @override
  List<Object?> get props => [...super.props, blurRadius, brushSize];
}

/// 工具状态类
class ToolState extends Equatable {
  /// 当前工具
  final EditorTool currentTool;

  /// 修饰键状态
  final ModifierKeys modifierKeys;

  /// 工具设置映射表
  final Map<String, ToolSettings> toolSettings;

  const ToolState({
    this.currentTool = EditorTool.select,
    this.modifierKeys = const ModifierKeys(),
    this.toolSettings = const {},
  });

  /// 创建初始状态
  factory ToolState.initial() {
    // 创建初始工具设置
    Map<String, ToolSettings> initialSettings = {
      'shape': const ShapeToolSettings(id: 'shape'),
      'text': const TextToolSettings(id: 'text'),
      'blur': const BlurToolSettings(id: 'blur'),
    };

    return ToolState(toolSettings: initialSettings);
  }

  /// 使用copyWith创建新实例
  ToolState copyWith({
    EditorTool? currentTool,
    ModifierKeys? modifierKeys,
    Map<String, ToolSettings>? toolSettings,
  }) {
    return ToolState(
      currentTool: currentTool ?? this.currentTool,
      modifierKeys: modifierKeys ?? this.modifierKeys,
      toolSettings: toolSettings ?? this.toolSettings,
    );
  }

  /// 更新特定工具的设置
  ToolState updateToolSetting(ToolSettings newSetting) {
    final updatedSettings = Map<String, ToolSettings>.from(toolSettings);
    updatedSettings[newSetting.id] = newSetting;

    return copyWith(toolSettings: updatedSettings);
  }

  /// 获取形状工具设置
  ShapeToolSettings get shapeSettings =>
      toolSettings['shape'] as ShapeToolSettings? ??
      ShapeToolSettings(id: 'shape');

  /// 获取文本工具设置
  TextToolSettings get textSettings =>
      toolSettings['text'] as TextToolSettings? ?? TextToolSettings(id: 'text');

  /// 获取模糊工具设置
  BlurToolSettings get blurSettings =>
      toolSettings['blur'] as BlurToolSettings? ?? BlurToolSettings(id: 'blur');

  /// 获取当前工具设置
  ToolSettings? getCurrentToolSettings() {
    switch (currentTool) {
      case EditorTool.rectangle:
      case EditorTool.ellipse:
      case EditorTool.arrow:
      case EditorTool.line:
      case EditorTool.freehand:
        return shapeSettings;
      case EditorTool.text:
        return textSettings;
      case EditorTool.blur:
      case EditorTool.highlight:
        return blurSettings;
      default:
        return null;
    }
  }

  /// 当前工具是否为绘图工具
  bool get isDrawingTool =>
      currentTool != EditorTool.select && currentTool != EditorTool.none;

  @override
  List<Object?> get props => [currentTool, modifierKeys, toolSettings];
}
