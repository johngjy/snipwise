import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../domain/models/tool_type.dart';

/// 编辑器工具栏 - 提供绘图工具选择和操作按钮
class EditorToolbar extends StatelessWidget {
  // 工具栏模式
  final EditorToolbarMode _mode;

  // 基础工具栏参数 - 绘图模式
  final ToolType? selectedTool;
  final bool? canUndo;
  final bool? canRedo;
  final bool? hasUnsavedChanges;
  final void Function(ToolType)? onToolSelected;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onClearAll;
  final VoidCallback? onShowTextCache;
  final VoidCallback? onExportImage;

  // 截图编辑模式工具栏参数
  final VoidCallback? onShowSaveConfirmation;
  final VoidCallback? onShowNewButtonMenu;
  final VoidCallback? onSave;
  final VoidCallback? onShowZoomMenu;
  final LayerLink? toolbarKey;
  final GlobalKey? zoomKey;
  final VoidCallback? onShowCachedText;

  /// 绘图工具栏构造函数
  const EditorToolbar({
    Key? key,
    required ToolType selectedTool,
    required bool canUndo,
    required bool canRedo,
    required bool hasUnsavedChanges,
    required void Function(ToolType) onToolSelected,
    required VoidCallback onUndo,
    required VoidCallback onRedo,
    required VoidCallback onClearAll,
    required VoidCallback onShowTextCache,
    required VoidCallback onExportImage,
  })  : _mode = EditorToolbarMode.painting,
        selectedTool = selectedTool,
        canUndo = canUndo,
        canRedo = canRedo,
        hasUnsavedChanges = hasUnsavedChanges,
        onToolSelected = onToolSelected,
        onUndo = onUndo,
        onRedo = onRedo,
        onClearAll = onClearAll,
        onShowTextCache = onShowTextCache,
        onExportImage = onExportImage,
        onShowSaveConfirmation = null,
        onShowNewButtonMenu = null,
        onSave = null,
        onShowZoomMenu = null,
        toolbarKey = null,
        zoomKey = null,
        onShowCachedText = null,
        super(key: key);

  /// 截图编辑工具栏构造函数
  const EditorToolbar.screenshot({
    Key? key,
    required VoidCallback onShowSaveConfirmation,
    required VoidCallback onShowNewButtonMenu,
    required VoidCallback onSave,
    required VoidCallback onShowZoomMenu,
    required LayerLink toolbarKey,
    required GlobalKey zoomKey,
    VoidCallback? onShowCachedText,
  })  : _mode = EditorToolbarMode.screenshot,
        selectedTool = null,
        canUndo = null,
        canRedo = null,
        hasUnsavedChanges = null,
        onToolSelected = null,
        onUndo = null,
        onRedo = null,
        onClearAll = null,
        onShowTextCache = null,
        onExportImage = null,
        onShowSaveConfirmation = onShowSaveConfirmation,
        onShowNewButtonMenu = onShowNewButtonMenu,
        onSave = onSave,
        onShowZoomMenu = onShowZoomMenu,
        toolbarKey = toolbarKey,
        zoomKey = zoomKey,
        onShowCachedText = onShowCachedText,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据模式构建不同的工具栏
    return _mode == EditorToolbarMode.painting
        ? _buildPaintingToolbar(context)
        : _buildScreenshotToolbar(context);
  }

  /// 构建绘图模式工具栏
  Widget _buildPaintingToolbar(BuildContext context) {
    // 使用 macOS 风格的设计
    return Container(
      height: 48,
      color: CupertinoTheme.of(context).barBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 绘图工具组
          _buildToolGroup(context),

          const SizedBox(width: 16),

          // 分隔线
          Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),

          const SizedBox(width: 16),

          // 操作按钮组
          _buildActionGroup(context),

          const Spacer(),

          // 右侧按钮组
          _buildRightGroup(context),
        ],
      ),
    );
  }

  /// 构建截图编辑模式工具栏
  Widget _buildScreenshotToolbar(BuildContext context) {
    // 这里可以使用实际的截图工具栏实现
    // 暂时返回一个简单的样式
    return Container(
      height: 48,
      color: CupertinoTheme.of(context).barBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 左侧按钮组
          Row(
            children: [
              // 新建按钮
              CompositedTransformTarget(
                link: toolbarKey!,
                child: _buildScreenshotActionButton(
                    context, CupertinoIcons.add, '新建截图', onShowNewButtonMenu!),
              ),

              // 保存按钮
              _buildScreenshotActionButton(
                  context, CupertinoIcons.floppy_disk, '保存截图', onSave!),
            ],
          ),

          const Spacer(),

          // 右侧按钮组
          Row(
            children: [
              // 显示缓存文本按钮（如果有回调）
              if (onShowCachedText != null)
                _buildScreenshotActionButton(context,
                    CupertinoIcons.text_alignleft, '显示文本缓存', onShowCachedText!),

              // 缩放按钮
              SizedBox(
                key: zoomKey,
                child: _buildScreenshotActionButton(
                    context, CupertinoIcons.zoom_in, '缩放', onShowZoomMenu!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建工具按钮组
  Widget _buildToolGroup(BuildContext context) {
    return Row(
      children: [
        _buildToolButton(
          context,
          ToolType.select,
          CupertinoIcons.arrow_uturn_right,
          '选择工具',
        ),
        _buildToolButton(
          context,
          ToolType.rectangle,
          CupertinoIcons.rectangle,
          '矩形工具',
        ),
        _buildToolButton(
          context,
          ToolType.arrow,
          CupertinoIcons.arrow_right,
          '箭头工具',
        ),
        _buildToolButton(
          context,
          ToolType.freedraw,
          CupertinoIcons.pencil,
          '自由绘图工具',
        ),
        _buildToolButton(
          context,
          ToolType.text,
          CupertinoIcons.text_badge_plus,
          '文本工具',
        ),
      ],
    );
  }

  /// 构建操作按钮组
  Widget _buildActionGroup(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          context,
          CupertinoIcons.arrow_counterclockwise,
          '撤销',
          onUndo!,
          enabled: canUndo!,
        ),
        _buildActionButton(
          context,
          CupertinoIcons.arrow_clockwise,
          '重做',
          onRedo!,
          enabled: canRedo!,
        ),
        _buildActionButton(
          context,
          CupertinoIcons.trash,
          '清除所有标注',
          onClearAll!,
        ),
      ],
    );
  }

  /// 构建右侧按钮组
  Widget _buildRightGroup(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          context,
          CupertinoIcons.text_alignleft,
          '显示文本',
          onShowTextCache!,
        ),
        _buildActionButton(
          context,
          CupertinoIcons.share,
          '导出图片',
          onExportImage!,
        ),
      ],
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton(
    BuildContext context,
    ToolType type,
    IconData icon,
    String tooltip,
  ) {
    final isSelected = selectedTool == type;

    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: () => onToolSelected!(type),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.activeBlue.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.inactiveGray,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: enabled ? onPressed : null,
        child: Icon(
          icon,
          color: enabled
              ? CupertinoColors.activeBlue
              : CupertinoColors.inactiveGray,
          size: 20,
        ),
      ),
    );
  }

  /// 构建截图模式的操作按钮
  Widget _buildScreenshotActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        child: Icon(
          icon,
          color: CupertinoColors.activeBlue,
          size: 20,
        ),
      ),
    );
  }
}

/// 工具栏模式枚举
enum EditorToolbarMode {
  /// 绘图模式
  painting,

  /// 截图编辑模式
  screenshot,
}
