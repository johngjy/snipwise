import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'tool_button.dart';

/// 编辑器顶部工具栏组件
class EditorToolbar extends StatelessWidget {
  /// 工具按钮LayerLink
  final LayerLink newButtonLayerLink;

  /// 缩放按钮Key
  final GlobalKey zoomButtonKey;

  /// 显示新建按钮菜单的回调
  final VoidCallback onShowNewButtonMenu;

  /// 隐藏新建按钮菜单的回调
  final VoidCallback onHideNewButtonMenu;

  /// 显示保存确认对话框的回调
  final VoidCallback onShowSaveConfirmation;

  /// 选择工具的回调
  final Function(String) onSelectTool;

  /// 当前选中的工具
  final String selectedTool;

  /// 撤销操作回调
  final VoidCallback onUndo;

  /// 重做操作回调
  final VoidCallback onRedo;

  /// 缩放操作回调
  final VoidCallback onZoom;

  /// 保存图像回调
  final VoidCallback onSaveImage;

  /// 复制到剪贴板回调
  final VoidCallback onCopyToClipboard;

  /// 构造函数
  const EditorToolbar({
    super.key,
    required this.newButtonLayerLink,
    required this.zoomButtonKey,
    required this.onShowNewButtonMenu,
    required this.onHideNewButtonMenu,
    required this.onShowSaveConfirmation,
    required this.onSelectTool,
    required this.selectedTool,
    required this.onUndo,
    required this.onRedo,
    required this.onZoom,
    required this.onSaveImage,
    required this.onCopyToClipboard,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = Platform.isMacOS;

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

          // New按钮
          CompositedTransformTarget(
            link: newButtonLayerLink,
            child: MouseRegion(
              onEnter: (_) => onShowNewButtonMenu(),
              onExit: (_) => onHideNewButtonMenu(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: InkWell(
                  onTap: onShowNewButtonMenu,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.plus(PhosphorIconsStyle.light),
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'New',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
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
              child: Row(
                children: [
                  // 编辑工具按钮
                  ToolButton(
                    icon:
                        PhosphorIcons.chatCircleText(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'callout',
                    onTap: () => onSelectTool('callout'),
                  ),
                  ToolButton(
                    icon: PhosphorIcons.square(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'rect',
                    onTap: () => onSelectTool('rect'),
                  ),
                  ToolButton(
                    icon: PhosphorIcons.ruler(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'measure',
                    onTap: () => onSelectTool('measure'),
                  ),
                  ToolButton(
                    icon: PhosphorIcons.circleHalf(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'graymask',
                    onTap: () => onSelectTool('graymask'),
                  ),
                  ToolButton(
                    icon: PhosphorIcons.highlighterCircle(
                        PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'highlight',
                    onTap: () => onSelectTool('highlight'),
                  ),
                  ToolButton(
                    icon:
                        PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'magnifier',
                    onTap: () => onSelectTool('magnifier'),
                  ),
                  ToolButton(
                    icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'ocr',
                    onTap: () => onSelectTool('ocr'),
                  ),
                  ToolButton(
                    icon: PhosphorIcons.eraser(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'rubber',
                    onTap: () => onSelectTool('rubber'),
                  ),

                  // 分隔线
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: Colors.grey[300],
                  ),

                  // 动作按钮
                  ToolButton(
                    icon: PhosphorIcons.arrowCounterClockwise(
                        PhosphorIconsStyle.light),
                    isSelected: false,
                    onTap: onUndo,
                  ),
                  ToolButton(
                    icon:
                        PhosphorIcons.arrowClockwise(PhosphorIconsStyle.light),
                    isSelected: false,
                    onTap: onRedo,
                  ),
                  ToolButton(
                    icon: PhosphorIcons.magnifyingGlassPlus(
                        PhosphorIconsStyle.light),
                    isSelected: false,
                    onTap: onZoom,
                    buttonKey: zoomButtonKey,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 保存和复制按钮容器
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToolButton(
                icon: PhosphorIcons.floppyDisk(PhosphorIconsStyle.light),
                isSelected: false,
                onTap: onSaveImage,
                color: Colors.black,
              ),
              ToolButton(
                icon: PhosphorIcons.copy(PhosphorIconsStyle.light),
                isSelected: false,
                onTap: onCopyToClipboard,
                color: Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
