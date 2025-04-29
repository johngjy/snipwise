import 'package:flutter/material.dart';

/// 工具按钮组件
///
/// 用于编辑器工具栏中的工具选择按钮
class ToolButton extends StatelessWidget {
  /// 按钮图标（支持 IconData 或自定义 Widget）
  final dynamic icon;

  /// 是否被选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  /// 自定义颜色（可选）
  final Color? color;

  /// 按钮的 Key（可选）
  final Key? buttonKey;

  const ToolButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? Colors.grey[200] : Colors.transparent,
        ),
        child: icon is IconData
            ? Icon(
                icon,
                size: 18,
                color: color ?? (isSelected ? Colors.black : Colors.grey[600]),
              )
            : icon, // 支持传入自定义 Widget
      ),
    );
  }
}
