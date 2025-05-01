import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifiers/annotation_notifier.dart';
import 'notifiers/canvas_transform_notifier.dart';
import 'notifiers/editor_state_notifier.dart';
import 'notifiers/layout_notifier.dart';
import 'states/annotation_state.dart';
import 'states/canvas_transform_state.dart';
import 'states/editor_state.dart';
import 'states/layout_state.dart';

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

/// 滚动条显示Provider
final showScrollbarsProvider = Provider<bool>((ref) {
  // 获取所需的状态
  final canvasTransform = ref.watch(canvasTransformProvider);
  final originalImageSize =
      ref.watch(editorStateProvider.select((s) => s.originalImageSize));
  final wallpaperPadding =
      ref.watch(editorStateProvider.select((s) => s.wallpaperPadding));
  final currentCanvasViewSize =
      ref.watch(layoutProvider.select((s) => s.currentCanvasViewSize));

  // 如果没有图像，不显示滚动条
  if (originalImageSize == null) return false;

  // 计算缩放后的内容总尺寸
  final double contentWidth =
      (originalImageSize.width + wallpaperPadding.horizontal) *
          canvasTransform.scaleFactor;
  final double contentHeight =
      (originalImageSize.height + wallpaperPadding.vertical) *
          canvasTransform.scaleFactor;

  // 如果内容尺寸超过画布尺寸或存在画布偏移，显示滚动条
  final bool contentTooWide = contentWidth > currentCanvasViewSize.width;
  final bool contentTooTall = contentHeight > currentCanvasViewSize.height;
  final bool hasPanning = canvasTransform.canvasOffset != Offset.zero;

  return contentTooWide || contentTooTall || hasPanning;
});

/// 扩展EditorStateNotifier，添加跨Provider方法
extension EditorStateNotifierExtension on EditorStateNotifier {
  /// 加载截图并计算布局
  double loadScreenshotWithLayout(dynamic data, Size size) {
    // 更新自身状态
    state = state.copyWith(
      currentImageData: data,
      originalImageSize: size,
      isLoading: false,
    );

    // 调用LayoutNotifier计算初始布局
    final initialScaleFactor = ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(size, state.wallpaperPadding);

    // 设置初始缩放
    ref
        .read(canvasTransformProvider.notifier)
        .setInitialScale(initialScaleFactor);

    return initialScaleFactor;
  }

  /// 更新背景边距并重新计算布局
  void updateWallpaperPaddingWithLayout(EdgeInsets padding) {
    // 更新自身状态
    state = state.copyWith(wallpaperPadding: padding);

    // 如果没有图像尺寸，不重新计算布局
    final currentImageSize = state.originalImageSize;
    if (currentImageSize == null) return;

    // 调用LayoutNotifier重新计算布局，可能会调整缩放
    double newScale = ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(currentImageSize, padding);

    // 如果需要调整缩放（小于1.0表示内容需要缩小以适应窗口）
    if (newScale < 1.0) {
      ref.read(canvasTransformProvider.notifier).setInitialScale(newScale);
    }
  }

  /// 重置所有状态
  void resetAllState() {
    // 重置自身状态
    state = EditorState.initial();

    // 重置其他状态
    ref.read(layoutProvider.notifier).resetLayout();
    ref.read(canvasTransformProvider.notifier).resetTransform();
    ref.read(annotationProvider.notifier).clearAnnotations();
  }

  /// 裁剪图像并重新计算布局
  void cropImageWithLayout(Rect rect) {
    final currentImageSize = state.originalImageSize;
    if (currentImageSize == null) return;

    final Size newSize = Size(rect.width, rect.height);

    // 更新自身状态
    state = state.copyWith(
      originalImageSize: newSize,
      // 实际裁剪操作会修改图像数据，这里简化处理
    );

    // 重新计算布局
    final newScale = ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(newSize, state.wallpaperPadding);

    // 设置缩放
    ref.read(canvasTransformProvider.notifier).setInitialScale(newScale);
  }
}

/// 扩展LayoutNotifier，添加跨Provider方法
extension LayoutNotifierExtension on LayoutNotifier {
  /// 根据当前内容重新计算布局
  void recalculateLayoutBasedOnCurrentContent() {
    final editorState = ref.read(editorStateProvider);
    if (editorState.originalImageSize == null) return;

    final newScale = recalculateLayoutForNewContent(
      editorState.originalImageSize!,
      editorState.wallpaperPadding,
    );

    // 如果需要调整缩放
    if (newScale < 1.0) {
      ref.read(canvasTransformProvider.notifier).setInitialScale(newScale);
    }
  }
}

/// 扩展AnnotationNotifier，添加跨Provider方法
extension AnnotationNotifierExtension on AnnotationNotifier {
  /// 计算所有标注的边界
  Rect calculateAnnotationsBounds(List<EditorObject> annotations) {
    if (annotations.isEmpty) {
      return Rect.zero;
    }

    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;

    for (final annotation in annotations) {
      final Rect bounds = annotation.bounds;

      if (bounds.left < left) left = bounds.left;
      if (bounds.top < top) top = bounds.top;
      if (bounds.right > right) right = bounds.right;
      if (bounds.bottom > bottom) bottom = bounds.bottom;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 检查并扩展Wallpaper边距
  void checkAndExpandWallpaper(List<EditorObject> annotations) {
    if (annotations.isEmpty) return;

    final editorState = ref.read(editorStateProvider);
    if (editorState.originalImageSize == null) return;

    // 计算所有标注的边界
    final Rect annotationBounds = calculateAnnotationsBounds(annotations);

    // 计算原始图像的边界
    final Rect imageBounds = Rect.fromLTWH(
      0,
      0,
      editorState.originalImageSize!.width,
      editorState.originalImageSize!.height,
    );

    // 当前的边距
    final currentPadding = editorState.wallpaperPadding;

    // 计算所需的边距
    double leftPadding = currentPadding.left;
    double topPadding = currentPadding.top;
    double rightPadding = currentPadding.right;
    double bottomPadding = currentPadding.bottom;

    // 如果标注超出了图像边界，增加相应的边距
    if (annotationBounds.left < 0) {
      leftPadding = math.max(leftPadding, -annotationBounds.left + 10);
    }

    if (annotationBounds.top < 0) {
      topPadding = math.max(topPadding, -annotationBounds.top + 10);
    }

    if (annotationBounds.right > imageBounds.right) {
      rightPadding = math.max(
          rightPadding, annotationBounds.right - imageBounds.right + 10);
    }

    if (annotationBounds.bottom > imageBounds.bottom) {
      bottomPadding = math.max(
          bottomPadding, annotationBounds.bottom - imageBounds.bottom + 10);
    }

    // 检查是否需要更新边距
    if (leftPadding != currentPadding.left ||
        topPadding != currentPadding.top ||
        rightPadding != currentPadding.right ||
        bottomPadding != currentPadding.bottom) {
      // 创建新的边距
      final newPadding = EdgeInsets.fromLTRB(
          leftPadding, topPadding, rightPadding, bottomPadding);

      // 更新边距，这会触发布局重新计算
      ref
          .read(editorStateProvider.notifier)
          .updateWallpaperPaddingWithLayout(newPadding);
    }
  }
}
