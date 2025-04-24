import 'package:flutter/material.dart';

/// 工具类型枚举
enum ToolType {
  selection, // 选择
  rectangle, // 矩形截图
  freeform, // 自由形状截图
  window, // 窗口截图
  gifRecording, // GIF录制
  text, // 文本标注
  dimension, // 尺寸标注
  shape, // 形状标注
  magnifier, // 放大镜
  mask, // 灰度遮罩
  hiRes, // 高分辨率截图
}

/// 工具状态管理
class ToolsProvider extends ChangeNotifier {
  // 当前选中的工具
  ToolType _currentTool = ToolType.selection;

  // 获取当前工具
  ToolType get currentTool => _currentTool;

  // 是否为绘图工具
  bool get isDrawingTool => _currentTool != ToolType.selection;

  /// 选择工具
  void selectTool(ToolType tool) {
    if (_currentTool != tool) {
      _currentTool = tool;
      notifyListeners();
    }
  }

  /// 重置到选择工具
  void resetToSelectionTool() {
    selectTool(ToolType.selection);
  }

  /// 检查是否为特定工具类型
  bool isToolType(ToolType type) {
    return _currentTool == type;
  }
}
