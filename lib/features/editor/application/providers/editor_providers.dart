import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/annotation_notifier.dart';
import '../notifiers/canvas_transform_notifier.dart';
import '../notifiers/editor_state_notifier.dart';
import '../notifiers/layout_notifier.dart';
import '../notifiers/tool_notifier.dart';
import '../states/annotation_state.dart';
import '../states/canvas_transform_state.dart';
import '../states/editor_state.dart';
import '../states/layout_state.dart';
import '../states/tool_state.dart';

/// 布局管理Provider
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(() {
  return LayoutNotifier();
});

/// 编辑器状态Provider
final editorStateProvider =
    NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});

/// 画布变换Provider
final canvasTransformProvider =
    NotifierProvider<CanvasTransformNotifier, CanvasTransformState>(() {
  return CanvasTransformNotifier();
});

/// 标注管理Provider
final annotationProvider =
    NotifierProvider<AnnotationNotifier, AnnotationState>(() {
  return AnnotationNotifier();
});

/// 工具管理Provider
final toolProvider = NotifierProvider<ToolNotifier, ToolState>(() {
  return ToolNotifier();
});

/// 滚动条显示Provider
final showScrollbarsProvider = Provider<bool>((ref) {
  // 直接 watch NotifierProvider 来获取状态
  final layoutState = ref.watch(layoutProvider);
  final transformState = ref.watch(canvasTransformProvider);
  final editorState = ref.watch(editorStateProvider);

  // 如果没有图像数据，不显示滚动条
  if (editorState.currentImageData == null ||
      editorState.originalImageSize == null) {
    return false;
  }

  final imageSize = editorState.originalImageSize!;
  final canvasSize = layoutState.currentCanvasViewSize;
  final scaleFactor = transformState.scaleFactor;

  // 计算缩放后的内容尺寸
  final scaledWidth = imageSize.width * scaleFactor;
  final scaledHeight = imageSize.height * scaleFactor;

  // 考虑背景边距
  final paddingHorizontal =
      editorState.wallpaperPadding.left + editorState.wallpaperPadding.right;
  final paddingVertical =
      editorState.wallpaperPadding.top + editorState.wallpaperPadding.bottom;

  final totalWidth = scaledWidth + paddingHorizontal;
  final totalHeight = scaledHeight + paddingVertical;

  // 如果内容宽度大于画布宽度，或者内容高度大于画布高度，则显示滚动条
  final needsScrollbars = totalWidth > canvasSize.width ||
      totalHeight > canvasSize.height ||
      transformState.canvasOffset != Offset.zero;

  return needsScrollbars;
});
