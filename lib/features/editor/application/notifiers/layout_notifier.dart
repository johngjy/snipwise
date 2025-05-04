import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/layout_state.dart';
import '../states/editor_state.dart';
import '../providers/editor_providers.dart';
import '../notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider;
import '../helpers/canvas_transform_connector.dart';

/// 布局管理器Notifier
class LayoutNotifier extends Notifier<LayoutState> {
  @override
  LayoutState build() => LayoutState.initial();

  /// 初始化屏幕尺寸
  void initialize(Size screenSize) {
    state = state.copyWith(availableScreenSize: screenSize);
  }

  /// 切换历史面板
  void toggleHistoryPanel() {
    state = state.copyWith(isHistoryPanelOpen: !state.isHistoryPanelOpen);
    _recalculateLayoutBasedOnCurrentContent();
  }

  /// 更新工具栏高度
  void updateToolbarHeights({double? top, double? bottom}) {
    state = state.copyWith(
      topToolbarHeight: top ?? state.topToolbarHeight,
      bottomToolbarHeight: bottom ?? state.bottomToolbarHeight,
    );
    _recalculateLayoutBasedOnCurrentContent();
  }

  /// 处理用户手动调整窗口大小
  void handleManualResize(Size newWindowSize) {
    state = state.copyWith(
      editorWindowSize: newWindowSize,
      userHasManuallyResized: true,
    );

    // 立即根据新窗口尺寸重新计算画布尺寸
    final double canvasHeight = newWindowSize.height - state.totalToolbarHeight;
    final double canvasWidth = newWindowSize.width;

    state = state.copyWith(
      currentCanvasViewSize: Size(canvasWidth, canvasHeight),
    );
  }

  /// 为新内容重新计算布局
  /// 返回计算出的初始缩放因子
  double recalculateLayoutForNewContent(
      Size originalImageSize, EdgeInsets currentPadding) {
    if (state.availableScreenSize == null) {
      // 如果没有屏幕尺寸信息，使用默认值
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
    double initialScaleFactor = 1.0;
    if (scaleFactorX < 1.0 || scaleFactorY < 1.0) {
      initialScaleFactor =
          scaleFactorX < scaleFactorY ? scaleFactorX : scaleFactorY;
    }

    // 更新当前画布视觉尺寸
    final Size newCanvasSize = Size(targetCanvasWidth, targetCanvasHeight);

    // 计算窗口尺寸
    final Size newWindowSize = Size(
      targetCanvasWidth,
      targetCanvasHeight + state.totalToolbarHeight,
    );

    // 更新状态
    state = state.copyWith(
      currentCanvasViewSize: newCanvasSize,
      editorWindowSize: newWindowSize,
      userHasManuallyResized: false,
    );

    return initialScaleFactor;
  }

  /// 重置布局
  void resetLayout() {
    state = LayoutState.initial().copyWith(
      availableScreenSize: state.availableScreenSize,
    );
  }

  /// 根据当前内容重新计算布局 (私有方法)
  void _recalculateLayoutBasedOnCurrentContent() {
    final originalImageSize =
        ref.read(editorStateProvider.select((s) => s.originalImageSize));
    final wallpaperPadding =
        ref.read(editorStateProvider.select((s) => s.wallpaperPadding));

    if (originalImageSize == null) return;

    final newScale = recalculateLayoutForNewContent(
      originalImageSize,
      wallpaperPadding,
    );

    if (newScale < 1.0) {
      ref.read(canvasTransformProvider.notifier).setZoomLevel(newScale);
    }
  }
}
