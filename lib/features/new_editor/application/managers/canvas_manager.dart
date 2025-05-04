import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/state_providers.dart';
import '../providers/canvas_providers.dart';

/// 画布管理器提供者
final canvasManagerProvider = Provider<CanvasManager>((ref) {
  return CanvasManager(ref);
});

/// 画布管理器
/// 负责管理画布的尺寸、缩放和适配等功能
class CanvasManager {
  final Ref _ref;
  final Logger _logger = Logger();

  /// 构造函数
  CanvasManager(this._ref);

  /// 使内容适合视口
  /// 调整缩放和偏移使内容完全可见
  void fitContentToViewport(Size viewportSize) {
    final canvasState = _ref.read(canvasProvider);

    // 如果画布尺寸未设置，无需调整
    if (canvasState.originalImageSize == null ||
        canvasState.totalSize == null) {
      _logger.d('fitContentToViewport: 画布尺寸未设置，无需调整');
      return;
    }

    // 计算适合视口的缩放比例
    final fitScale = _ref.read(contentFitScaleProvider(viewportSize));

    _logger.d('fitContentToViewport: 适合视口的缩放比例=$fitScale, '
        '视口尺寸=${viewportSize.width}x${viewportSize.height}, '
        '内容尺寸=${canvasState.totalSize!.width}x${canvasState.totalSize!.height}');

    // 重置变换
    _ref.read(canvasProvider.notifier).setScale(fitScale);

    // 计算居中偏移
    final scaledWidth = canvasState.totalSize!.width * fitScale;
    final scaledHeight = canvasState.totalSize!.height * fitScale;

    final offsetX = (viewportSize.width - scaledWidth) / 2;
    final offsetY = (viewportSize.height - scaledHeight) / 2;

    _ref.read(canvasProvider.notifier).setOffset(Offset(offsetX, offsetY));

    _logger.d('fitContentToViewport: 设置居中偏移=($offsetX, $offsetY)');
  }

  /// 调整画布适应绘制物边界
  /// 如果绘制物超出边界，自动扩展画布
  void adjustCanvasForDrawableBounds(Rect drawableBounds) {
    final canvasState = _ref.read(canvasProvider);
    final padding = canvasState.padding;

    // 如果画布尺寸未设置，无需调整
    if (canvasState.originalImageSize == null) {
      _logger.d('adjustCanvasForDrawableBounds: 画布尺寸未设置，无需调整');
      return;
    }

    final imageWidth = canvasState.originalImageSize!.width;
    final imageHeight = canvasState.originalImageSize!.height;

    // 检查是否需要扩展画布
    bool needsExpansion = false;
    double newImageWidth = imageWidth;
    double newImageHeight = imageHeight;

    // 检查右边界
    if (drawableBounds.right > imageWidth) {
      newImageWidth = drawableBounds.right + 20; // 添加额外边距
      needsExpansion = true;
      _logger.d('adjustCanvasForDrawableBounds: 需要扩展右边界，新宽度=$newImageWidth');
    }

    // 检查底边界
    if (drawableBounds.bottom > imageHeight) {
      newImageHeight = drawableBounds.bottom + 20; // 添加额外边距
      needsExpansion = true;
      _logger.d('adjustCanvasForDrawableBounds: 需要扩展底边界，新高度=$newImageHeight');
    }

    // 如果需要扩展，更新画布尺寸
    if (needsExpansion) {
      final newSize = Size(newImageWidth, newImageHeight);
      _ref.read(canvasProvider.notifier).setImageSize(newSize);

      _logger.d(
          'adjustCanvasForDrawableBounds: 扩展画布尺寸为${newSize.width}x${newSize.height}');
    }
  }

  /// 重置画布尺寸和变换
  void resetCanvas() {
    _ref.read(canvasProvider.notifier).resetTransform();
    _logger.d('resetCanvas: 重置画布变换');
  }
}
