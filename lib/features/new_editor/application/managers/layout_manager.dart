import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/state_providers.dart';
import '../providers/canvas_providers.dart';

/// 布局管理器提供者
final layoutManagerProvider = Provider<LayoutManager>((ref) {
  return LayoutManager(ref);
});

/// 全局最小画布尺寸
final minCanvasSizeProvider = Provider<Size>((ref) {
  return const Size(900, 500);
});

/// 工具栏高度配置
class ToolbarHeights {
  final double top;
  final double bottom;
  double get total => top + bottom;

  const ToolbarHeights({
    this.top = 50,
    this.bottom = 40,
  });
}

/// 工具栏高度提供者
final toolbarHeightsProvider = Provider<ToolbarHeights>((ref) {
  return const ToolbarHeights();
});

/// 全局最小窗口基础尺寸提供者
final minWindowBaseSizeProvider = Provider<Size>((ref) {
  final minCanvasSize = ref.watch(minCanvasSizeProvider);
  final toolbarHeights = ref.watch(toolbarHeightsProvider);

  return Size(
    minCanvasSize.width,
    minCanvasSize.height + toolbarHeights.total,
  );
});

/// 可用最大画布尺寸提供者
final maxCanvasSizeProvider = Provider<Size?>((ref) {
  final screenSize = ref.watch(availableScreenSizeProvider);
  if (screenSize == null) return null;

  final toolbarHeights = ref.watch(toolbarHeightsProvider);
  const screenMargin = 20.0; // 窗口距离屏幕边缘的固定视觉边距

  return Size(
    screenSize.width - screenMargin * 2,
    screenSize.height - screenMargin * 2 - toolbarHeights.total,
  );
});

/// 可用屏幕尺寸提供者
final availableScreenSizeProvider = StateProvider<Size?>((ref) {
  // 默认为一个合理的初始值，实际应用中可以通过窗口API获取
  return const Size(1920, 1080);
});

/// 布局管理器类
/// 负责根据设计文档中的规范计算并应用正确的画布尺寸和缩放
class LayoutManager {
  final Ref _ref;
  final Logger _logger = Logger();

  // 视觉边距常量
  static const double visualPadding = 40.0;

  LayoutManager(this._ref);

  /// 计算并应用新截图的初始布局
  /// 根据截图尺寸计算合适的画布尺寸和缩放因子
  /// 返回计算得到的初始缩放因子
  double calculateInitialLayout(Size originalImageSize) {
    _logger.d(
        '计算初始布局: 原始图像尺寸=${originalImageSize.width}x${originalImageSize.height}');

    final minCanvasSize = _ref.read(minCanvasSizeProvider);
    final maxCanvasSize = _ref.read(maxCanvasSizeProvider) ?? Size(1920, 1080);

    // 计算目标画布宽度
    double targetCanvasWidth;
    double scaleFactorX = 1.0;

    if (originalImageSize.width + visualPadding * 2 < minCanvasSize.width) {
      // 如果内容宽度小于最小画布宽度，使用最小画布宽度
      targetCanvasWidth = minCanvasSize.width;
      _logger.d('内容宽度小于最小画布宽度，使用最小宽度: $targetCanvasWidth');
    } else if (originalImageSize.width + visualPadding * 2 <=
        maxCanvasSize.width) {
      // 如果内容宽度介于最小和最大之间，使用内容宽度加边距
      targetCanvasWidth = originalImageSize.width + visualPadding * 2;
      _logger.d('内容宽度在最小和最大之间，使用内容宽度加边距: $targetCanvasWidth');
    } else {
      // 如果内容宽度超过最大画布宽度，使用最大画布宽度并计算缩放因子
      targetCanvasWidth = maxCanvasSize.width;
      scaleFactorX =
          (maxCanvasSize.width - visualPadding * 2) / originalImageSize.width;
      _logger
          .d('内容宽度超过最大画布宽度，使用最大宽度: $targetCanvasWidth, X方向缩放因子: $scaleFactorX');
    }

    // 计算目标画布高度
    double targetCanvasHeight;
    double scaleFactorY = 1.0;

    if (originalImageSize.height + visualPadding * 2 < minCanvasSize.height) {
      // 如果内容高度小于最小画布高度，使用最小画布高度
      targetCanvasHeight = minCanvasSize.height;
      _logger.d('内容高度小于最小画布高度，使用最小高度: $targetCanvasHeight');
    } else if (originalImageSize.height + visualPadding * 2 <=
        maxCanvasSize.height) {
      // 如果内容高度介于最小和最大之间，使用内容高度加边距
      targetCanvasHeight = originalImageSize.height + visualPadding * 2;
      _logger.d('内容高度在最小和最大之间，使用内容高度加边距: $targetCanvasHeight');
    } else {
      // 如果内容高度超过最大画布高度，使用最大画布高度并计算缩放因子
      targetCanvasHeight = maxCanvasSize.height;
      scaleFactorY =
          (maxCanvasSize.height - visualPadding * 2) / originalImageSize.height;
      _logger.d(
          '内容高度超过最大画布高度，使用最大高度: $targetCanvasHeight, Y方向缩放因子: $scaleFactorY');
    }

    // 计算最终缩放因子，取X和Y方向中较小的一个
    double initialScaleFactor = 1.0;
    if (scaleFactorX < 1.0 || scaleFactorY < 1.0) {
      initialScaleFactor = math.min(scaleFactorX, scaleFactorY);
      _logger.d('最终计算的初始缩放因子: $initialScaleFactor');
    }

    // 计算当前画布视觉尺寸
    final currentCanvasViewSize = Size(targetCanvasWidth, targetCanvasHeight);
    _logger.d(
        '计算的画布视觉尺寸: ${currentCanvasViewSize.width}x${currentCanvasViewSize.height}');

    // 应用计算结果到状态
    applyLayoutToCanvas(
        originalImageSize, currentCanvasViewSize, initialScaleFactor);

    return initialScaleFactor;
  }

  /// 将计算好的布局应用到画布
  void applyLayoutToCanvas(
      Size originalImageSize, Size canvasViewSize, double scaleFactor) {
    // 更新画布尺寸
    _ref.read(canvasProvider.notifier).setImageSize(originalImageSize);

    // 计算新的内边距，确保截图在画布中居中
    final horizontalPadding =
        (canvasViewSize.width - originalImageSize.width) / 2;
    final verticalPadding =
        (canvasViewSize.height - originalImageSize.height) / 2;

    // 确保内边距不为负
    final effectiveHorizontalPadding = math.max(0.0, horizontalPadding);
    final effectiveVerticalPadding = math.max(0.0, verticalPadding);

    // 设置均匀的内边距
    final padding = EdgeInsets.symmetric(
        horizontal: effectiveHorizontalPadding,
        vertical: effectiveVerticalPadding);

    // 先应用内边距，避免setPadding触发额外的布局计算
    _ref.read(canvasProvider.notifier).setPadding(padding);

    // 获取视口尺寸
    final viewportSize = _ref.read(canvasProvider).viewportSize;

    // 计算总内容尺寸（包含内边距）
    final totalContentSize = Size(originalImageSize.width + padding.horizontal,
        originalImageSize.height + padding.vertical);

    // 应用缩放级别
    _ref.read(canvasTransformProvider.notifier).setZoomLevel(scaleFactor);

    // 计算缩放后内容的尺寸
    final scaledContentWidth = totalContentSize.width * scaleFactor;
    final scaledContentHeight = totalContentSize.height * scaleFactor;

    // 计算使内容在视口中居中的偏移量
    final offsetX = (viewportSize.width - scaledContentWidth) / 2;
    final offsetY = (viewportSize.height - scaledContentHeight) / 2;

    // 应用偏移量确保居中
    _ref
        .read(canvasTransformProvider.notifier)
        .setOffset(Offset(offsetX, offsetY));

    _logger.d(
        '已应用布局: 内边距=$padding, 缩放因子=$scaleFactor, 偏移=(${offsetX.toStringAsFixed(1)}, ${offsetY.toStringAsFixed(1)})');
  }

  /// 重置所有布局状态
  /// 在第二次截图时调用，以确保状态完全重置
  void resetLayoutState() {
    _logger.d('重置布局状态');

    // 重置画布变换
    _ref.read(canvasTransformProvider.notifier).setZoomLevel(1.0);
    _ref.read(canvasTransformProvider.notifier).setOffset(Offset.zero);

    // 重置内边距
    _ref.read(canvasProvider.notifier).setPadding(EdgeInsets.zero);
  }

  /// 更新可用屏幕尺寸
  void updateAvailableScreenSize(Size size) {
    _ref.read(availableScreenSizeProvider.notifier).state = size;
    _logger.d('更新可用屏幕尺寸: ${size.width}x${size.height}');
  }
}
