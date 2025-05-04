import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../presentation/widgets/zoom_control.dart';
import '../providers/editor_providers.dart';
import '../states/canvas_transform_state.dart';
import '../notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider;
import '../helpers/canvas_transform_connector.dart';

/// 缩放菜单服务，用于管理缩放菜单的显示和隐藏
class ZoomMenuService {
  static final ZoomMenuService _instance = ZoomMenuService._internal();

  factory ZoomMenuService() => _instance;

  ZoomMenuService._internal();

  final Logger _logger = Logger();
  OverlayEntry? _zoomOverlayEntry;
  Timer? _zoomMenuHideTimer;

  // 定义菜单隐藏延迟时间常量
  static const Duration _hideDelay = Duration(milliseconds: 800);

  /// 显示缩放菜单
  void showZoomMenu({
    required BuildContext context,
    required WidgetRef ref,
    required BuildContext buttonContext,
    required GlobalKey buttonKey,
    required Size? availableEditorSize,
    required Size? imageSize,
    double currentZoom = 1.0,
    double fitZoomLevel = 1.0,
  }) {
    final editorState = ref.read(editorStateProvider);

    // 如果菜单已经可见，则隐藏
    if (editorState.isZoomMenuVisible) {
      hideZoomMenu(ref);
      return;
    }

    final List<String> zoomOptions = [
      'Fit window',
      '50%',
      '100%',
      '150%',
      '200%',
      '300%',
    ];

    // 处理菜单项点击
    void handleMenuItemTap(String option) {
      // 使用CanvasTransformConnector处理选项
      ref.read(canvasTransformConnectorProvider).handleZoomMenuOption(option);

      hideZoomMenu(ref);
    }

    // 创建覆盖条目 - 定位在屏幕左下角
    _zoomOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: 15, // 左边距离
        bottom: 35, // 调整到选择器上方
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: MouseRegion(
            onEnter: (_) {
              _zoomMenuHideTimer?.cancel();
            },
            onExit: (_) {
              startZoomMenuHideTimer(ref);
            },
            child: ZoomMenu(
              zoomOptions: zoomOptions,
              currentZoom: currentZoom,
              fitZoomLevel: fitZoomLevel,
              onOptionSelected: handleMenuItemTap,
            ),
          ),
        ),
      ),
    );

    Overlay.of(buttonContext).insert(_zoomOverlayEntry!);

    // 更新状态
    ref.read(editorStateProvider.notifier).setZoomMenuVisible(true);
  }

  /// 开始定时器以隐藏缩放菜单
  void startZoomMenuHideTimer(WidgetRef ref) {
    _zoomMenuHideTimer?.cancel();
    _zoomMenuHideTimer = Timer(_hideDelay, () {
      hideZoomMenu(ref);
    });
  }

  /// 隐藏缩放菜单
  void hideZoomMenu(WidgetRef ref) {
    if (_zoomOverlayEntry != null) {
      _zoomOverlayEntry!.remove();
      _zoomOverlayEntry = null;
    }

    ref.read(editorStateProvider.notifier).setZoomMenuVisible(false);
  }

  /// 清理资源
  void dispose() {
    _zoomMenuHideTimer?.cancel();
    if (_zoomOverlayEntry != null) {
      _zoomOverlayEntry!.remove();
      _zoomOverlayEntry = null;
    }
  }
}
