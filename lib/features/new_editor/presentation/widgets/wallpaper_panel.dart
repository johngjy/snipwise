import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/core/editor_state_core.dart';
import '../../application/providers/state_providers.dart';
import '../../application/states/wallpaper_state.dart';
import '../../application/providers/wallpaper_providers.dart';
import 'wallpaper_panel/components/setting_slider.dart';

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
                    _buildGradientsGrid(ref, wallpaperState),
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
                    _buildColorGrid(ref, wallpaperState),
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
                    _buildBlurredGrid(ref, wallpaperState),
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

  /// 构建渐变网格
  Widget _buildGradientsGrid(WidgetRef ref, WallpaperState settings) {
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
        final isSelected = settings.type == WallpaperType.gradient &&
            settings.selectedGradientIndex == index;

        return InkWell(
          onTap: () =>
              ref.read(wallpaperProvider.notifier).setGradientPreset(index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradientPresets[index].gradient,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建纯色网格
  Widget _buildColorGrid(WidgetRef ref, WallpaperState settings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: plainColors.length,
      itemBuilder: (context, index) {
        final color = plainColors[index];
        final isSelected = settings.type == WallpaperType.plainColor &&
            settings.backgroundColor == color;

        return InkWell(
          onTap: () =>
              ref.read(wallpaperProvider.notifier).setPlainColor(color),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建模糊背景网格
  Widget _buildBlurredGrid(WidgetRef ref, WallpaperState settings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: blurredBackgrounds.length,
      itemBuilder: (context, index) {
        final blurBg = blurredBackgrounds[index];
        final isSelected = settings.type == WallpaperType.blurred &&
            settings.selectedBlurIndex == index;

        return InkWell(
          onTap: () =>
              ref.read(wallpaperProvider.notifier).setBlurredPreset(index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [blurBg.startColor, blurBg.endColor],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                blurBg.name,
                style: TextStyle(
                  fontSize: 10,
                  color: _contrastColor(blurBg.startColor),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
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

  /// 获取与背景对比的文字颜色
  Color _contrastColor(Color background) {
    // 计算亮度
    final brightness = (0.299 * background.red +
            0.587 * background.green +
            0.114 * background.blue) /
        255;

    // 如果背景较暗，则使用白色文字
    return brightness < 0.5 ? Colors.white : Colors.black;
  }
}
