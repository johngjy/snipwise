import 'package:flutter/material.dart';

/// 单个垂直菜单项，用于主捕获界面
class CaptureMenuItem extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标签文本
  final String label;

  /// 点击回调
  final VoidCallback onTap;

  /// 快捷键文本 (如 "⌘2")
  final String? shortcut;

  /// 是否显示右箭头
  final bool showRightArrow;

  /// 是否选中状态
  final bool isSelected;

  const CaptureMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.shortcut,
    this.showRightArrow = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Material(
        color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            width: double.infinity,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.0,
                  color: Colors.black87,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (showRightArrow) ...[
                  const SizedBox(width: 8.0),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14.0,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
