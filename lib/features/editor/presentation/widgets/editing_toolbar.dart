import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'editing_tool_button.dart';

/// 编辑工具栏 Widget
class EditingToolbar extends StatelessWidget {
  final String selectedTool;
  final Function(String) onToolSelected;
  final VoidCallback? onUndo; // Made optional
  final VoidCallback? onRedo; // Made optional
  final VoidCallback? onZoom; // Made optional
  final VoidCallback onSave;
  final VoidCallback onCopy;

  const EditingToolbar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
    this.onUndo,
    this.onRedo,
    this.onZoom,
    required this.onSave,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          EditingToolButton(
            icon: PhosphorIcons.chatCircleText(PhosphorIconsStyle.light),
            tooltip: '文字标注',
            isSelected: selectedTool == 'callout',
            onPressed: () => onToolSelected('callout'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.square(PhosphorIconsStyle.light),
            tooltip: '绘制矩形',
            isSelected: selectedTool == 'rect',
            onPressed: () => onToolSelected('rect'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.ruler(PhosphorIconsStyle.light),
            tooltip: '测量',
            isSelected: selectedTool == 'measure',
            onPressed: () => onToolSelected('measure'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.circleHalf(PhosphorIconsStyle.light),
            tooltip: '灰度遮罩',
            isSelected: selectedTool == 'graymask',
            onPressed: () => onToolSelected('graymask'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.highlighterCircle(PhosphorIconsStyle.light),
            tooltip: '高亮',
            isSelected: selectedTool == 'highlight',
            onPressed: () => onToolSelected('highlight'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
            tooltip: '放大镜',
            isSelected: selectedTool == 'magnifier',
            onPressed: () => onToolSelected('magnifier'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
            tooltip: 'OCR文字识别',
            isSelected: selectedTool == 'ocr',
            onPressed: () => onToolSelected('ocr'),
          ),
          EditingToolButton(
            icon: PhosphorIcons.eraser(PhosphorIconsStyle.light),
            tooltip: '橡皮擦',
            isSelected: selectedTool == 'rubber',
            onPressed: () => onToolSelected('rubber'),
          ),
          // Actions (Undo, Redo, Zoom) - use onPressed directly
          EditingToolButton(
            icon: PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.light),
            tooltip: '撤销',
            isSelected: false, // Actions are not selectable tools
            onPressed: onUndo ?? () {}, // Handle null callback
          ),
          EditingToolButton(
            icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.light),
            tooltip: '重做',
            isSelected: false,
            onPressed: onRedo ?? () {}, // Handle null callback
          ),
          EditingToolButton(
            icon: PhosphorIcons.magnifyingGlassPlus(PhosphorIconsStyle.light),
            tooltip: '缩放',
            isSelected: false,
            onPressed: onZoom ?? () {}, // Handle null callback
          ),

          // Spacer to push save/copy to the right
          const Spacer(),

          // Save Button
          EditingToolButton(
            icon: PhosphorIcons.floppyDisk(PhosphorIconsStyle.light),
            tooltip: '保存图片',
            isSelected: false,
            onPressed: onSave,
          ),

          // Copy Button
          EditingToolButton(
            icon: PhosphorIcons.copy(PhosphorIconsStyle.light),
            tooltip: '复制到剪贴板',
            isSelected: false,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
