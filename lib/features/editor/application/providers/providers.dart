import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/canvas_transform_state.dart';
import '../states/tool_state.dart';
import 'editor_providers.dart';

/// 是否显示滚动条
final showScrollbarsProvider = Provider<bool>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  final layoutState = ref.watch(layoutProvider);

  return transformState.scaleFactor > CanvasTransformState.minZoom ||
      layoutState.editorWindowSize.width <
          layoutState.currentCanvasViewSize.width ||
      layoutState.editorWindowSize.height <
          layoutState.currentCanvasViewSize.height;
});

/// 是否显示标尺
final showRulersProvider = Provider<bool>((ref) {
  final toolState = ref.watch(toolProvider);
  return toolState.currentTool == EditorTool.magnifier;
});
