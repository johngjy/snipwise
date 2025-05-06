import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/core_providers.dart';

/// 颜色选择网格 - 紧凑版本
class ColorGrid extends ConsumerWidget {
  const ColorGrid({super.key});

  // 内置颜色列表 - 顶部行
  static const List<Color> _colors1 = [
    Colors.black,
    Colors.white,
    Color(0xFFE57373), // 红色
    Color(0xFFFF9800), // 橙色
    Color(0xFFFFEB3B), // 黄色
    Color(0xFF4CAF50), // 绿色
    Color(0xFF2196F3), // 蓝色
    Color(0xFF9C27B0), // 紫色
    Colors.transparent, // 彩色选择器图标
  ];

  // 内置颜色列表 - 底部行
  static const List<Color> _colors2 = [
    Color(0xFF616161), // 深灰色
    Color(0xFFF5F5F5), // 浅灰色
    Color(0xFFF8BBD0), // 浅粉色
    Color(0xFFFFCC80), // 浅橙色
    Color(0xFFFFF9C4), // 浅黄色
    Color(0xFFC8E6C9), // 浅绿色
    Color(0xFFBBDEFB), // 浅蓝色
    Color(0xFFE1BEE7), // 浅紫色
    Colors.transparent, // 自定义颜色选择器图标
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
    final backgroundColor = wallpaperSettings.backgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行颜色
          _buildColorRow(context, ref, _colors1, backgroundColor),
          const SizedBox(height: 6),
          // 第二行颜色
          _buildColorRow(context, ref, _colors2, backgroundColor),
        ],
      ),
    );
  }

  Widget _buildColorRow(BuildContext context, WidgetRef ref, List<Color> colors,
      Color selectedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: colors.map((color) {
        // 最后一个透明色作为彩色选择器
        final bool isColorPicker = color == Colors.transparent;
        final bool isSelected =
            !isColorPicker && color.value == selectedColor.value;

        return GestureDetector(
          onTap: () {
            if (isColorPicker) {
              _showColorPicker(context, ref);
            } else {
              ref
                  .read(wallpaperSettingsProvider.notifier)
                  .selectPlainColor(color);
            }
          },
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isColorPicker ? Colors.white : color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? Colors.blue.shade500
                    : (isColorPicker
                        ? Colors.grey.shade300
                        : color == Colors.white
                            ? Colors.grey.shade300
                            : Colors.transparent),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isColorPicker
                ? const Icon(Icons.colorize, size: 16, color: Colors.grey)
                : (isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null),
          ),
        );
      }).toList(),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    // 简化实现，实际可以调用更复杂的颜色选择器
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('高级颜色选择器待实现'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
