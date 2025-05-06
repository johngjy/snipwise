import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../application/providers/wallpaper_providers.dart';
import '../../../../application/states/wallpaper_state.dart';

/// 模糊效果网格组件
/// 显示模糊背景选项，用于壁纸面板模糊背景选择
class BlurredGrid extends ConsumerWidget {
  const BlurredGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperState = ref.watch(wallpaperProvider);
    final selectedIndex = wallpaperState.selectedBlurIndex;

    // 模糊背景选项列表
    return Row(
      children: [
        // 模糊森林
        _buildBlurOption(
          ref,
          0,
          selectedIndex,
          Colors.brown.shade300,
          PhosphorIcons.treeStructure(PhosphorIconsStyle.light),
        ),
        const SizedBox(width: 12),

        // 白色模糊
        _buildBlurOption(
          ref,
          1,
          selectedIndex,
          Colors.white,
          null,
          borderColor: Colors.grey.shade300,
        ),
        const SizedBox(width: 12),

        // 灰色模糊
        _buildBlurOption(
          ref,
          2,
          selectedIndex,
          Colors.grey.shade300,
          null,
        ),
      ],
    );
  }

  // 构建模糊背景选项
  Widget _buildBlurOption(
    WidgetRef ref,
    int index,
    int? selectedIndex,
    Color backgroundColor,
    IconData? icon, {
    Color? borderColor,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => ref.read(wallpaperProvider.notifier).setBlurredPreset(index),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? Colors.blue : (borderColor ?? Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 20,
                color: Colors.white.withOpacity(0.8),
              )
            : null,
      ),
    );
  }
}
