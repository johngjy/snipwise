import 'package:flutter/material.dart';

/// 延迟捕获菜单 Widget
class DelayMenu extends StatelessWidget {
  final Function(int) onDelaySelected;

  const DelayMenu({super.key, required this.onDelaySelected});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(context, 'No delay', 0),
            _buildMenuItem(context, '3 seconds', 3),
            _buildMenuItem(context, '5 seconds', 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String label, int delay) {
    return InkWell(
      onTap: () => onDelaySelected(delay),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}
