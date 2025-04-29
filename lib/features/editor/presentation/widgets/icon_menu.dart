import 'package:flutter/material.dart';

/// 图标菜单项
class IconMenuItem {
  /// 标题
  final String title;

  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback onTap;

  IconMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// 图标菜单
class IconMenu extends StatelessWidget {
  /// 菜单项
  final List<IconMenuItem> items;

  /// 标题
  final String? title;

  const IconMenu({
    super.key,
    required this.items,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ...items.map((item) => _buildMenuItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconMenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: Colors.black87,
            ),
            const SizedBox(width: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
