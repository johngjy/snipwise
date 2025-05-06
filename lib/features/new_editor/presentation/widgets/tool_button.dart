import 'package:flutter/material.dart';

/// 工具按钮组件
class ToolButton extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback onTap;

  /// 是否选中
  final bool isSelected;

  /// 构造函数
  const ToolButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.blue.shade700 : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
