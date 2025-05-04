import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/state_providers.dart';

/// 缩放控制组件
class ZoomControl extends ConsumerWidget {
  /// 缩放变化回调
  final Function(double)? onZoomChanged;

  /// 构造函数
  const ZoomControl({
    Key? key,
    this.onZoomChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasProvider);
    final editorCore = ref.read(editorStateCoreProvider);
    final scale = canvasState.scale;
    final scalePercent = (scale * 100).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 缩放百分比显示
        Text(
          '$scalePercent%',
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(width: 8),

        // 缩放减小按钮
        _buildIconButton(
          icon: Icons.remove,
          tooltip: '缩小',
          onPressed: () {
            final newScale = scale * 0.9;
            if (onZoomChanged != null) {
              onZoomChanged!(newScale);
            } else {
              editorCore.setZoomLevel(newScale);
            }
          },
        ),

        // 缩放重置按钮
        _buildIconButton(
          icon: Icons.fit_screen,
          tooltip: '适合窗口',
          onPressed: () {
            editorCore.fitContentToViewport();
            if (onZoomChanged != null) {
              onZoomChanged!(editorCore.canvasState.scale);
            }
          },
        ),

        // 缩放增大按钮
        _buildIconButton(
          icon: Icons.add,
          tooltip: '放大',
          onPressed: () {
            final newScale = scale * 1.1;
            if (onZoomChanged != null) {
              onZoomChanged!(newScale);
            } else {
              editorCore.setZoomLevel(newScale);
            }
          },
        ),
      ],
    );
  }

  /// 构建图标按钮
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: Colors.black87,
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }
}
