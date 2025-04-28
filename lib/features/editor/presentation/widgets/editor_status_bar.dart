import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'zoom_control.dart';
import 'action_button.dart';
import '../../../../src/features/drag_export/drag_to_copy_button.dart';

/// 编辑器底部状态栏组件
class EditorStatusBar extends StatelessWidget {
  /// 要导出的图像数据
  final Uint8List? imageData;

  /// 当前缩放级别
  final double zoomLevel;

  /// 最小缩放级别
  final double minZoom;

  /// 最大缩放级别
  final double maxZoom;

  /// 缩放级别变化回调
  final ValueChanged<double> onZoomChanged;

  /// 缩放菜单点击回调
  final VoidCallback onZoomMenuTap;

  /// 用于缩放菜单的LayerLink
  final LayerLink zoomLayerLink;

  /// 缩放按钮Key
  final GlobalKey? zoomButtonKey;

  /// 导出图片回调
  final VoidCallback onExportImage;

  /// 复制到剪贴板回调
  final VoidCallback onCopyToClipboard;

  /// 裁剪图片回调
  final VoidCallback onCrop;

  /// 打开文件位置回调
  final VoidCallback onOpenFileLocation;

  /// 拖拽成功回调
  final VoidCallback? onDragSuccess;

  /// 拖拽失败回调
  final Function(String)? onDragError;

  /// 构造函数
  const EditorStatusBar({
    Key? key,
    required this.imageData,
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    required this.onZoomMenuTap,
    required this.zoomLayerLink,
    this.zoomButtonKey,
    required this.onExportImage,
    required this.onCopyToClipboard,
    required this.onCrop,
    required this.onOpenFileLocation,
    this.onDragSuccess,
    this.onDragError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 左侧缩放控件
          Expanded(
            child: Row(
              children: [
                ZoomControl(
                  zoomLevel: zoomLevel,
                  minZoom: minZoom,
                  maxZoom: maxZoom,
                  onZoomChanged: onZoomChanged,
                  onZoomMenuTap: onZoomMenuTap,
                  zoomLayerLink: zoomLayerLink,
                  buttonKey: zoomButtonKey,
                ),
              ],
            ),
          ),

          // 中间拖拽按钮
          DragToCopyButton(
            imageData: imageData,
            onDragSuccess: onDragSuccess,
            onDragError: onDragError,
          ),

          // 右侧操作按钮
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionButton(
                  icon: PhosphorIcons.export(PhosphorIconsStyle.light),
                  onTap: onExportImage,
                  tooltip: '导出图片',
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: PhosphorIcons.copySimple(PhosphorIconsStyle.light),
                  onTap: onCopyToClipboard,
                  tooltip: '复制到剪贴板',
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: PhosphorIcons.scissors(PhosphorIconsStyle.light),
                  onTap: onCrop,
                  tooltip: '裁剪',
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: PhosphorIcons.folderOpen(PhosphorIconsStyle.light),
                  onTap: onOpenFileLocation,
                  tooltip: '打开文件位置',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
