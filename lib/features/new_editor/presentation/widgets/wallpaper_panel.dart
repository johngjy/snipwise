import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/state_providers.dart';
import '../../application/states/wallpaper_state.dart';
import '../../application/providers/wallpaper_providers.dart';
import 'wallpaper_panel/components/setting_slider.dart';
import 'wallpaper_panel/components/color_grid.dart';
import 'wallpaper_panel/components/gradient_grid.dart';
import 'wallpaper_panel/components/blurred_grid.dart';

/// 壁纸设置面板
/// 用于控制壁纸类型、颜色、渐变、模糊背景等设置
class WallpaperPanel extends ConsumerWidget {
  const WallpaperPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperState = ref.watch(wallpaperProvider);

    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '壁纸设置',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                // 关闭按钮
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ref.read(wallpaperPanelVisibleProvider.notifier).state =
                        false;
                  },
                ),
              ],
            ),
          ),

          // 主内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "None" 选项
                    _buildNoneOption(ref, wallpaperState),
                    const SizedBox(height: 12),

                    // 类型选择区域
                    const Text(
                      '壁纸类型',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 渐变背景选项
                    const Text(
                      '渐变',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const GradientGrid(),
                    const SizedBox(height: 12),

                    // 纯色背景选项
                    const Text(
                      '纯色',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const ColorGrid(),
                    const SizedBox(height: 12),

                    // 模糊背景选项
                    const Text(
                      '模糊背景',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const BlurredGrid(),
                    const SizedBox(height: 16),

                    // 分隔线
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),

                    // 设置项
                    _buildSettingsArea(ref, wallpaperState),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建None选项
  Widget _buildNoneOption(WidgetRef ref, WallpaperState settings) {
    final isSelected = settings.type == WallpaperType.none;

    return InkWell(
      onTap: () => ref
          .read(wallpaperProvider.notifier)
          .setWallpaperType(WallpaperType.none),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '无背景',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建设置区域
  Widget _buildSettingsArea(WidgetRef ref, WallpaperState settings) {
    // 如果类型为none，不显示设置
    if (settings.type == WallpaperType.none) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '样式设置',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),

        // 边距设置
        SettingSlider(
          title: '内边距',
          value: settings.padding,
          min: 0,
          max: 40,
          divisions: 20,
          onChanged: (value) {
            ref.read(wallpaperProvider.notifier).setPadding(value);
          },
        ),

        // 内凹边距设置
        SettingSlider(
          title: '内凹边距',
          value: settings.inset,
          min: 0,
          max: 20,
          divisions: 20,
          onChanged: (value) {
            ref.read(wallpaperProvider.notifier).setInset(value);
          },
        ),

        // 圆角设置
        SettingSlider(
          title: '圆角',
          value: settings.cornerRadius,
          min: 0,
          max: 20,
          divisions: 20,
          onChanged: (value) {
            ref.read(wallpaperProvider.notifier).setCornerRadius(value);
          },
        ),

        // 阴影设置
        SettingSlider(
          title: '阴影',
          value: settings.shadowRadius,
          min: 0,
          max: 20,
          divisions: 20,
          onChanged: (value) {
            ref.read(wallpaperProvider.notifier).setShadowRadius(value);
          },
        ),

        // 自动平衡开关
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '自动平衡',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555),
              ),
            ),
            Switch.adaptive(
              value: settings.autoBalance,
              onChanged: (value) {
                ref.read(wallpaperProvider.notifier).setAutoBalance(value);
              },
              activeColor: Colors.blue.shade400,
            ),
          ],
        ),
      ],
    );
  }
}
