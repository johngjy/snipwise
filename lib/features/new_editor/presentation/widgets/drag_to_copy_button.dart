import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:logger/logger.dart';
import '../../../editor/services/drag_export/drag_export_adapter.dart';

/// 可拖拽复制按钮
///
/// 允许用户通过拖拽操作将图像数据导出到其他应用程序
class DragToCopyButton extends StatelessWidget {
  /// 要导出的图像数据
  final Uint8List? imageData;

  /// 按钮文本标签
  final String label;

  /// 按钮图标
  final IconData? icon;

  /// 按钮文本样式
  final TextStyle? textStyle;

  /// 按钮背景色
  final Color? backgroundColor;

  /// 按钮边框颜色
  final Color? borderColor;

  /// 拖拽成功回调
  final VoidCallback? onDragSuccess;

  /// 拖拽失败回调
  final Function(String)? onDragError;

  /// 点击复制回调
  final VoidCallback? onTap;

  /// 日志记录器
  final Logger _logger = Logger();

  DragToCopyButton({
    Key? key,
    required this.imageData,
    this.label = '拖拽或点击复制',
    this.icon,
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
    this.onDragSuccess,
    this.onDragError,
    this.onTap,
  }) : super(key: key ?? UniqueKey());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final Color bgColor =
        backgroundColor ?? (isDarkMode ? Colors.grey[800]! : Colors.white);

    final Color border = borderColor ??
        (isDarkMode ? Colors.grey[600]! : const Color(0xFFDFDFDF));

    final TextStyle labelStyle = textStyle ??
        TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
        );

    final IconData dragIcon =
        icon ?? PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.light);

    return GestureDetector(
      onPanStart: _handleDragStart,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              Text(
                label,
                style: labelStyle,
              ),
              const SizedBox(width: 10),
              // 点击区域
              InkWell(
                onTap: onTap,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(14)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(13)),
                  ),
                  child: Icon(
                    PhosphorIcons.copy(PhosphorIconsStyle.light),
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理拖拽开始事件
  void _handleDragStart(DragStartDetails details) async {
    if (imageData == null) return;

    try {
      _logger.d('开始拖拽导出');
      final success = await DragExportAdapter.instance.startDrag(
        imageData!,
        details.globalPosition,
      );

      if (success) {
        _logger.d('拖拽导出成功启动');
        onDragSuccess?.call();
      } else {
        _logger.e('拖拽操作启动失败');
        onDragError?.call('拖拽操作启动失败');
      }
    } catch (e) {
      _logger.e('拖拽导出失败: $e');
      onDragError?.call('$e');
    }
  }
}
