import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../application/providers/canvas_providers.dart';
import '../../../application/providers/painter_providers.dart';

/// 连接器组件：将画布变换状态与绘图控制器连接
///
/// 该组件负责监听画布变换状态的变化，
/// 并将其自动更新到PainterController中。
class PainterCanvasConnector extends ConsumerWidget {
  /// 构造函数
  PainterCanvasConnector({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// 子组件
  final Widget child;

  // 日志记录器
  final Logger _logger = Logger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听绘图模式更改
    final drawingMode = ref.watch(currentDrawingModeProvider);

    // 监听颜色更改
    final strokeColor = ref.watch(strokeColorProvider);
    final fillColor = ref.watch(fillColorProvider);
    final isFilled = ref.watch(isFilledProvider);

    // 监听线宽更改
    final strokeWidth = ref.watch(strokeWidthProvider);

    // 每当这些值变化时，更新绘图器设置
    _updatePainterSettings(
        ref, drawingMode, strokeColor, fillColor, isFilled, strokeWidth);

    return child;
  }

  /// 更新绘图器设置
  void _updatePainterSettings(
    WidgetRef ref,
    DrawingMode drawingMode,
    Color strokeColor,
    Color fillColor,
    bool isFilled,
    double strokeWidth,
  ) {
    print('更新绘图器设置: 模式=$drawingMode, 颜色=$strokeColor, 线宽=$strokeWidth');

    final controller = ref.read(painterControllerProvider);

    try {
      // 获取当前设置
      final currentSettings = controller.value.settings;

      // 更新自由绘制设置
      final updatedFreeStyleSettings = currentSettings.freeStyle.copyWith(
        color: strokeColor,
        strokeWidth: strokeWidth,
      );

      // 更新形状设置 - 根据flutter_painter_v2 API
      final updatedShapeSettings = currentSettings.shape.copyWith(
        paint: Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke,
      );

      // 更新文本设置
      final updatedTextSettings = currentSettings.text.copyWith(
        textStyle: TextStyle(
          color: strokeColor,
          fontSize: 20,
        ),
      );

      // 应用更新后的设置
      controller.value = controller.value.copyWith(
        settings: currentSettings.copyWith(
          freeStyle: updatedFreeStyleSettings,
          shape: updatedShapeSettings,
          text: updatedTextSettings,
        ),
      );

      // 通知监听器
      controller.notifyListeners();
    } catch (e) {
      _logger.e('更新绘图器设置失败', error: e);
    }
  }
}
