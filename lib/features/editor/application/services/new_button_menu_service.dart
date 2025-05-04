import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/editor_providers.dart';
import '../../presentation/widgets/hover_menu.dart';
import '../../../capture/data/models/capture_mode.dart';

/// 新建按钮菜单服务类，管理新建按钮菜单的显示和隐藏
class NewButtonMenuService {
  static final NewButtonMenuService _instance =
      NewButtonMenuService._internal();

  factory NewButtonMenuService() => _instance;

  NewButtonMenuService._internal();

  final Logger _logger = Logger();
  OverlayEntry? _newButtonOverlay;
  Timer? _newButtonHideTimer;

  // 定义菜单隐藏延迟时间常量
  static const Duration _hideDelay = Duration(milliseconds: 800);

  /// 显示新建按钮菜单
  void showNewButtonMenu({
    required BuildContext context,
    required WidgetRef ref,
    required LayerLink buttonLayerLink,
    required Function(CaptureMode) onCaptureModeSelected,
  }) {
    _newButtonHideTimer?.cancel();

    if (_newButtonOverlay != null) {
      hideNewButtonMenu(ref);
      return;
    }

    final List<HoverMenuItem> menuItems = [
      HoverMenuItem(
        icon: PhosphorIcons.square(PhosphorIconsStyle.light),
        label: 'Capture Area',
        onTap: () => onCaptureModeSelected(CaptureMode.region),
      ),
      HoverMenuItem(
        icon: PhosphorIcons.monitorPlay(PhosphorIconsStyle.light),
        label: 'Fullscreen',
        onTap: () => onCaptureModeSelected(CaptureMode.fullscreen),
      ),
      HoverMenuItem(
        icon: PhosphorIcons.browser(PhosphorIconsStyle.light),
        label: 'Window',
        onTap: () => onCaptureModeSelected(CaptureMode.window),
      ),
    ];

    // 创建菜单叠加层
    _newButtonOverlay = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: buttonLayerLink,
        offset: const Offset(0, 26), // 精确定位到按钮底部
        // 使用Align包裹，强制其左上对齐，阻止扩展
        child: Align(
          alignment: Alignment.topLeft,
          child: MouseRegion(
            onEnter: (_) {
              _newButtonHideTimer?.cancel();
            },
            onExit: (_) {
              // 使用延迟隐藏菜单，给用户更多时间操作
              _newButtonHideTimer = Timer(_hideDelay, () {
                hideNewButtonMenu(ref);
              });
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: HoverMenu(items: menuItems),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_newButtonOverlay!);

    // 更新状态
    ref.read(editorStateProvider.notifier).setNewButtonMenuVisible(true);
  }

  /// 开始定时器以隐藏新建按钮菜单
  void startHideTimer(WidgetRef ref) {
    _newButtonHideTimer?.cancel();
    _newButtonHideTimer = Timer(_hideDelay, () {
      hideNewButtonMenu(ref);
    });
  }

  /// 隐藏新建按钮菜单
  void hideNewButtonMenu(WidgetRef ref) {
    _newButtonHideTimer?.cancel();

    if (_newButtonOverlay != null) {
      _newButtonOverlay!.remove();
      _newButtonOverlay = null;
    }

    ref.read(editorStateProvider.notifier).setNewButtonMenuVisible(false);
  }

  /// 清理资源
  void dispose() {
    _newButtonHideTimer?.cancel();

    if (_newButtonOverlay != null) {
      _newButtonOverlay!.remove();
      _newButtonOverlay = null;
    }
  }
}
