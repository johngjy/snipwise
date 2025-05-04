import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/responsive_grid.dart';
import '../../../../application/providers/editor_providers.dart';
import '../../../../domain/entities/wallpaper.dart';
import 'wallpaper_grid_item.dart';

/// 壁纸网格组件 - 显示多个可选壁纸
class WallpaperGrid extends ConsumerWidget {
  const WallpaperGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取壁纸列表
    final wallpapers = ref.watch(availableWallpapersProvider);
    final selectedWallpaperId = ref.watch(selectedWallpaperProvider);

    return ResponsiveGrid(
      columnCount: 2,
      spacing: 8,
      runSpacing: 8,
      children: [
        // 遍历每个壁纸创建选项
        for (final wallpaper in wallpapers)
          WallpaperGridItem(
            wallpaper: wallpaper,
            isSelected: wallpaper.id == selectedWallpaperId,
            onTap: () {
              // 选择壁纸
              ref.read(selectedWallpaperProvider.notifier).state = wallpaper.id;
              ref
                  .read(wallpaperSettingsProvider.notifier)
                  .selectWallpaper(wallpaper);
            },
          ),
      ],
    );
  }
}
