import 'package:flutter/material.dart';

/// 操作按钮组件
///
/// 用于底部工具栏的操作按钮
class ActionButton extends StatelessWidget {
  /// 按钮图标（支持 IconData 或自定义 Widget）
  final dynamic icon;

  /// 点击回调
  final VoidCallback onTap;

  /// 按钮大小（可选）
  final double size;

  /// 图标大小（可选）
  final double iconSize;

  /// 自定义背景色（可选）
  final Color? backgroundColor;

  /// 自定义边框颜色（可选）
  final Color? borderColor;

  /// 自定义图标颜色（可选）
  final Color? iconColor;

  /// 工具提示文本（可选）
  final String? tooltip;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 30,
    this.iconSize = 16,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor ?? const Color(0xFFDFDFDF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 0.5,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: IconButton(
        icon: icon is IconData
            ? Icon(icon,
                size: iconSize, color: iconColor ?? const Color(0xFF555555))
            : icon,
        onPressed: onTap,
        padding: const EdgeInsets.all(5),
        constraints: BoxConstraints(minWidth: size, minHeight: size - 4),
        iconSize: iconSize,
        splashRadius: iconSize,
      ),
    );

    // 如果提供了tooltip，则包装在Tooltip中
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
