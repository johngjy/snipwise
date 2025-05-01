import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../providers/editor_providers.dart';
import '../states/layout_state.dart';

/// 布局管理Notifier
class LayoutNotifier extends Notifier<LayoutState> {
  @override
  LayoutState build() => LayoutState.initial();

  /// 初始化布局，设置屏幕尺寸和默认的最小/最大画布尺寸
  void initialize(Size screenSize) {
    state = LayoutState.initial().copyWith(
      availableScreenSize: screenSize,
    );
  }

  /// 重置布局状态为初始值
  void resetLayout() {
    state = LayoutState.initial().copyWith(
      availableScreenSize: state.availableScreenSize,
    );
  }

  /// 根据新的内容尺寸和边距重新计算布局（窗口大小、画布大小、初始缩放）
  double recalculateLayoutForNewContent(
      Size originalImageSize, EdgeInsets currentPadding) {
    // 如果没有屏幕尺寸，则无法计算布局
    if (state.maxCanvasSize == null) {
      return 1.0;
    }

    // 定义视觉边距
    const double visualPadding = 40.0;

    // 计算内容尺寸（图像+Wallpaper边距）
    final double contentWidth =
        originalImageSize.width + currentPadding.left + currentPadding.right;
    final double contentHeight =
        originalImageSize.height + currentPadding.top + currentPadding.bottom;

    // 计算带视觉边距的总内容尺寸
    final double totalContentWidth = contentWidth + visualPadding * 2;
    final double totalContentHeight = contentHeight + visualPadding * 2;

    // 获取最小画布尺寸和最大画布尺寸
    final Size minCanvas = state.minCanvasSize;
    final Size maxCanvas = state.maxCanvasSize!;

    // 计算目标画布宽度和可能的X方向缩放
    double targetCanvasWidth;
    double scaleFactorX = 1.0;

    if (totalContentWidth < minCanvas.width) {
      // 内容宽度小于最小宽度，使用最小宽度
      targetCanvasWidth = minCanvas.width;
    } else if (totalContentWidth <= maxCanvas.width) {
      // 内容宽度介于最小和最大宽度之间，使用内容宽度
      targetCanvasWidth = totalContentWidth;
    } else {
      // 内容宽度超过最大宽度，使用最大宽度，计算缩放因子
      targetCanvasWidth = maxCanvas.width;
      scaleFactorX = maxCanvas.width / totalContentWidth;
    }

    // 计算目标画布高度和可能的Y方向缩放
    double targetCanvasHeight;
    double scaleFactorY = 1.0;

    if (totalContentHeight < minCanvas.height) {
      // 内容高度小于最小高度，使用最小高度
      targetCanvasHeight = minCanvas.height;
    } else if (totalContentHeight <= maxCanvas.height) {
      // 内容高度介于最小和最大高度之间，使用内容高度
      targetCanvasHeight = totalContentHeight;
    } else {
      // 内容高度超过最大高度，使用最大高度，计算缩放因子
      targetCanvasHeight = maxCanvas.height;
      scaleFactorY = maxCanvas.height / totalContentHeight;
    }

    // 如果宽度或高度需要缩放，选择较小的缩放因子
    double initialScaleFactor = math.min(scaleFactorX, scaleFactorY);

    // 计算编辑器的窗口尺寸 (画布高度 + UI总高度)
    final double editorWindowWidth = targetCanvasWidth;
    final double editorWindowHeight =
        targetCanvasHeight + state.totalToolbarHeight;

    // 更新布局状态
    state = state.copyWith(
      editorWindowSize: Size(editorWindowWidth, editorWindowHeight),
      currentCanvasViewSize: Size(targetCanvasWidth, targetCanvasHeight),
    );

    // 返回计算出的初始缩放因子
    return initialScaleFactor;
  }

  /// 更新当前画布视图的大小 (通常在LayoutBuilder中调用)
  void updateCanvasViewSize(Size newSize) {
    if (state.currentCanvasViewSize != newSize) {
      state = state.copyWith(currentCanvasViewSize: newSize);
    }
  }
}
