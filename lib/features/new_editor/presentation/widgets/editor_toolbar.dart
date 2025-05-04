import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core/editor_state_core.dart';
import '../../application/providers/painter_providers.dart';
import '../../application/providers/state_providers.dart';
import 'toolbar/tool_button.dart';

/// 编辑器顶部工具栏
class EditorToolbar extends ConsumerWidget {
  /// 保存图像回调
  final VoidCallback? onSaveImage;

  /// 复制到剪贴板回调
  final VoidCallback? onCopyToClipboard;

  /// 导出图像回调
  final VoidCallback? onExportImage;

  /// 构造函数
  const EditorToolbar({
    Key? key,
    this.onSaveImage,
    this.onCopyToClipboard,
    this.onExportImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMacOS = Platform.isMacOS;
    final editorCore = ref.read(editorStateCoreProvider);
    final currentDrawingMode = ref.watch(currentDrawingModeProvider);
    final painterUtils = ref.read(painterProvidersUtilsProvider);
    final painterController = ref.read(painterControllerProvider);

    return Container(
      color: const Color(0xFFE0E0E0), // 灰色背景
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        children: [
          // macOS系统左侧预留空间
          if (isMacOS) const SizedBox(width: 50),

          // Wallpaper按钮
          Container(
            decoration: BoxDecoration(
              color: ref.watch(wallpaperPanelVisibleProvider)
                  ? Colors.blue.shade100
                  : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 3,
            ),
            child: InkWell(
              onTap: () => editorCore.toggleWallpaperPanel(),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.palette,
                    size: 18,
                    color: ref.watch(wallpaperPanelVisibleProvider)
                        ? Colors.blue.shade700
                        : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Wallpaper',
                    style: TextStyle(
                      fontSize: 14,
                      color: ref.watch(wallpaperPanelVisibleProvider)
                          ? Colors.blue.shade700
                          : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 工具容器 - 包含所有编辑工具
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 选择工具
                    _buildToolButton(
                      icon: Icons.pan_tool,
                      isSelected: currentDrawingMode == DrawingMode.selection,
                      onTap: () =>
                          updateDrawingMode(ref, DrawingMode.selection),
                    ),

                    // 矩形工具
                    _buildToolButton(
                      icon: Icons.crop_square,
                      isSelected: currentDrawingMode == DrawingMode.rectangle,
                      onTap: () =>
                          updateDrawingMode(ref, DrawingMode.rectangle),
                    ),

                    // 椭圆工具
                    _buildToolButton(
                      icon: Icons.circle_outlined,
                      isSelected: currentDrawingMode == DrawingMode.oval,
                      onTap: () => updateDrawingMode(ref, DrawingMode.oval),
                    ),

                    // 箭头工具
                    _buildToolButton(
                      icon: Icons.arrow_right_alt,
                      isSelected: currentDrawingMode == DrawingMode.arrow,
                      onTap: () => updateDrawingMode(ref, DrawingMode.arrow),
                    ),

                    // 文本工具
                    _buildToolButton(
                      icon: Icons.text_fields,
                      isSelected: currentDrawingMode == DrawingMode.text,
                      onTap: () => updateDrawingMode(ref, DrawingMode.text),
                    ),

                    // 手绘工具
                    _buildToolButton(
                      icon: Icons.brush,
                      isSelected: currentDrawingMode == DrawingMode.pen,
                      onTap: () => updateDrawingMode(ref, DrawingMode.pen),
                    ),

                    // 橡皮擦工具
                    _buildToolButton(
                      icon: Icons.auto_fix_normal,
                      isSelected: currentDrawingMode == DrawingMode.eraser,
                      onTap: () => updateDrawingMode(ref, DrawingMode.eraser),
                    ),

                    // 分隔线
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: Colors.grey[300],
                    ),

                    // 撤销按钮
                    _buildToolButton(
                      icon: Icons.undo,
                      isSelected: false,
                      onTap: painterController.canUndo
                          ? () => painterController.undo()
                          : null,
                    ),

                    // 重做按钮
                    _buildToolButton(
                      icon: Icons.redo,
                      isSelected: false,
                      onTap: painterController.canRedo
                          ? () => painterController.redo()
                          : null,
                    ),

                    // 分隔线
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: Colors.grey[300],
                    ),

                    // 颜色选择按钮
                    _buildToolButton(
                      icon: Icons.color_lens,
                      isSelected: false,
                      color: ref.watch(strokeColorProvider),
                      onTap: () {
                        ref.read(showColorPickerProvider.notifier).state = true;
                      },
                    ),

                    // 线宽选择按钮
                    _buildToolButton(
                      icon: Icons.line_weight,
                      isSelected: false,
                      onTap: () => _showStrokeWidthDialog(context, ref),
                    ),

                    // 填充开关
                    _buildToolButton(
                      icon: Icons.format_color_fill,
                      isSelected: ref.watch(isFilledProvider),
                      onTap: () => ref.read(isFilledProvider.notifier).state =
                          !ref.watch(isFilledProvider),
                    ),

                    // 清除所有按钮
                    _buildToolButton(
                      icon: Icons.delete_outline,
                      isSelected: false,
                      onTap: () =>
                          painterUtils.clearAllDrawables(painterController),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 适应视口按钮
          _buildToolButton(
            icon: Icons.fit_screen,
            isSelected: false,
            onTap: () => editorCore.fitContentToViewport(),
          ),

          const SizedBox(width: 2),

          // 保存按钮
          if (onSaveImage != null)
            _buildToolButton(
              icon: Icons.save,
              isSelected: false,
              onTap: onSaveImage,
            ),

          const SizedBox(width: 2),

          // 复制到剪贴板按钮
          if (onCopyToClipboard != null)
            _buildToolButton(
              icon: Icons.copy,
              isSelected: false,
              onTap: onCopyToClipboard,
            ),

          // 导出按钮
          if (onExportImage != null)
            _buildToolButton(
              icon: Icons.file_download,
              isSelected: false,
              onTap: onExportImage,
            ),
        ],
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color:
              color ?? (isSelected ? Colors.blue.shade700 : Colors.grey[800]),
        ),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        splashRadius: 20,
        tooltip: '工具按钮',
      ),
    );
  }

  /// 显示线宽选择对话框
  void _showStrokeWidthDialog(BuildContext context, WidgetRef ref) {
    final currentWidth = ref.read(strokeWidthProvider);
    double selectedWidth = currentWidth;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择线宽'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: selectedWidth,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: selectedWidth.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => selectedWidth = value);
                },
              ),
              Container(
                height: selectedWidth,
                width: 100,
                color: ref.read(strokeColorProvider),
                margin: const EdgeInsets.only(top: 10),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(strokeWidthProvider.notifier).state = selectedWidth;
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
