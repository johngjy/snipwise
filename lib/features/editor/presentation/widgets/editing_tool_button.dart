import 'package:flutter/material.dart';

/// 编辑工具栏中的单个按钮 Widget
class EditingToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const EditingToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: isSelected ? Colors.blue : Colors.grey.shade700,
        splashRadius: 20,
        iconSize: 22,
        padding: const EdgeInsets.all(8),
        visualDensity: VisualDensity.compact,
        tooltip: tooltip, // Keep tooltip for accessibility if needed
        style: ButtonStyle(
          // Match style from original _buildEditingToolButton
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
