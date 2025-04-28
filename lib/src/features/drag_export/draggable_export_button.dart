import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../features/editor/services/drag_export/drag_export_adapter.dart';

/// 可拖拽的图像导出按钮组件
///
/// 允许用户通过拖拽操作将当前编辑的图像导出到外部应用程序
/// 支持在 macOS 和 Windows 平台上使用
class DraggableExportButton extends StatefulWidget {
  /// 当前要导出的图像数据
  final Uint8List? imageData;

  /// 按钮大小
  final double size;

  /// 按钮图标大小
  final double iconSize;

  /// 按钮提示文本
  final String tooltip;

  /// 拖拽成功时的回调
  final VoidCallback? onDragSuccess;

  /// 拖拽失败时的回调
  final Function(String message)? onDragError;

  /// 按钮背景色，如果为null则使用主题色
  final Color? backgroundColor;

  /// 按钮图标颜色，如果为null则使用主题色
  final Color? iconColor;

  /// 禁用时的背景色，如果为null则使用主题色
  final Color? disabledBackgroundColor;

  /// 禁用时的图标颜色，如果为null则使用主题色
  final Color? disabledIconColor;

  /// 导出格式，默认为PNG
  final DragExportFormat exportFormat;

  /// JPEG质量，仅当exportFormat为jpg时有效
  final int jpegQuality;

  /// 长按时是否显示格式选择菜单
  final bool showFormatMenu;

  /// 创建一个可拖拽导出按钮
  ///
  /// [imageData] 为空时按钮将被禁用
  const DraggableExportButton({
    super.key,
    required this.imageData,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.tooltip = '拖拽到任意应用',
    this.onDragSuccess,
    this.onDragError,
    this.backgroundColor,
    this.iconColor,
    this.disabledBackgroundColor,
    this.disabledIconColor,
    this.exportFormat = DragExportFormat.png,
    this.jpegQuality = 90,
    this.showFormatMenu = true,
  });

  @override
  State<DraggableExportButton> createState() => _DraggableExportButtonState();
}

class _DraggableExportButtonState extends State<DraggableExportButton>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isProcessing = false;
  late DragExportFormat _currentFormat;

  // 动画控制器，用于处理拖拽开始时的反馈动画
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentFormat = widget.exportFormat;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(DraggableExportButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exportFormat != widget.exportFormat) {
      _currentFormat = widget.exportFormat;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // 根据主题色和传入参数确定各种颜色
    final Color enabledBackground = widget.backgroundColor ??
        (isDarkMode ? Colors.grey[800]! : Colors.white);

    final Color enabledIcon = widget.iconColor ??
        (isDarkMode ? Colors.grey[300]! : const Color(0xFF333333));

    final Color disabledBackground = widget.disabledBackgroundColor ??
        (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!);

    final Color disabledIcon = widget.disabledIconColor ??
        (isDarkMode ? Colors.grey[600]! : Colors.grey[500]!);

    final bool isEnabled = widget.imageData != null &&
        DragExportAdapter.instance.isSupported &&
        !_isProcessing;

    // 格式标签，用于提示
    final String formatLabel =
        _currentFormat == DragExportFormat.png ? 'PNG' : 'JPG';
    final String tooltipWithFormat = '${widget.tooltip} ($formatLabel)';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Tooltip(
            message: !DragExportAdapter.instance.isSupported
                ? '当前平台不支持拖拽导出功能'
                : widget.imageData == null
                    ? '没有可用图像'
                    : _isProcessing
                        ? '正在处理...'
                        : tooltipWithFormat,
            waitDuration: const Duration(milliseconds: 500),
            child: GestureDetector(
              onPanStart: isEnabled ? _handleDragStart : null,
              onPanEnd: isEnabled ? _handleDragEnd : null,
              onPanCancel: isEnabled ? _handleDragCancel : null,
              onLongPress:
                  isEnabled && widget.showFormatMenu ? _showFormatMenu : null,
              child: Stack(
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: isEnabled ? enabledBackground : disabledBackground,
                      borderRadius: BorderRadius.circular(widget.size / 4),
                      boxShadow: isEnabled && _isDragging
                          ? [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withAlpha(80)
                                    : Colors.black.withAlpha(50),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isProcessing
                          ? SizedBox(
                              width: widget.iconSize,
                              height: widget.iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode
                                      ? Colors.grey[300]!
                                      : Colors.grey[600]!,
                                ),
                              ),
                            )
                          : Icon(
                              PhosphorIcons.arrowSquareOut(
                                  PhosphorIconsStyle.light),
                              size: widget.iconSize,
                              color: isEnabled ? enabledIcon : disabledIcon,
                            ),
                    ),
                  ),

                  // 右下角的格式指示器
                  if (isEnabled && widget.showFormatMenu)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: widget.size / 3,
                        height: widget.size / 3,
                        decoration: BoxDecoration(
                          color: _currentFormat == DragExportFormat.png
                              ? Colors.blue.withOpacity(0.8)
                              : Colors.orange.withOpacity(0.8),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(widget.size / 8),
                            bottomRight: Radius.circular(widget.size / 4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _currentFormat == DragExportFormat.png
                                ? 'PNG'
                                : 'JPG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.size / 5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 显示格式选择菜单
  void _showFormatMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);

    final double menuWidth = 120.0;
    final double menuItemHeight = 40.0;

    showMenu<DragExportFormat>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy + widget.size,
        buttonPosition.dx + menuWidth,
        buttonPosition.dy + widget.size + (menuItemHeight * 2),
      ),
      items: [
        PopupMenuItem<DragExportFormat>(
          value: DragExportFormat.png,
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: _currentFormat == DragExportFormat.png
                    ? Colors.blue
                    : Colors.transparent,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('PNG格式'),
            ],
          ),
        ),
        PopupMenuItem<DragExportFormat>(
          value: DragExportFormat.jpg,
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: _currentFormat == DragExportFormat.jpg
                    ? Colors.blue
                    : Colors.transparent,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('JPG格式'),
            ],
          ),
        ),
      ],
    ).then((format) {
      if (format != null && mounted) {
        setState(() {
          _currentFormat = format;
        });
      }
    });
  }

  /// 处理拖拽开始事件
  void _handleDragStart(DragStartDetails details) async {
    if (widget.imageData == null || _isProcessing) return;

    // 开始动画并更新状态
    _animationController.forward();

    setState(() {
      _isDragging = true;
      _isProcessing = true;
    });

    try {
      // 调用适配器来处理图像导出
      final success = await DragExportAdapter.instance.startDrag(
        widget.imageData!,
        details.globalPosition,
        format: _currentFormat,
        jpegQuality: widget.jpegQuality,
      );

      if (mounted) {
        if (success) {
          // 拖拽成功
          widget.onDragSuccess?.call();
        } else {
          // 拖拽失败
          widget.onDragError?.call('拖拽操作启动失败');
        }

        setState(() {
          _isDragging = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      // 错误已在适配器中处理和记录
      if (mounted) {
        widget.onDragError?.call('拖拽操作异常: $e');
        setState(() {
          _isDragging = false;
          _isProcessing = false;
        });
      }
    } finally {
      // 重置动画
      _animationController.reverse();
    }
  }

  /// 处理拖拽结束事件
  void _handleDragEnd(DragEndDetails details) {
    _animationController.reverse();

    if (mounted && _isDragging) {
      setState(() {
        _isDragging = false;
      });
    }
  }

  /// 处理拖拽取消事件
  void _handleDragCancel() {
    _animationController.reverse();

    if (mounted && _isDragging) {
      setState(() {
        _isDragging = false;
      });
    }
  }
}
