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

  /// 切换Wallpaper面板回调
  final VoidCallback onToggleWallpaperPanel;

  /// Wallpaper面板是否可见
  final bool isWallpaperPanelVisible;

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
    required this.onToggleWallpaperPanel,
    this.isWallpaperPanelVisible = false,
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

          // Wallpaper按钮
          Container(
            decoration: BoxDecoration(
              color:
                  isWallpaperPanelVisible ? Colors.blue.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 3,
            ),
            child: InkWell(
              onTap: onToggleWallpaperPanel,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.palette(PhosphorIconsStyle.light),
                    size: 18,
                    color: isWallpaperPanelVisible
                        ? Colors.blue.shade700
                        : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Wallpaper',
                    style: TextStyle(
                      fontSize: 14,
                      color: isWallpaperPanelVisible
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
              child: Row(
                children: [
                  // flutter_painter_v2 工具组件
                  // 选择工具
                  ToolButton(
                    icon: PhosphorIcons.arrowsOut(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'select',
                    onTap: () => onSelectTool('select'),
                  ),

                  // 矩形工具
                  ToolButton(
                    icon: PhosphorIcons.square(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'rectangle',
                    onTap: () => onSelectTool('rectangle'),
                  ),

                  // 箭头工具
                  ToolButton(
                    icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'arrow',
                    onTap: () => onSelectTool('arrow'),
                  ),

                  // 文本工具
                  ToolButton(
                    icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'text',
                    onTap: () => onSelectTool('text'),
                  ),

                  // 手绘工具
                  ToolButton(
                    icon: PhosphorIcons.scribbleLoop(PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'freehand',
                    onTap: () => onSelectTool('freehand'),
                  ),

                  // 高亮工具
                  ToolButton(
                    icon: PhosphorIcons.highlighterCircle(
                        PhosphorIconsStyle.light),
                    isSelected: selectedTool == 'highlight',
                    onTap: () => onSelectTool('highlight'),
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

                  // ... 其他工具按钮
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 缩放按钮
          ToolButton(
            key: zoomButtonKey,
            icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
            isSelected: false,
            onTap: onZoom,
          ),

          const SizedBox(width: 2),

          // 保存按钮
          ToolButton(
            icon: PhosphorIcons.floppyDisk(PhosphorIconsStyle.light),
            isSelected: false,
            onTap: onSaveImage,
          ),

          const SizedBox(width: 2),

          // 复制到剪贴板按钮
          ToolButton(
            icon: PhosphorIcons.copySimple(PhosphorIconsStyle.light),
            isSelected: false,
            onTap: onCopyToClipboard,
          ),
        ],
      ),
    );
  }
}
