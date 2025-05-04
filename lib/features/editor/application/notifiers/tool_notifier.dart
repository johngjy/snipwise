import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:logger/logger.dart';

import '../providers/painter_providers.dart';
import '../states/tool_state.dart';

/// 工具状态管理Notifier
class ToolNotifier extends Notifier<ToolState> {
  final Logger _logger = Logger();

  @override
  ToolState build() => ToolState.initial();

  /// 设置当前工具
  void setCurrentTool(EditorTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// 处理工具选择并应用到PainterController
  /// @param tool 工具字符串标识
  void handleToolSelect(String tool) {
    final controller = ref.read(painterControllerProvider);
    final currentSettings = controller.value.settings;
    EditorTool selectedTool = EditorTool.select; // 默认选择工具

    FreeStyleSettings freeStyleSettings = currentSettings.freeStyle;
    ShapeSettings shapeSettings = currentSettings.shape;
    TextSettings textSettings = currentSettings.text;

    // 获取当前的形状设置（用于颜色和宽度）
    final currentShapeSettings = state.shapeSettings;
    final strokeColor = currentShapeSettings.strokeColor;
    final strokeWidth = currentShapeSettings.strokeWidth;
    final isFilled = currentShapeSettings.isFilled;
    final fillColor = currentShapeSettings.fillColor;

    controller.textFocusNode?.unfocus();
    freeStyleSettings = freeStyleSettings.copyWith(mode: FreeStyleMode.none);

    // 首先重置形状工厂
    shapeSettings = shapeSettings.copyWith(factory: null);

    switch (tool) {
      case 'select':
        selectedTool = EditorTool.select;
        _logger.d('Tool selected: Select');
        break;
      case 'rectangle':
        selectedTool = EditorTool.rectangle;
        // 只设置工厂，其他属性在全局应用
        shapeSettings = shapeSettings.copyWith(
          factory: RectangleFactory(),
        );
        _logger.d('Tool selected: Rectangle');
        break;
      case 'ellipse':
        selectedTool = EditorTool.ellipse;
        // 只设置工厂，其他属性在全局应用
        shapeSettings = shapeSettings.copyWith(
          factory: OvalFactory(),
        );
        _logger.d('Tool selected: Ellipse');
        break;
      case 'arrow':
        selectedTool = EditorTool.arrow;
        // 只设置工厂，其他属性在全局应用
        shapeSettings = shapeSettings.copyWith(
          factory: ArrowFactory(),
        );
        _logger.d('Tool selected: Arrow');
        break;
      case 'line':
        selectedTool = EditorTool.line;
        // 只设置工厂，其他属性在全局应用
        shapeSettings = shapeSettings.copyWith(
          factory: LineFactory(),
        );
        _logger.d('Tool selected: Line');
        break;
      case 'text':
        selectedTool = EditorTool.text;
        final settings = state.textSettings;
        textSettings = textSettings.copyWith(
          textStyle: settings.textStyle,
          // Background settings might be handled differently or need specific setup
        );
        controller.textFocusNode?.requestFocus();
        _logger
            .d('Tool selected: Text with style ${settings.textStyle.fontSize}');
        break;
      case 'blur':
        selectedTool = EditorTool.blur;
        final settings = state.blurSettings; // Get current blur settings
        // Placeholder: FreeStyleMode.blur might not exist.
        freeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.draw, // Use draw as placeholder
          // Apply blur settings as far as possible
          color: Colors.black, // 模糊工具的颜色不重要
          strokeWidth: settings.brushSize, // 使用模糊工具的笔刷大小
        );
        _logger.w('Tool selected: Blur (Using Draw mode as placeholder)');
        break;
      case 'highlight':
        selectedTool = EditorTool.highlight;
        // 高亮工具使用半透明黄色
        freeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.draw, // Use draw as placeholder
          color: Colors.yellow.withAlpha((255 * 0.5).round()), // 半透明黄色
          strokeWidth: strokeWidth * 3, // 放大笔划宽度，使高亮更明显
        );
        _logger.w('Tool selected: Highlight (Using Draw mode as placeholder)');
        break;
      case 'erase':
        selectedTool = EditorTool.erase;
        freeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.erase,
          strokeWidth: strokeWidth * 2, // 稍微放大橡皮擦尺寸
        );
        _logger.d('Tool selected: Erase (Freestyle)');
        break;
      case 'freehand':
      default:
        selectedTool = EditorTool.freehand;
        freeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.draw,
          color: strokeColor, // 使用当前选择的颜色
          strokeWidth: strokeWidth, // 使用当前选择的宽度
        );
        _logger.d('Tool selected: Freehand Draw with color $strokeColor');
        break;
    }

    // 为所有形状工具应用通用的颜色和线宽设置
    if (['rectangle', 'ellipse', 'arrow', 'line'].contains(tool)) {
      // 形状工具的颜色和宽度需要通过当前设置的shapeSettings应用

      // 复制并应用形状设置
      final drawingColor = strokeColor;
      final drawingWidth = strokeWidth;

      // 更新控制器设置
      controller.value = controller.value.copyWith(
        settings: controller.value.settings.copyWith(
          freeStyle: freeStyleSettings,
          shape: shapeSettings,
          text: textSettings,
        ),
      );

      // 使用工具状态更新形状工具的颜色和宽度设置
      // 这些会在下一次使用形状工具时应用
      updateShapeToolSettings(
        strokeColor: drawingColor,
        strokeWidth: drawingWidth,
        isFilled: isFilled,
        fillColor: fillColor,
      );
    } else {
      // 对于非形状工具，只应用工具特定设置
      controller.value = controller.value.copyWith(
        settings: controller.value.settings.copyWith(
          freeStyle: freeStyleSettings,
          shape: shapeSettings,
          text: textSettings,
        ),
      );
    }

    // 最后设置当前工具状态
    setCurrentTool(selectedTool);
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
