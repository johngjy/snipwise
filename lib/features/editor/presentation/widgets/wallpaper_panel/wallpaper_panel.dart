import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../application/providers/editor_providers.dart';
import '../../../application/states/wallpaper_settings_state.dart';
import 'components/setting_slider.dart';

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

  /// 构建渐变网格 - 减小尺寸和间距
  Widget _buildGradientsGrid(WidgetRef ref, WallpaperSettingsState settings) {
    final selectedIndex = settings.selectedGradientIndex;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(
        15, // 减少显示的渐变数量
        (index) {
          final isSelected = selectedIndex == index;

          // 创建渐变 - 使用预设或随机生成
          final gradient = index < gradientPresets.length
              ? gradientPresets[index].gradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(
                        255, 100 + index * 7, 50 + index * 3, 150 - index * 5),
                    Color.fromARGB(
                        255, 150 - index * 3, 100 + index * 5, 200 - index * 2),
                  ],
                );

          return GestureDetector(
            onTap: () {
              if (index < gradientPresets.length) {
                ref.read(wallpaperSettingsProvider.notifier)
                  ..setWallpaperType(WallpaperType.gradient)
                  ..selectGradientPreset(index);
              }
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
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

  /// 构建模糊效果网格 - 减小尺寸和间距
  Widget _buildBlurredGrid(WidgetRef ref, WallpaperSettingsState settings) {
    final selectedIndex = settings.selectedBlurIndex;

    return Row(
      children: [
        // 模糊森林
        GestureDetector(
          onTap: () {
            ref.read(wallpaperSettingsProvider.notifier)
              ..setWallpaperType(WallpaperType.blurred)
              ..selectBlurredPreset(0);
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
              color: Colors.brown.shade300, // 使用颜色替代无法加载的图片
            ),
            child: Icon(PhosphorIcons.treeStructure(PhosphorIconsStyle.light),
                size: 18, color: Colors.white70),
          ),
        ),
        const SizedBox(width: 8),

        // 白色模糊
        GestureDetector(
          onTap: () {
            ref.read(wallpaperSettingsProvider.notifier)
              ..setWallpaperType(WallpaperType.blurred)
              ..selectBlurredPreset(1);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selectedIndex == 1 ? Colors.blue : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 灰色模糊
        GestureDetector(
          onTap: () {
            ref.read(wallpaperSettingsProvider.notifier)
              ..setWallpaperType(WallpaperType.blurred)
              ..selectBlurredPreset(2);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selectedIndex == 2 ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建颜色网格 - 减小尺寸和间距
  Widget _buildColorGrid(WidgetRef ref, WallpaperSettingsState settings) {
    final currentColor = settings.backgroundColor;

    // 常用颜色列表 - 第一行
    final List<Color> colors1 = [
      Colors.black,
      Colors.white,
      const Color(0xFFE57373), // 红色
      const Color(0xFFFF9800), // 橙色
      const Color(0xFFFFEB3B), // 黄色
      const Color(0xFF4CAF50), // 绿色
      const Color(0xFF2196F3), // 蓝色
      const Color(0xFF9C27B0), // 紫色
    ];

    // 常用颜色列表 - 第二行
    final List<Color> colors2 = [
      const Color(0xFF616161), // 深灰色
      const Color(0xFFEEEEEE), // 浅灰色
      const Color(0xFFF8BBD0), // 浅粉色
      const Color(0xFFFFCC80), // 浅橙色
      const Color(0xFFFFF9C4), // 浅黄色
      const Color(0xFFC8E6C9), // 浅绿色
      const Color(0xFFBBDEFB), // 浅蓝色
      Colors.transparent, // 自定义颜色
    ];

    return Column(
      children: [
        // 第一行颜色
        Row(
          children: colors1.map((color) {
            final bool isSelected = color.value == currentColor.value;

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  ref.read(wallpaperSettingsProvider.notifier)
                    ..setWallpaperType(WallpaperType.plainColor)
                    ..selectPlainColor(color);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : (color == Colors.white
                              ? Colors.grey.shade300
                              : Colors.transparent),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // 第二行颜色
        Row(
          children: colors2.map((color) {
            final bool isColorPicker = color == Colors.transparent;
            final bool isSelected =
                !isColorPicker && color.value == currentColor.value;

            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  if (!isColorPicker) {
                    ref.read(wallpaperSettingsProvider.notifier)
                      ..setWallpaperType(WallpaperType.plainColor)
                      ..selectPlainColor(color);
                  } else {
                    // 颜色选择器逻辑
                  }
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isColorPicker ? Colors.white : color,
                    borderRadius: BorderRadius.circular(isColorPicker ? 4 : 10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : (isColorPicker ||
                                  color == Colors.white ||
                                  color == const Color(0xFFEEEEEE)
                              ? Colors.grey.shade300
                              : Colors.transparent),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isColorPicker
                      ? Icon(Icons.palette,
                          size: 14, color: Colors.grey.shade400)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
