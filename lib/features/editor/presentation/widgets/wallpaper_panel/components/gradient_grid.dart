import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/editor_providers.dart';
import '../../../../application/states/wallpaper_settings_state.dart';

/// 渐变预设网格 - 紧凑版本
class GradientGrid extends ConsumerWidget {
  const GradientGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
    final selectedIndex = wallpaperSettings.selectedGradientIndex;

    // 每行展示5个渐变
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
          childAspectRatio: 1.0,
        ),
        itemCount: gradientPresets.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;

          return InkWell(
            onTap: () {
              ref
                  .read(wallpaperSettingsProvider.notifier)
                  .selectGradientPreset(index);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: gradientPresets[index].gradient,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue.shade500 : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
