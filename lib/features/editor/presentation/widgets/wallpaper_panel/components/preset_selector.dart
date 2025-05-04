import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../application/providers/editor_providers.dart';
import '../../../../application/states/wallpaper_settings_state.dart';

/// 预设选择器组件 - 选择不同类型的预设
class PresetSelector extends ConsumerWidget {
  PresetSelector({Key? key}) : super(key: key);

  /// 预设类型选项列表
  final List<_PresetTypeOption> _presetOptions = [
    _PresetTypeOption(
      label: 'None',
      type: WallpaperType.none,
      icon: PhosphorIcons.x(PhosphorIconsStyle.light),
    ),
    _PresetTypeOption(
      label: 'Gradients',
      type: WallpaperType.gradient,
      icon: PhosphorIcons.gradient(PhosphorIconsStyle.light),
    ),
    _PresetTypeOption(
      label: 'Wallpapers',
      type: WallpaperType.wallpaper,
      icon: PhosphorIcons.image(PhosphorIconsStyle.light),
    ),
    _PresetTypeOption(
      label: 'Blurred',
      type: WallpaperType.blurred,
      icon: PhosphorIcons.sparkle(PhosphorIconsStyle.light),
    ),
    _PresetTypeOption(
      label: 'Plain color',
      type: WallpaperType.plainColor,
      icon: PhosphorIcons.paintBucket(PhosphorIconsStyle.light),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
    final currentType = wallpaperSettings.type;

    // 当前选中的预设类型
    final selectedOption = _presetOptions.firstWhere(
      (option) => option.type == currentType,
      orElse: () => _presetOptions.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和下拉菜单
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildDropdown(ref, selectedOption),
              ),
              const SizedBox(width: 8),
              _buildAddButton(),
            ],
          ),
        ),

        // 如果当前类型不是None，显示"None"快速选项
        if (currentType != WallpaperType.none)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => ref
                  .read(wallpaperSettingsProvider.notifier)
                  .setWallpaperType(WallpaperType.none),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'None',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建预设类型下拉菜单
  Widget _buildDropdown(WidgetRef ref, _PresetTypeOption selectedOption) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WallpaperType>(
          value: selectedOption.type,
          isExpanded: true,
          icon: Icon(
            PhosphorIcons.caretDown(PhosphorIconsStyle.light),
            size: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(8),
          onChanged: (WallpaperType? newType) {
            if (newType != null) {
              ref
                  .read(wallpaperSettingsProvider.notifier)
                  .setWallpaperType(newType);
            }
          },
          items: _presetOptions.map((option) {
            return DropdownMenuItem<WallpaperType>(
              value: option.type,
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建添加按钮
  Widget _buildAddButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(
          PhosphorIcons.plus(PhosphorIconsStyle.light),
          size: 20,
        ),
        onPressed: () {
          // 添加自定义预设逻辑 - 暂不实现
        },
        tooltip: '添加新预设',
      ),
    );
  }
}

/// 预设类型选项
class _PresetTypeOption {
  final String label;
  final WallpaperType type;
  final IconData icon;

  const _PresetTypeOption({
    required this.label,
    required this.type,
    required this.icon,
  });
}
