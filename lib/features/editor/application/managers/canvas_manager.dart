import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/core_providers.dart';
import '../providers/canvas_providers.dart';
import '../states/canvas_transform_state.dart';

/// 画布管理器类
/// 提供高级画布管理功能，统一多个Provider间的协调
class CanvasManager {
  final Ref _ref;
  final Logger _logger = Logger();

  CanvasManager(this._ref);

  /// 计算内容适合窗口的缩放因子
  /// 确保内容完全可见，不超出可用区域
  double calculateContentFitScale(Size contentSize, Size availableArea) {
    if (contentSize.isEmpty || availableArea.isEmpty) {
      return 1.0;
    }

    final widthRatio = availableArea.width / contentSize.width;
    final heightRatio = availableArea.height / contentSize.height;

    // 取较小的比例确保内容完全可见
    final fitScale = math.min(widthRatio, heightRatio);

    _logger.d('计算内容适应缩放: 内容=$contentSize, 区域=$availableArea, 缩放=$fitScale');

    return fitScale;
  }

  /// 调整画布以适应绘制物对象边界
  /// 当标注或绘图对象超出当前边界时自动扩展画布
  void adjustCanvasForDrawableBounds(Rect bounds) {
    final currentSize = _ref.read(canvasSizeProvider);
    final padding = _ref.read(canvasPaddingProvider);

    // 计算需要的最小尺寸
    final requiredWidth = bounds.right + padding.right;
    final requiredHeight = bounds.bottom + padding.bottom;

    // 如果需要扩展
    if (requiredWidth > currentSize.width ||
        requiredHeight > currentSize.height) {
      final newWidth = math.max(currentSize.width, requiredWidth);
      final newHeight = math.max(currentSize.height, requiredHeight);
      final newSize = Size(newWidth, newHeight);

      _logger.d('扩展画布尺寸: $currentSize -> $newSize, 适应边界: $bounds');

      // 更新编辑器状态中的原始图像尺寸
      _ref.read(editorStateProvider.notifier).updateOriginalImageSize(newSize);

      // 重新计算布局
      _ref
          .read(layoutProvider.notifier)
          .recalculateLayoutForNewContent(newSize, padding);
    }
  }

  /// 居中显示内容
  /// 调整变换状态使内容居中显示在可见区域
  void centerContent(Size contentSize, Size viewportSize) {
    if (contentSize.isEmpty || viewportSize.isEmpty) {
      return;
    }

    // 计算居中所需的偏移
    final offsetX = (viewportSize.width - contentSize.width) / 2;
    final offsetY = (viewportSize.height - contentSize.height) / 2;

    // 更新变换状态
    _ref
        .read(canvasTransformProvider.notifier)
        .updateTranslation(Offset(offsetX, offsetY));

    _logger
        .d('居中内容: 内容=$contentSize, 视口=$viewportSize, 偏移=($offsetX, $offsetY)');
  }

  /// 重置所有画布相关状态
  /// 将缩放、偏移等重置为初始值
  void resetCanvas() {
    _ref.read(canvasTransformProvider.notifier).resetTransform();
    _ref.read(drawableBoundsProvider.notifier).state = null;
  }

  /// 加载新图像并设置适当的缩放和布局
  /// 统一处理新图像加载时的画布设置
  double loadImageWithOptimalScaling(
      Uint8List imageData, Size imageSize, Size availableArea) {
    _logger.d(
        '加载图像，数据长度: ${imageData.length}, 图像尺寸: $imageSize, 可用区域: $availableArea');

    // 更新编辑器状态
    _ref
        .read(editorStateProvider.notifier)
        .loadScreenshot(imageData, imageSize);

    // 获取当前内边距
    final padding = _ref.read(canvasPaddingProvider);
    _logger.d('当前内边距: $padding');

    // 计算总内容尺寸（图像+内边距）
    final totalSize = Size(imageSize.width + padding.left + padding.right,
        imageSize.height + padding.top + padding.bottom);
    _logger.d('总内容尺寸: $totalSize');

    // 计算适合缩放
    final fitScale = calculateContentFitScale(totalSize, availableArea);
    _logger.d('计算得到的适合缩放比例: $fitScale');

    // 设置变换状态
    _ref.read(canvasTransformProvider.notifier).setZoomLevel(fitScale);

    // 更新总尺寸状态
    _ref
        .read(layoutProvider.notifier)
        .recalculateLayoutForNewContent(imageSize, padding);

    // 验证图像数据是否保存在editorState中
    final updatedImageData = _ref.read(editorStateProvider).currentImageData;
    if (updatedImageData != null) {
      _logger.d('验证: editorState中的图像数据存在，长度: ${updatedImageData.length}');
    } else {
      _logger.e('验证失败: editorState中的图像数据为null');
    }

    return fitScale;
  }

  /// 计算适合当前内容的缩放和位置
  /// 根据当前图像和可用空间计算最佳呈现方式
  void fitContentToViewport(Size availableArea) {
    _logger.d('调整内容适应视口: 可用区域=$availableArea');

    // 获取当前内容尺寸
    final canvasSize = _ref.read(canvasTotalSizeProvider);
    _logger.d('当前画布总尺寸: $canvasSize');

    // 计算适合缩放
    final fitScale = calculateContentFitScale(canvasSize, availableArea);
    _logger.d('适合当前内容的缩放比例: $fitScale');

    // 更新缩放状态
    _ref.read(canvasTransformProvider.notifier).setZoomLevel(fitScale);

    // 居中显示内容
    centerContent(
        Size(canvasSize.width * fitScale, canvasSize.height * fitScale),
        availableArea);

    // 验证图像数据
    _validateImageData();
  }

  /// 诊断函数：验证图像数据流向各部分的状态
  void _validateImageData() {
    _logger.d('======开始诊断图像数据======');

    // 检查editorState中的图像数据
    final editorState = _ref.read(editorStateProvider);
    if (editorState.currentImageData != null) {
      _logger
          .d('EditorState: 图像数据存在，长度=${editorState.currentImageData.length}');
    } else {
      _logger.e('EditorState: 图像数据为空');
    }

    // 检查各个壁纸提供者的状态
    try {
      final wpImage = _ref.read(wallpaperImageProvider);
      if (wpImage != null) {
        _logger.d('WallpaperProvider: 图像数据存在，长度=${wpImage.length}');
      } else {
        _logger.e('WallpaperProvider: 图像数据为空');
      }
    } catch (e) {
      _logger.e('读取WallpaperProvider出错', error: e);
    }

    _logger.d('======诊断完成======');
  }
}

/// 画布管理器提供者
final canvasManagerProvider = Provider<CanvasManager>((ref) {
  return CanvasManager(ref);
});
