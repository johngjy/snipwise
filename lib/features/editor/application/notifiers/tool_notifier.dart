import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/tool_state.dart';

/// 工具状态管理Notifier
class ToolNotifier extends Notifier<ToolState> {
  @override
  ToolState build() => ToolState.initial();

  /// 设置当前工具
  void setCurrentTool(EditorTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// 重置到选择工具
  void resetToSelectionTool() {
    setCurrentTool(EditorTool.select);
  }

  /// 更新修饰键状态
  void updateModifierKeys({
    bool? isShiftPressed,
    bool? isCtrlPressed,
    bool? isAltPressed,
  }) {
    final updatedModifierKeys = state.modifierKeys.copyWith(
      isShiftPressed: isShiftPressed,
      isCtrlPressed: isCtrlPressed,
      isAltPressed: isAltPressed,
    );

    state = state.copyWith(modifierKeys: updatedModifierKeys);
  }

  /// 更新形状工具设置
  void updateShapeToolSettings({
    Color? strokeColor,
    double? strokeWidth,
    bool? isFilled,
    Color? fillColor,
  }) {
    final updatedSettings = state.shapeSettings.copyWith(
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      isFilled: isFilled,
      fillColor: fillColor,
    );

    state = state.updateToolSetting(updatedSettings);
  }

  /// 更新文本工具设置
  void updateTextToolSettings({
    TextStyle? textStyle,
    Color? backgroundColor,
    bool? hasBackground,
  }) {
    final updatedSettings = state.textSettings.copyWith(
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      hasBackground: hasBackground,
    );

    state = state.updateToolSetting(updatedSettings);
  }

  /// 更新模糊工具设置
  void updateBlurToolSettings({
    double? blurRadius,
    double? brushSize,
  }) {
    final updatedSettings = state.blurSettings.copyWith(
      blurRadius: blurRadius,
      brushSize: brushSize,
    );

    state = state.updateToolSetting(updatedSettings);
  }

  /// 检查是否为特定工具类型
  bool isToolType(EditorTool type) {
    return state.currentTool == type;
  }

  /// 恢复所有工具设置为默认值
  void resetAllToolSettings() {
    state = ToolState.initial();
  }
}
