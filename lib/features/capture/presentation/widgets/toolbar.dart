// import 'dart:io'; // Remove unused import
// import 'dart:developer' as developer; // Remove unused import
// import 'dart:async'; // Remove unused import
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:provider/provider.dart'; // Remove unused import
// import '../providers/capture_mode_provider.dart'; // Remove unused import
// import '../../data/models/capture_mode.dart'; // Remove unused import
import 'mode_hover_menu_button.dart'; // 导入Mode按钮组件
import 'toolbar_button_style.dart'; // 导入按钮样式

/// 工具栏组件 - 显示在顶部的功能按钮
class Toolbar extends StatefulWidget {
  /// 区域截图回调 (New 按钮)
  final VoidCallback onCaptureRegion;

  /// 全屏截图回调 (Snip 按钮 和 Mode 菜单项)
  final VoidCallback onCaptureFullscreen;

  /// 窗口截图回调 (Mode 菜单项)
  final VoidCallback onCaptureWindow;

  /// 矩形/区域截图回调 (Mode 菜单项 - 通常同 onCaptureRegion)
  final VoidCallback onCaptureRectangle; // 新增

  /// 高清屏幕截图回调 (Snip 按钮 - 保留以防未来需要区分)
  final VoidCallback onCaptureHDScreen;

  /// 视频录制回调
  final VoidCallback onCaptureVideo;

  /// 延时截图回调
  final VoidCallback onDelayCapture;

  /// OCR功能回调
  final VoidCallback onPerformOCR;

  /// 打开图片回调
  final VoidCallback onOpenImage;

  /// 显示历史记录回调
  final VoidCallback onShowHistory;

  /// 构造函数
  const Toolbar({
    super.key,
    required this.onCaptureRegion,
    required this.onCaptureHDScreen, // 保留，但 Snip 按钮现在触发 Fullscreen
    required this.onCaptureVideo,
    required this.onCaptureWindow,
    required this.onDelayCapture,
    required this.onPerformOCR,
    required this.onOpenImage,
    required this.onShowHistory,
    required this.onCaptureFullscreen, // 新增
    required this.onCaptureRectangle, // 新增
  });

  // 定义按钮间距常量，便于统一管理
  static const double kButtonSpacing = 10.0; // 减小按钮间距，使工具栏更紧凑
  static const double kHorizontalPadding = 0.0;

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  // 移除 Mode 按钮相关的状态和方法
  // Timer? _hideTimer;
  // final LayerLink _layerLink = LayerLink();
  // OverlayEntry? _overlayEntry;

  // 移除 Delay 按钮相关的状态和方法
  // Timer? _delayHideTimer;
  // final LayerLink _delayLayerLink = LayerLink();
  // OverlayEntry? _delayOverlayEntry;

  @override
  void dispose() {
    // _delayHideTimer?.cancel(); // 移除
    // _removeDelayOverlay(); // 移除
    super.dispose();
  }

  // 移除 Delay 相关的悬停菜单方法
  // void _showHoverMenu(String label, BuildContext context) { ... }
  // void _startHideTimer() { ... }
  // void _removeDelayOverlay() { ... }
  // OverlayEntry _createDelayMenuOverlay(BuildContext context) { ... }
  // Widget _buildDelayMenuContent(BuildContext context) { ... }
  // Widget _buildDelayMenuItem({ ... }) { ... }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // New Button
            ToolbarButtonStyle.build(
              icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.light),
              label: 'New',
              onPressed: widget.onCaptureRegion,
            ),
            const SizedBox(width: Toolbar.kButtonSpacing),

            // Video Button
            ToolbarButtonStyle.build(
              icon: PhosphorIcons.play(PhosphorIconsStyle.light),
              label: 'Video',
              showDropdown: true,
              onPressed: widget.onCaptureVideo,
            ),
            const SizedBox(width: Toolbar.kButtonSpacing),

            // Mode Button
            ModeHoverMenuButton(
              onCaptureRectangle: widget.onCaptureRectangle,
              onCaptureFullscreen: widget.onCaptureFullscreen,
              onCaptureWindow: widget.onCaptureWindow,
            ),
            const SizedBox(width: Toolbar.kButtonSpacing),

            // Delay Button - 恢复为简单按钮，直接调用 onDelayCapture
            ToolbarButtonStyle.build(
              icon: PhosphorIcons.clock(PhosphorIconsStyle.light),
              label: 'Delay',
              showDropdown: true, // 保留下拉箭头视觉提示
              onPressed: widget.onDelayCapture, // 点击直接触发外部回调
            ),
            const SizedBox(width: Toolbar.kButtonSpacing),

            // OCR Button
            ToolbarButtonStyle.build(
              icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
              label: 'OCR',
              onPressed: widget.onPerformOCR,
            ),
            const SizedBox(width: Toolbar.kButtonSpacing),

            // Open Button
            ToolbarButtonStyle.build(
              icon: PhosphorIcons.folderOpen(PhosphorIconsStyle.light),
              label: 'Open',
              onPressed: widget.onOpenImage,
            ),
            const SizedBox(width: Toolbar.kButtonSpacing),

            // History Button
            ToolbarButtonStyle.build(
              icon:
                  PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.light),
              label: 'History',
              onPressed: widget.onShowHistory,
            ),
          ],
        ),
      ),
    );
  }

  // 移除所有 Mode 和 Delay 相关的构建方法
}
