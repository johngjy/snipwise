import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import '../states/painter_state.dart';

/// 绘图工具状态管理器
class PainterNotifier extends StateNotifier<PainterState> {
  PainterNotifier() : super(const PainterState());

  /// 设置绘制模式
  void setDrawingMode(DrawingMode mode) {
    state = state.copyWith(drawingMode: mode);
    _updatePainterController();
  }

  /// 设置线条宽度
  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
    _updatePainterController();
  }

  /// 设置线条颜色
  void setStrokeColor(Color color) {
    state = state.copyWith(strokeColor: color);
    _updatePainterController();
  }

  /// 设置填充颜色
  void setFillColor(Color color) {
    state = state.copyWith(fillColor: color);
    _updatePainterController();
  }

  /// 设置是否填充
  void setFilled(bool filled) {
    state = state.copyWith(isFilled: filled);
    _updatePainterController();
  }

  /// 切换调色板显示
  void toggleColorPicker() {
    state = state.copyWith(showColorPicker: !state.showColorPicker);
  }

  /// 添加文本到缓存
  void addTextToCache(String text) {
    state = state.copyWith(textCache: [...state.textCache, text]);
  }

  /// 从缓存中移除文本
  void removeTextFromCache(String text) {
    state = state.copyWith(
      textCache: state.textCache.where((t) => t != text).toList(),
    );
  }

  /// 清空文本缓存
  void clearTextCache() {
    state = state.copyWith(textCache: []);
  }

  /// 切换文本缓存对话框显示
  void toggleTextCacheDialog() {
    state = state.copyWith(showTextCacheDialog: !state.showTextCacheDialog);
  }

  /// 设置选中的绘图对象
  void setSelectedObject(ObjectDrawable? object) {
    state = state.copyWith(selectedObject: object);
  }

  /// 设置绘图控制器
  void setController(PainterController controller) {
    state = state.copyWith(controller: controller);
    _updatePainterController();
  }

  /// 更新绘图控制器设置
  void _updatePainterController() {
    final controller = state.controller;
    if (controller == null) return;

    final currentSettings = controller.value.settings;
    final shapeSettings = currentSettings.shape;
    final freeStyleSettings = currentSettings.freeStyle;

    FreeStyleSettings newFreeStyleSettings;
    ShapeSettings newShapeSettings;

    switch (state.drawingMode) {
      case DrawingMode.none:
      case DrawingMode.selection:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.none,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: null,
        );
        break;
      case DrawingMode.pen:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.draw,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: null,
        );
        break;
      case DrawingMode.line:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.none,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: LineFactory(),
        );
        break;
      case DrawingMode.rectangle:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.none,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: RectangleFactory(),
        );
        break;
      case DrawingMode.oval:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.none,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: OvalFactory(),
        );
        break;
      case DrawingMode.arrow:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.none,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: ArrowFactory(),
        );
        break;
      case DrawingMode.text:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.none,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: null,
        );
        break;
      case DrawingMode.eraser:
        newFreeStyleSettings = freeStyleSettings.copyWith(
          mode: FreeStyleMode.erase,
        );
        newShapeSettings = shapeSettings.copyWith(
          factory: null,
        );
        break;
    }

    controller.value = controller.value.copyWith(
      settings: currentSettings.copyWith(
        freeStyle: newFreeStyleSettings,
        shape: newShapeSettings,
      ),
    );

    controller.notifyListeners();
  }
}
