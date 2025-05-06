import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/editor_providers.dart';
import '../states/editor_state.dart';
import '../notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider;
import '../helpers/canvas_transform_connector.dart';

/// 编辑器状态管理Notifier
class EditorStateNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => EditorState.initial();

  /// 加载截图数据 (仅更新状态)
  void loadScreenshot(dynamic data, Size size) {
    final logger = Logger();
    logger.d(
        'EditorStateNotifier.loadScreenshot 被调用: 图像大小=${size.width}x${size.height}, 数据=${data != null ? "非空" : "空"}');
    if (data != null) {
      try {
        logger.d('接收到图像数据长度: ${data.length}');
      } catch (e) {
        logger.w('无法获取图像数据长度: $e');
      }
    }

    state = state.copyWith(
      currentImageData: data,
      originalImageSize: size,
      isLoading: false,
    );

    logger.d('EditorStateNotifier.loadScreenshot 完成: 状态已更新');
  }

  /// 设置UI图像
  void setUiImage(ui.Image image) {
    state = state.copyWith(imageAsUiImage: image);
  }

  /// 设置捕获比例
  void setCapturedScale(double scale) {
    state = state.copyWith(capturedScale: scale);
  }

  /// 设置缩放菜单可见性
  void setZoomMenuVisible(bool visible) {
    state = state.copyWith(isZoomMenuVisible: visible);
  }

  /// 设置新建按钮菜单可见性
  void setNewButtonMenuVisible(bool visible) {
    state = state.copyWith(isNewButtonMenuVisible: visible);
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

  /// 用于跟踪上一次的图像数据哈希
  int? _lastImageDataHash;

  /// 设置当前图像数据
  void setCurrentImageData(dynamic data) {
    final logger = Logger();

    if (data == null) {
      // 只在之前有数据而现在变为null时记录日志
      if (_lastImageDataHash != null) {
        logger.w('传入的图像数据为空，不更新状态');
        _lastImageDataHash = null;
      }
      return;
    }

    // 计算当前数据的哈希值
    final currentHash = data.hashCode;

    // 仅当图像数据发生变化时才更新和记录日志
    if (_lastImageDataHash != currentHash) {
      _lastImageDataHash = currentHash;

      logger
          .d('EditorStateNotifier.setCurrentImageData: 数据已更新，哈希值=$currentHash');

      try {
        logger.d('接收到图像数据长度: ${data.length}');
      } catch (e) {
        logger.w('无法获取图像数据长度: $e');
      }

      state = state.copyWith(currentImageData: data);
      logger.d('EditorStateNotifier.setCurrentImageData 完成: 状态已更新');
    }
  }

  /// 重置编辑器状态 (仅重置自身状态)
  void resetEditorState() {
    state = EditorState.initial();
  }

  /// 加载完整的截图数据（包括图像数据、UI图像和捕获比例）
  void loadFullScreenshotData(
      dynamic data, ui.Image uiImage, Size size, double scale) {
    state = state.copyWith(
      currentImageData: data,
      imageAsUiImage: uiImage,
      originalImageSize: size,
      capturedScale: scale,
      isLoading: false,
    );
  }

  /// 加载截图并计算布局
  double loadScreenshotWithLayout(dynamic data, Size size,
      {double capturedScale = 1.0}) {
    // 更新自身状态
    state = state.copyWith(
      currentImageData: data,
      originalImageSize: size,
      capturedScale: capturedScale,
      isLoading: false,
    );

    // 调用LayoutNotifier计算初始布局
    final initialScaleFactor = ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(size, state.wallpaperPadding);

    // 设置初始缩放
    ref.read(canvasTransformProvider.notifier).setZoomLevel(initialScaleFactor);

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
      ref.read(canvasTransformProvider.notifier).setZoomLevel(newScale);
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
    ref.read(canvasTransformProvider.notifier).setZoomLevel(newScale);
  }

  /// 更新原始图像尺寸
  /// 用于由 WallpaperCanvasContainer 调用，以支持画布自动扩展
  void updateOriginalImageSize(Size newSize) {
    state = state.copyWith(originalImageSize: newSize);
  }
}
