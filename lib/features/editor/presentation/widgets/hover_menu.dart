import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart'; // Unused import removed

/// 悬停菜单项模型
class HoverMenuItem {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;

  // Add const constructor
  const HoverMenuItem({
    this.icon,
    required this.label,
    this.onTap,
    this.isSelected = false,
  });
}

/// 悬停菜单 Widget
class HoverMenu extends StatelessWidget {
  final List<HoverMenuItem> items;
  final Color backgroundColor;
  final double iconSize;
  final double fontSize;

  // Use super parameters
  const HoverMenu({
    super.key, // Use super key
    required this.items,
    this.backgroundColor = Colors.white,
    this.iconSize = 16.0,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      color: backgroundColor,
      shadowColor: Colors.black
          .withAlpha((0.1 * 255).round()), // Replace deprecated withOpacity
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        width: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) => _buildMenuItem(context, item)).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, HoverMenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: item.isSelected ? const Color(0xFFF5F5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (item.icon != null)
              Icon(
                item.icon,
                size: iconSize,
                color: item.isSelected ? Colors.blue : Colors.grey[600],
              ),
            if (item.icon != null) const SizedBox(width: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: fontSize,
                color: item.isSelected ? Colors.blue : Colors.grey[800],
                fontWeight:
                    item.isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
