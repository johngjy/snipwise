import 'package:flutter/material.dart';

/// 工具栏按钮组件
class ToolButton extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 提示文本
  final String tooltip;

  /// 点击回调
  final VoidCallback onPressed;

  /// 是否激活
  final bool isActive;

  /// 按钮尺寸
  final double size;

  /// 按钮颜色
  final Color? color;

  /// 激活颜色
  final Color activeColor;

  /// 构造函数
  const ToolButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.size = 20,
    this.color,
    this.activeColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: size),
        color: isActive ? activeColor : (color ?? Colors.black87),
        onPressed: onPressed,
        splashRadius: 20,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
