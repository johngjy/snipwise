import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/editor_providers.dart';
import '../states/editor_state.dart';

/// 编辑器状态管理Notifier
class EditorStateNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => EditorState.initial();

  /// 加载截图数据 (仅更新状态)
  void loadScreenshot(dynamic data, Size size) {
    state = state.copyWith(
      currentImageData: data,
      originalImageSize: size,
      isLoading: false,
    );
  }

  /// 裁剪图像 (仅更新状态)
  void cropImage(Rect rect) {
    if (state.originalImageSize == null) return;
    final Size newSize = Size(rect.width, rect.height);
    state = state.copyWith(
      originalImageSize: newSize,
      // 实际裁剪数据处理不在此
    );
  }

  /// 更新背景颜色
  void updateWallpaperColor(Color color) {
    state = state.copyWith(wallpaperColor: color);
  }

  /// 更新背景边距 (仅更新状态)
  void updateWallpaperPadding(EdgeInsets padding) {
    state = state.copyWith(wallpaperPadding: padding);
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// 重置编辑器状态 (仅重置自身状态)
  void resetEditorState() {
    state = EditorState.initial();
  }

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
    if (state.originalImageSize == null) return;

    // 调用LayoutNotifier重新计算布局，可能会调整缩放
    double newScale = ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(state.originalImageSize!, padding);

    // 如果需要调整缩放（小于1.0表示内容需要缩小以适应窗口）
    if (newScale < 1.0) {
      ref.read(canvasTransformProvider.notifier).setInitialScale(newScale);
    }
  }

  /// 裁剪图像并重新计算布局
  void cropImageWithLayout(Rect rect) {
    if (state.originalImageSize == null) return;
    final Size newSize = Size(rect.width, rect.height);

    // 更新自身状态
    state = state.copyWith(
      originalImageSize: newSize,
      // 实际裁剪数据处理不在此
    );

    // 重新计算布局
    final newScale = ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(newSize, state.wallpaperPadding);

    // 设置缩放
    ref.read(canvasTransformProvider.notifier).setInitialScale(newScale);
  }

  /// 重置所有相关状态
  void resetAllState() {
    // 重置自身状态
    state = EditorState.initial();

    // 重置其他状态
    ref.read(layoutProvider.notifier).resetLayout();
    ref.read(canvasTransformProvider.notifier).resetTransform();
    ref.read(annotationProvider.notifier).clearAnnotations();
    ref.read(toolProvider.notifier).resetToSelectionTool();
  }
}
