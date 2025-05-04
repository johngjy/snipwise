import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';

import '../notifiers/canvas_transform_notifier.dart';
import 'painter_providers.dart';

/// CanvasTransformConnector 组件
/// 连接 canvas_transform_notifier 和 PainterController
///
/// 当画布变换状态改变时，自动更新 PainterController 的变换
class CanvasTransformConnector extends ConsumerWidget {
  /// 子组件
  final Widget child;

  /// 构造函数
  const CanvasTransformConnector({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听画布变换状态变化
    ref.listen<CanvasTransformState>(
      canvasTransformProvider,
      (previous, next) {
        if (previous?.zoomLevel != next.zoomLevel ||
            previous?.canvasOffset != next.canvasOffset) {
          _updatePainterController(ref, next);
        }
      },
    );

    return child;
  }

  /// 更新 PainterController 的变换
  void _updatePainterController(WidgetRef ref, CanvasTransformState state) {
    final controller = ref.read(painterControllerProvider);
    final utils = ref.read(painterProvidersUtilsProvider);

    // 设置缩放级别
    utils.setZoomLevel(controller, state.zoomLevel);

    // 设置平移量
    utils.setTranslation(controller, state.canvasOffset);
  }
}
