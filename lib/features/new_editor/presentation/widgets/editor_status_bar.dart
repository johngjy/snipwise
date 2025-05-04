import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core/editor_state_core.dart';
import '../../application/providers/state_providers.dart';
import 'status_bar/zoom_control.dart';

/// 编辑器底部状态栏
class EditorStatusBar extends ConsumerWidget {
  /// 保存图像回调
  final VoidCallback? onSaveImage;

  /// 复制到剪贴板回调
  final VoidCallback? onCopyToClipboard;

  /// 导出图像回调
  final VoidCallback? onExportImage;

  /// 构造函数
  const EditorStatusBar({
    Key? key,
    this.onSaveImage,
    this.onCopyToClipboard,
    this.onExportImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取画布状态
    final canvasState = ref.watch(canvasProvider);
    // 获取图像数据
    final imageData = canvasState.imageData;

    return Container(
      height: 38,
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 左侧信息区域
          Expanded(
            child: Row(
              children: [
                // 缩放控制
                ZoomControl(),

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

          // 中间区域
          if (imageData != null) _buildDragToCopyArea(ref, imageData),

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
                  _buildActionButton(
                    icon: Icons.file_download,
                    tooltip: '导出图片',
                    onPressed: onExportImage!,
                  ),

                const SizedBox(width: 8),

                // 复制按钮
                if (onCopyToClipboard != null)
                  _buildActionButton(
                    icon: Icons.copy,
                    tooltip: '复制到剪贴板',
                    onPressed: onCopyToClipboard!,
                  ),

                const SizedBox(width: 8),

                // 保存按钮
                if (onSaveImage != null)
                  _buildActionButton(
                    icon: Icons.save,
                    tooltip: '保存图像',
                    onPressed: onSaveImage!,
                  ),

                const SizedBox(width: 8),

                // 文件位置按钮 (占位，实际功能需要实现)
                _buildActionButton(
                  icon: Icons.folder_open,
                  tooltip: '打开文件位置',
                  onPressed: () {
                    // 提示用户功能未实现
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('功能开发中...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建拖拽复制区域
  Widget _buildDragToCopyArea(WidgetRef ref, Uint8List imageData) {
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.drag_indicator,
              size: 18,
              color: Colors.grey,
            ),
          ),
          const Text(
            '拖拽或点击复制',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          // 这里是拖拽区域，实际需要实现拖拽功能
          InkWell(
            onTap: onCopyToClipboard,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(13)),
              ),
              child: const Icon(
                Icons.copy,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: Colors.grey.shade700,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }
}
