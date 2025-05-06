import 'package:flutter/material.dart';

/// 悬停菜单项模型
class HoverMenuItem {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final Widget? customIcon;

  const HoverMenuItem({
    this.icon,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.customIcon,
  });
}

/// 悬停菜单 Widget
class HoverMenu extends StatelessWidget {
  final List<HoverMenuItem> items;
  final Color backgroundColor;
  final double iconSize;
  final double fontSize;

  const HoverMenu({
    super.key,
    required this.items,
    this.backgroundColor = Colors.white,
    this.iconSize = 16.0,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) => _buildMenuItem(context, item)).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, HoverMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (item.onTap != null) {
              item.onTap!();
            }
          });
        },
        hoverColor: const Color(0xFFF0F0F0),
        splashColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color:
                item.isSelected ? const Color(0xFFF5F5F5) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (item.customIcon != null)
                item.customIcon!
              else if (item.icon != null)
                Icon(
                  item.icon,
                  size: iconSize,
                  color: item.isSelected ? Colors.blue : Colors.grey[600],
                ),
              if (item.icon != null || item.customIcon != null)
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: item.isSelected ? Colors.blue : Colors.grey[800],
                    fontWeight:
                        item.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
