import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/models/capture_mode.dart';
import '../providers/capture_mode_provider.dart';
import 'toolbar_button_style.dart'; // 引入按钮样式
import 'mode_menu_item.dart'; // 导入新的菜单项 Widget

/// Mode 按钮及其悬停菜单的模块化组件
class ModeHoverMenuButton extends StatefulWidget {
  final VoidCallback onCaptureRectangle;
  final VoidCallback onCaptureFullscreen;
  final VoidCallback onCaptureWindow;

  const ModeHoverMenuButton({
    super.key,
    required this.onCaptureRectangle,
    required this.onCaptureFullscreen,
    required this.onCaptureWindow,
  });

  @override
  State<ModeHoverMenuButton> createState() => _ModeHoverMenuButtonState();
}

class _ModeHoverMenuButtonState extends State<ModeHoverMenuButton> {
  Timer? _hideTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  // 显示悬停菜单
  void _showHoverMenu(BuildContext context) {
    _hideTimer?.cancel();
    _removeOverlay();
    _overlayEntry = _createModeMenuOverlay(context);
    Overlay.of(context).insert(_overlayEntry!);
  }

  // 开始隐藏菜单的计时器
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 500), () {
      _removeOverlay();
    });
  }

  // 移除浮动菜单
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 创建Mode菜单浮层
  OverlayEntry _createModeMenuOverlay(BuildContext context) {
    return OverlayEntry(
      builder: (_) => Positioned(
        width: 200, // 适应横向排列
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 36),
          child: MouseRegion(
            onEnter: (_) => _hideTimer?.cancel(),
            onExit: (_) => _startHideTimer(),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: _buildModeMenuContent(context),
            ),
          ),
        ),
      ),
    );
  }

  // 构建 Mode 悬停菜单的内容 - 使用 ModeMenuItem
  Widget _buildModeMenuContent(BuildContext context) {
    final provider = context.watch<CaptureModeProvider>();
    final currentMode = provider.currentMode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ModeMenuItem(
            icon: PhosphorIcons.square(PhosphorIconsStyle.light),
            label: 'Rectangle',
            isSelected: currentMode == CaptureMode.rectangle,
            onTap: () {
              developer.log('Mode selected: Rectangle');
              provider.setMode(CaptureMode.rectangle);
              widget.onCaptureRectangle();
              _removeOverlay();
            },
          ),
          ModeMenuItem(
            icon: PhosphorIcons.monitorPlay(PhosphorIconsStyle.light),
            label: 'Fullscreen',
            isSelected: currentMode == CaptureMode.fullscreen,
            onTap: () {
              developer.log('Mode selected: Fullscreen');
              provider.setMode(CaptureMode.fullscreen);
              widget.onCaptureFullscreen();
              _removeOverlay();
            },
          ),
          ModeMenuItem(
            icon: PhosphorIcons.browser(PhosphorIconsStyle.light),
            label: 'Window',
            isSelected: currentMode == CaptureMode.window,
            onTap: () {
              developer.log('Mode selected: Window');
              provider.setMode(CaptureMode.window);
              widget.onCaptureWindow();
              _removeOverlay();
            },
          ),
        ],
      ),
    );
  }

  // 辅助函数：根据标签获取 CaptureMode (保留，因为 buildModeIconItem 内部逻辑不再需要访问它了)
  // CaptureMode _getModeFromLabel(String label) {
  //   switch (label) {
  //     case 'Rectangle': return CaptureMode.rectangle;
  //     case 'Fullscreen': return CaptureMode.fullscreen;
  //     case 'Window': return CaptureMode.window;
  //     default: return CaptureMode.rectangle;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showHoverMenu(context),
        onExit: (_) => _startHideTimer(),
        child: ToolbarButtonStyle.build(
          // 使用封装的样式
          icon: PhosphorIcons.square(PhosphorIconsStyle.light),
          label: 'Mode',
          onPressed: () {
            developer.log(
                'Mode button clicked, showing menu if not already visible.');
            _showHoverMenu(context);
          },
          showDropdown: true,
        ),
      ),
    );
  }
}
