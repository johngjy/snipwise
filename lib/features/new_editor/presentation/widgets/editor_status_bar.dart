import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core/editor_state_core.dart';
import '../../application/providers/state_providers.dart';
import 'action_button.dart';
import 'drag_to_copy_button.dart';
import 'status_bar/zoom_control.dart';

/// 编辑器底部状态栏
class EditorStatusBar extends ConsumerWidget {
  /// 保存图像回调
  final VoidCallback? onSaveImage;

  /// 复制到剪贴板回调
  final VoidCallback? onCopyToClipboard;

  /// 导出图像回调
  final VoidCallback? onExportImage;

  /// 裁剪回调
  final VoidCallback? onCrop;

  /// 打开文件位置回调
  final VoidCallback? onOpenFileLocation;

  /// 缩放回调
  final VoidCallback? onZoomMenuTap;

  /// 缩放层链接
  final LayerLink? zoomLayerLink;

  /// 缩放按钮Key
  final GlobalKey? zoomButtonKey;

  /// 构造函数
  const EditorStatusBar({
    super.key,
    this.onSaveImage,
    this.onCopyToClipboard,
    this.onExportImage,
    this.onCrop,
    this.onOpenFileLocation,
    this.onZoomMenuTap,
    this.zoomLayerLink,
    this.zoomButtonKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取画布状态
    final canvasState = ref.watch(canvasProvider);
    final editorCore = ref.read(editorStateCoreProvider);

    // 获取图像数据
    final imageData = canvasState.imageData;
    final zoomLevel = canvasState.scale;

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
                  minZoom: 0.25,
                  maxZoom: 4.0,
                  onZoomChanged: (value) => editorCore.setZoomLevel(value),
                  onZoomMenuTap: onZoomMenuTap,
                  zoomLayerLink: zoomLayerLink,
                  buttonKey: zoomButtonKey,
                  fitZoomLevel: 0.75,
                ),

                // 如果需要，这里可以添加画布大小显示
                if (canvasState.originalImageSize != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      '${canvasState.originalImageSize!.width.round()}×${canvasState.originalImageSize!.height.round()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 中间拖拽复制区域
          if (imageData != null)
            DragToCopyButton(
              imageData: imageData,
              onTap: onCopyToClipboard,
            ),

          // 右侧操作区域
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 显示画布溢出状态
                if (ref.watch(canvasOverflowProvider))
                  const Tooltip(
                    message: '内容超出可视区域',
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),

                // 导出按钮
                if (onExportImage != null)
                  ActionButton(
                    icon: Icons.file_download,
                    tooltip: '导出图片',
                    onTap: onExportImage!,
                  ),

                const SizedBox(width: 8),

                // 复制按钮
                if (onCopyToClipboard != null)
                  ActionButton(
                    icon: Icons.copy,
                    tooltip: '复制到剪贴板',
                    onTap: onCopyToClipboard!,
                  ),

                const SizedBox(width: 8),

                // 裁剪按钮
                if (onCrop != null)
                  ActionButton(
                    icon: Icons.crop,
                    tooltip: '裁剪',
                    onTap: onCrop!,
                  ),

                const SizedBox(width: 8),

                // 保存按钮
                if (onSaveImage != null)
                  ActionButton(
                    icon: Icons.save,
                    tooltip: '保存图像',
                    onTap: onSaveImage!,
                  ),

                const SizedBox(width: 8),

                // 文件位置按钮
                if (onOpenFileLocation != null)
                  ActionButton(
                    icon: Icons.folder_open,
                    tooltip: '打开文件位置',
                    onTap: onOpenFileLocation!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
