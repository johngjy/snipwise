import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../application/core/editor_state_core.dart';
import '../../application/providers/painter_providers.dart';
import '../../application/providers/state_providers.dart';
import 'toolbar/tool_button.dart';
import 'new_button_menu.dart';

/// 编辑器顶部工具栏
class EditorToolbar extends ConsumerWidget {
  /// 工具按钮LayerLink
  final LayerLink? newButtonLayerLink;

  /// 缩放按钮Key
  final GlobalKey? zoomButtonKey;

  /// 显示新建按钮菜单的回调
  final VoidCallback? onShowNewButtonMenu;

  /// 隐藏新建按钮菜单的回调
  final VoidCallback? onHideNewButtonMenu;

  /// 显示保存确认对话框的回调
  final VoidCallback? onShowSaveConfirmation;

  /// 保存图像回调
  final VoidCallback? onSaveImage;

  /// 复制到剪贴板回调
  final VoidCallback? onCopyToClipboard;

  /// 导出图像回调
  final VoidCallback? onExportImage;

  /// 撤销操作回调
  final VoidCallback? onUndo;

  /// 重做操作回调
  final VoidCallback? onRedo;

  /// 缩放操作回调
  final VoidCallback? onZoom;

  /// 构造函数
  const EditorToolbar({
    super.key,
    this.newButtonLayerLink,
    this.zoomButtonKey,
    this.onShowNewButtonMenu,
    this.onHideNewButtonMenu,
    this.onShowSaveConfirmation,
    this.onSaveImage,
    this.onCopyToClipboard,
    this.onExportImage,
    this.onUndo,
    this.onRedo,
    this.onZoom,
  });

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

          // New按钮
          if (newButtonLayerLink != null)
            CompositedTransformTarget(
              link: newButtonLayerLink!,
              child: MouseRegion(
                onEnter: (_) => onShowNewButtonMenu?.call(),
                onExit: (_) => onHideNewButtonMenu?.call(),
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

          if (newButtonLayerLink != null) const SizedBox(width: 12),

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
                    PhosphorIcons.palette(PhosphorIconsStyle.light),
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
                    ToolButton(
                      icon: PhosphorIcons.arrowsOut(PhosphorIconsStyle.light),
                      isSelected: currentDrawingMode == DrawingMode.selection,
                      onTap: () =>
                          updateDrawingMode(ref, DrawingMode.selection),
                    ),

                    // 矩形工具
                    ToolButton(
                      icon: PhosphorIcons.square(PhosphorIconsStyle.light),
                      isSelected: currentDrawingMode == DrawingMode.rectangle,
                      onTap: () =>
                          updateDrawingMode(ref, DrawingMode.rectangle),
                    ),

                    // 椭圆工具
                    ToolButton(
                      icon: PhosphorIcons.circle(PhosphorIconsStyle.light),
                      isSelected: currentDrawingMode == DrawingMode.oval,
                      onTap: () => updateDrawingMode(ref, DrawingMode.oval),
                    ),

                    // 箭头工具
                    ToolButton(
                      icon: PhosphorIcons.arrowRight(PhosphorIconsStyle.light),
                      isSelected: currentDrawingMode == DrawingMode.arrow,
                      onTap: () => updateDrawingMode(ref, DrawingMode.arrow),
                    ),

                    // 文本工具
                    ToolButton(
                      icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
                      isSelected: currentDrawingMode == DrawingMode.text,
                      onTap: () => updateDrawingMode(ref, DrawingMode.text),
                    ),

                    // 手绘工具
                    ToolButton(
                      icon:
                          PhosphorIcons.scribbleLoop(PhosphorIconsStyle.light),
                      isSelected: currentDrawingMode == DrawingMode.pen,
                      onTap: () => updateDrawingMode(ref, DrawingMode.pen),
                    ),

                    // 橡皮擦工具
                    ToolButton(
                      icon: PhosphorIcons.eraser(PhosphorIconsStyle.light),
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
                    ToolButton(
                      icon: PhosphorIcons.arrowCounterClockwise(
                          PhosphorIconsStyle.light),
                      isSelected: false,
                      onTap: painterController.canUndo
                          ? (onUndo ?? () => painterController.undo())
                          : null,
                    ),

                    // 重做按钮
                    ToolButton(
                      icon: PhosphorIcons.arrowClockwise(
                          PhosphorIconsStyle.light),
                      isSelected: false,
                      onTap: painterController.canRedo
                          ? (onRedo ?? () => painterController.redo())
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
                    ToolButton(
                      icon: PhosphorIcons.palette(PhosphorIconsStyle.light),
                      isSelected: false,
                      color: ref.watch(strokeColorProvider),
                      onTap: () {
                        ref.read(showColorPickerProvider.notifier).state = true;
                      },
                    ),

                    // 线宽选择按钮
                    ToolButton(
                      icon: PhosphorIcons.lineSegment(PhosphorIconsStyle.light),
                      isSelected: false,
                      onTap: () => _showStrokeWidthDialog(context, ref),
                    ),

                    // 填充开关
                    ToolButton(
                      icon: PhosphorIcons.paintBucket(PhosphorIconsStyle.light),
                      isSelected: ref.watch(isFilledProvider),
                      onTap: () => ref.read(isFilledProvider.notifier).state =
                          !ref.watch(isFilledProvider),
                    ),

                    // 清除所有按钮
                    ToolButton(
                      icon: PhosphorIcons.trash(PhosphorIconsStyle.light),
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
          ToolButton(
            icon: PhosphorIcons.frameCorners(PhosphorIconsStyle.light),
            isSelected: false,
            onTap: () => editorCore.fitContentToViewport(),
          ),

          const SizedBox(width: 2),

          // 缩放按钮
          if (zoomButtonKey != null && onZoom != null)
            ToolButton(
              buttonKey: zoomButtonKey,
              icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
              isSelected: false,
              onTap: onZoom,
            ),

          const SizedBox(width: 2),

          // 保存按钮
          if (onSaveImage != null)
            ToolButton(
              icon: PhosphorIcons.floppyDisk(PhosphorIconsStyle.light),
              isSelected: false,
              onTap: onSaveImage,
            ),

          const SizedBox(width: 2),

          // 复制到剪贴板按钮
          if (onCopyToClipboard != null)
            ToolButton(
              icon: PhosphorIcons.copySimple(PhosphorIconsStyle.light),
              isSelected: false,
              onTap: onCopyToClipboard,
            ),

          const SizedBox(width: 2),

          // 导出按钮
          if (onExportImage != null)
            ToolButton(
              icon: PhosphorIcons.export(PhosphorIconsStyle.light),
              isSelected: false,
              onTap: onExportImage,
            ),
        ],
      ),
    );
  }

  /// 显示线宽选择对话框
  void _showStrokeWidthDialog(BuildContext context, WidgetRef ref) {
    final currentWidth = ref.read(strokeWidthProvider);

    showDialog(
      context: context,
      builder: (context) {
        double selectedWidth = currentWidth;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择线宽'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: selectedWidth,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: selectedWidth.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          selectedWidth = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: selectedWidth,
                      width: 100,
                      decoration: BoxDecoration(
                        color: ref.read(strokeColorProvider),
                        borderRadius: BorderRadius.circular(selectedWidth / 2),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(strokeWidthProvider.notifier).state =
                        selectedWidth;
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 更新绘图模式
  void updateDrawingMode(WidgetRef ref, DrawingMode mode) {
    ref.read(currentDrawingModeProvider.notifier).state = mode;
  }
}
