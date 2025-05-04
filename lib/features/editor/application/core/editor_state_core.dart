import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';

import '../states/editor_state.dart';
import '../states/canvas_transform_state.dart' as cts;
import '../states/wallpaper_settings_state.dart';
import '../states/annotation_state.dart';
import '../states/layout_state.dart';
import '../notifiers/editor_state_notifier.dart';
import '../notifiers/canvas_transform_notifier.dart';
import '../notifiers/wallpaper_settings_notifier.dart';
import '../notifiers/annotation_notifier.dart';
import '../notifiers/layout_notifier.dart';
import '../notifiers/tool_notifier.dart';
import '../providers/editor_providers.dart';
import '../providers/painter_providers.dart';

/// 编辑器核心状态管理器
/// 提供统一的状态访问和更新接口，协调所有子状态间的交互
class EditorStateCore {
  final Ref _ref;

  EditorStateCore(this._ref);

  // ====== 状态访问接口 ======

  /// 获取编辑器状态
  EditorState get editorState => _ref.read(editorStateProvider);

  /// 获取画布变换状态
  cts.CanvasTransformState get canvasTransform =>
      _ref.read(canvasTransformProvider);

  /// 获取壁纸设置状态
  WallpaperSettingsState get wallpaperSettings =>
      _ref.read(wallpaperSettingsProvider);

  /// 获取布局状态
  LayoutState get layoutState => _ref.read(layoutProvider);

  // ====== 统一的变换管理接口 ======

  /// 设置画布缩放级别，统一管理所有相关组件
  void setCanvasZoom(double zoomLevel) {
    // 更新变换状态
    _ref.read(canvasTransformProvider.notifier).setZoomLevel(zoomLevel);

    // 同步到FlutterPainter (虽然只是占位实现)
    final controller = _ref.read(painterControllerProvider);
    final utils = _ref.read(painterProvidersUtilsProvider);
    utils.setZoomLevel(controller, zoomLevel);
  }

  /// 设置画布平移偏移，统一管理所有相关组件
  void setCanvasTranslation(Offset offset) {
    // 更新变换状态
    _ref.read(canvasTransformProvider.notifier).updateTranslation(offset);

    // 同步到FlutterPainter (虽然只是占位实现)
    final controller = _ref.read(painterControllerProvider);
    final utils = _ref.read(painterProvidersUtilsProvider);
    utils.setTranslation(controller, offset);
  }

  /// 重置画布变换状态
  /// 将缩放和平移恢复到初始状态
  void resetCanvasTransform() {
    _ref.read(canvasTransformProvider.notifier).resetTransform();

    // 同步到FlutterPainter
    final controller = _ref.read(painterControllerProvider);
    final utils = _ref.read(painterProvidersUtilsProvider);
    utils.setZoomLevel(controller, 1.0);
    utils.setTranslation(controller, Offset.zero);
  }

  /// 使内容适应可用空间
  /// 计算并应用合适的缩放和居中位置
  double fitContentToAvailableSpace(Size contentSize, Size availableSize) {
    // 计算最佳缩放比例
    final widthRatio = availableSize.width / contentSize.width;
    final heightRatio = availableSize.height / contentSize.height;
    final fitScale = math.min(widthRatio, heightRatio);

    // 应用缩放
    setCanvasZoom(fitScale);

    // 计算居中偏移
    final scaledWidth = contentSize.width * fitScale;
    final scaledHeight = contentSize.height * fitScale;
    final offsetX = (availableSize.width - scaledWidth) / 2;
    final offsetY = (availableSize.height - scaledHeight) / 2;

    // 应用偏移
    setCanvasTranslation(Offset(offsetX, offsetY));

    return fitScale;
  }

  // ====== 高级操作接口 ======

  /// 加载截图并自动计算适当的缩放和布局
  /// 统一入口，替代各组件中分散的加载逻辑
  double loadScreenshot(Uint8List data, Size size,
      {double capturedScale = 1.0}) {
    // 更新编辑器状态
    _ref.read(editorStateProvider.notifier).loadScreenshot(data, size);

    // 计算初始布局
    final initialScaleFactor = _ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(size, editorState.wallpaperPadding);

    // 设置初始缩放 (使用统一接口)
    setCanvasZoom(initialScaleFactor);

    return initialScaleFactor;
  }

  /// 更新壁纸内边距并重新计算布局
  /// 统一处理内边距更新逻辑，确保所有相关状态同步更新
  void updateWallpaperPadding(double padding) {
    // 使用WallpaperSettingsNotifier更新padding
    _ref.read(wallpaperSettingsProvider.notifier).setPadding(padding);

    // 如果没有图像尺寸，不重新计算布局
    final imageSize = editorState.originalImageSize;
    if (imageSize == null) return;

    // 更新EditorState中的内边距（将来可移除）
    _ref
        .read(editorStateProvider.notifier)
        .updateWallpaperPadding(EdgeInsets.all(padding));

    // 重新计算布局
    double newScale = _ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(imageSize, EdgeInsets.all(padding));

    // 如果需要调整缩放（小于1.0表示内容需要缩小以适应窗口）
    if (newScale < 1.0) {
      setCanvasZoom(newScale);
    }
  }

  /// 为绘制对象边界扩展画布
  /// 处理当标注或绘图超出边界时的画布扩展逻辑
  void expandCanvasForDrawableBounds(Rect bounds, EdgeInsets padding) {
    // 获取当前图像尺寸
    final currentSize = editorState.originalImageSize;
    if (currentSize == null) return;

    // 计算需要的扩展大小
    double requiredWidth = bounds.right + padding.right;
    double requiredHeight = bounds.bottom + padding.bottom;

    // 如果需要扩展
    if (requiredWidth > currentSize.width ||
        requiredHeight > currentSize.height) {
      // 计算新的尺寸
      final newWidth = math.max(currentSize.width, requiredWidth);
      final newHeight = math.max(currentSize.height, requiredHeight);
      final newSize = Size(newWidth, newHeight);

      // 更新编辑器状态
      _ref.read(editorStateProvider.notifier).updateOriginalImageSize(newSize);

      // 通知布局更新
      _ref.read(layoutProvider.notifier).recalculateLayoutForNewContent(
          newSize, EdgeInsets.all(padding.left));
    }
  }

  /// 重置所有状态
  /// 一键重置所有编辑器状态
  void resetAllState() {
    // 重置编辑器状态
    _ref.read(editorStateProvider.notifier).resetEditorState();

    // 重置布局
    _ref.read(layoutProvider.notifier).resetLayout();

    // 重置变换 (使用统一接口)
    resetCanvasTransform();

    // 重置标注
    _ref.read(annotationProvider.notifier).clearAnnotations();

    // 重置工具
    _ref.read(toolProvider.notifier).resetToSelectionTool();

    // 重置壁纸设置
    _ref.read(wallpaperSettingsProvider.notifier).resetToDefaults();
  }

  /// 更新背景图像
  /// 确保FlutterPainter和编辑器状态的背景图像同步
  Future<void> updateBackgroundImage(Uint8List imageData) async {
    // 更新FlutterPainter背景
    final controller = _ref.read(painterControllerProvider);
    final utils = _ref.read(painterProvidersUtilsProvider);
    await utils.updateBackgroundImage(controller, imageData);
  }
}

/// 编辑器核心状态Provider
final editorStateCoreProvider = Provider<EditorStateCore>((ref) {
  return EditorStateCore(ref);
});
