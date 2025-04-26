import 'package:flutter/material.dart';

/// Mode 悬停菜单中的单个选项项 Widget
class ModeMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前主题颜色
    final primaryColor = Theme.of(context).primaryColor;
    final defaultColor = Colors.grey[700];
    final defaultTextColor = Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 60, // 保持宽度一致
        padding: const EdgeInsets.all(3.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22, // 16px
              color: isSelected ? primaryColor : defaultColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // 10px
                color: isSelected ? primaryColor : defaultTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
