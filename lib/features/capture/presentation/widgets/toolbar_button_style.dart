import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// 封装工具栏按钮的通用样式和构建逻辑
class ToolbarButtonStyle {
  static Widget build({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool showDropdown = false,
  }) {
    EdgeInsets itemPadding;
    double iconSize;
    double fontSize;

    // 根据标签应用不同样式 (和原 Toolbar 逻辑一致)
    if (label == 'New') {
      itemPadding = EdgeInsets.symmetric(
          horizontal: 8, vertical: Platform.isMacOS ? 5 : 3);
      iconSize = 23;
      fontSize = 15.0;
    } else {
      itemPadding = EdgeInsets.symmetric(
          horizontal: Platform.isMacOS ? 8 : 5,
          vertical: Platform.isMacOS ? 3 : 2);
      iconSize = 20;
      fontSize = 13.0;
    }

    final Widget buttonContent = Container(
      padding: itemPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: const Color(0xFF616161),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF616161),
            ),
          ),
          if (showDropdown) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: buttonContent,
      ),
    );
  }
}
