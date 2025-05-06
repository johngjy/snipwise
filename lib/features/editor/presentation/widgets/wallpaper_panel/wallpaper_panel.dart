import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../application/providers/core_providers.dart';
import '../../../application/states/wallpaper_settings_state.dart';
import 'components/setting_slider.dart';
import 'components/color_grid.dart';
import 'components/gradient_grid.dart';
import 'components/blurred_grid.dart';

/// Wallpaper设置面板 - 紧凑型高效布局设计
class WallpaperPanel extends ConsumerWidget {
  const WallpaperPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);

    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 预设选择下拉标题 - 压缩高度
          _buildPresetHeader(),

          // 主内容区域 - 无需滚动
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "None" 选项 - 减小高度
                  _buildNoneOption(ref, wallpaperSettings),

                  // 类型选择区域
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gradients 部分
                        Row(
                          children: [
                            const Text(
                              'Gradients',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  'Show less',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  PhosphorIcons.caretUp(
                                      PhosphorIconsStyle.light),
                                  size: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildGradientsGrid(ref, wallpaperSettings),

                        // Wallpapers 部分
                        const SizedBox(height: 8),
                        const Text(
                          'Wallpapers',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildWallpapersGrid(ref, wallpaperSettings),

                        // Blurred 部分
                        const SizedBox(height: 8),
                        const Text(
                          'Blurred',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildBlurredGrid(ref, wallpaperSettings),

                        // Plain color 部分
                        const SizedBox(height: 8),
                        const Text(
                          'Plain color',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildColorGrid(ref, wallpaperSettings),
                      ],
                    ),
                  ),

                  // 分隔线
                  const Divider(height: 16, thickness: 0.5),

                  // 设置项 - 紧凑布局
                  _buildSettingsArea(ref, wallpaperSettings),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建预设标题行 - 减小高度
  Widget _buildPresetHeader() {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          const Text(
            'Presets...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
          const Spacer(),
          Icon(
            PhosphorIcons.caretDown(PhosphorIconsStyle.light),
            size: 12,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Center(
              child: Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.light),
                size: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建None选项 - 减小高度
  Widget _buildNoneOption(WidgetRef ref, WallpaperSettingsState settings) {
    final isSelected = settings.type == WallpaperType.none;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: InkWell(
        onTap: () => ref
            .read(wallpaperSettingsProvider.notifier)
            .setWallpaperType(WallpaperType.none),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'None',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建渐变背景网格
  Widget _buildGradientsGrid(WidgetRef ref, WallpaperSettingsState settings) {
    return const GradientGrid();
  }

  /// 构建壁纸网格 - 减小尺寸
  Widget _buildWallpapersGrid(WidgetRef ref, WallpaperSettingsState settings) {
    final selectedIndex = settings.selectedWallpaperIndex;

    return Row(
      children: [
        // 森林壁纸
        GestureDetector(
          onTap: () {
            ref.read(wallpaperSettingsProvider.notifier)
              ..setWallpaperType(WallpaperType.wallpaper)
              ..selectWallpaperPreset(0);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selectedIndex == 0 ? Colors.blue : Colors.transparent,
                width: 2,
              ),
              color: Colors.brown.shade800, // 使用颜色替代无法加载的图片
            ),
            child: Icon(PhosphorIcons.tree(PhosphorIconsStyle.light),
                size: 18, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),

        // 添加新壁纸按钮
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.plus(PhosphorIconsStyle.light),
              size: 18,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建模糊背景网格
  Widget _buildBlurredGrid(WidgetRef ref, WallpaperSettingsState settings) {
    return const BlurredGrid();
  }

  /// 构建颜色网格
  Widget _buildColorGrid(WidgetRef ref, WallpaperSettingsState settings) {
    return const ColorGrid();
  }

  /// 构建所有设置区域 - 紧凑布局
  Widget _buildSettingsArea(WidgetRef ref, WallpaperSettingsState settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Padding 设置
          _buildCompactSetting(
            'Padding',
            SettingSlider(
              value: settings.padding,
              min: 0,
              max: 100,
              onChanged: (value) => ref
                  .read(wallpaperSettingsProvider.notifier)
                  .setPadding(value),
            ),
          ),

          // Inset 和 Auto-balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inset 左侧部分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inset',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SettingSlider(
                      value: settings.inset,
                      min: 0,
                      max: 50,
                      onChanged: (value) => ref
                          .read(wallpaperSettingsProvider.notifier)
                          .setInset(value),
                    ),
                  ],
                ),
              ),

              // Auto-balance 右侧部分
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: Checkbox(
                        value: settings.autoBalance,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) => ref
                            .read(wallpaperSettingsProvider.notifier)
                            .setAutoBalance(value ?? false),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'Auto-balance',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Shadow & Corners 部分
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shadow
              Expanded(
                child: _buildCompactSetting(
                  'Shadow',
                  SettingSlider(
                    value: settings.shadowRadius,
                    min: 0,
                    max: 50,
                    onChanged: (value) => ref
                        .read(wallpaperSettingsProvider.notifier)
                        .setShadowRadius(value),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Corners
              Expanded(
                child: _buildCompactSetting(
                  'Corners',
                  SettingSlider(
                    value: settings.cornerRadius,
                    min: 0,
                    max: 50,
                    onChanged: (value) => ref
                        .read(wallpaperSettingsProvider.notifier)
                        .setCornerRadius(value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建紧凑型设置项
  Widget _buildCompactSetting(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 2),
        child,
        const SizedBox(height: 6),
      ],
    );
  }
}
