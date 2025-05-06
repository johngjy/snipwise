import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../application/providers/wallpaper_providers.dart';
import '../../../../application/states/wallpaper_state.dart';

/// 渐变网格组件
/// 显示预设渐变选项，用于壁纸面板渐变背景选择
class GradientGrid extends ConsumerWidget {
  const GradientGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperState = ref.watch(wallpaperProvider);
    final selectedIndex = wallpaperState.selectedGradientIndex;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: gradientPresets.length,
      itemBuilder: (context, index) {
        final isSelected = wallpaperState.type == WallpaperType.gradient &&
            selectedIndex == index;

        return GestureDetector(
          onTap: () =>
              ref.read(wallpaperProvider.notifier).setGradientPreset(index),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradientPresets[index].gradient,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
          ),
        );
      },
    );
  }
}
