import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/wallpaper_providers.dart';
import '../../../../application/states/wallpaper_state.dart';

/// 颜色网格组件
/// 显示常用颜色选项，用于壁纸面板纯色背景选择
class ColorGrid extends ConsumerWidget {
  const ColorGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperState = ref.watch(wallpaperProvider);
    final currentColor = wallpaperState.backgroundColor;

    // 颜色列表 - 第一行
    final List<Color> colors1 = [
      Colors.black,
      Colors.white,
      const Color(0xFFE57373), // 红色
      const Color(0xFFFF9800), // 橙色
      const Color(0xFFFFEB3B), // 黄色
      const Color(0xFF4CAF50), // 绿色
    ];

    // 颜色列表 - 第二行
    final List<Color> colors2 = [
      const Color(0xFF2196F3), // 蓝色
      const Color(0xFF9C27B0), // 紫色
      const Color(0xFF616161), // 深灰色
      const Color(0xFFEEEEEE), // 浅灰色
      const Color(0xFFF8BBD0), // 浅粉色
      const Color(0xFFBBDEFB), // 浅蓝色
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一行颜色
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildColorRow(ref, colors1, currentColor),
        ),
        const SizedBox(height: 8),

        // 第二行颜色
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildColorRow(ref, colors2, currentColor),
        ),
      ],
    );
  }

  // 构建颜色行
  List<Widget> _buildColorRow(
      WidgetRef ref, List<Color> colors, Color currentColor) {
    return colors.map((color) {
      final isSelected = color.value == currentColor.value &&
          ref.read(wallpaperProvider).type == WallpaperType.plainColor;
      final needsBorder =
          color == Colors.white || color == const Color(0xFFEEEEEE);

      return GestureDetector(
        onTap: () => ref.read(wallpaperProvider.notifier).setPlainColor(color),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : (needsBorder ? Colors.grey.shade300 : Colors.transparent),
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      );
    }).toList();
  }
}
