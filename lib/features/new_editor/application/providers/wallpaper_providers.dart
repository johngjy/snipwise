import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../states/wallpaper_state.dart';

/// 壁纸状态提供者
/// 提供对壁纸设置的访问和管理
final wallpaperProvider =
    StateNotifierProvider<WallpaperNotifier, WallpaperState>((ref) {
  return WallpaperNotifier();
});

/// 壁纸面板显示状态提供者
/// 控制壁纸面板是否显示
final wallpaperPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// 壁纸装饰提供者 - 根据当前壁纸设置生成对应的背景装饰
final wallpaperDecorationProvider = Provider<BoxDecoration?>((ref) {
  final wallpaperState = ref.watch(wallpaperProvider);
  final wallpaperNotifier = ref.read(wallpaperProvider.notifier);
  return wallpaperNotifier.createBackgroundDecoration();
});

/// 壁纸设置状态更新器
/// 负责管理壁纸设置的所有更新操作
class WallpaperNotifier extends StateNotifier<WallpaperState> {
  final Logger _logger = Logger();

  /// 构造函数
  WallpaperNotifier() : super(WallpaperState.initial());

  /// 设置壁纸类型
  void setWallpaperType(WallpaperType type) {
    if (type == state.type) return;

    _logger.d('设置壁纸类型: $type');
    state = state.copyWith(type: type);
  }

  // 兼容旧API
  void setType(WallpaperType type) => setWallpaperType(type);

  /// 设置背景颜色
  void setBackgroundColor(Color color) {
    if (color == state.backgroundColor) return;

    _logger.d('设置背景颜色: $color');
    state = state.copyWith(
      backgroundColor: color,
      type: WallpaperType.plainColor, // 自动切换到纯色背景类型
    );
  }

  /// 设置选中的纯色背景
  void setPlainColor(Color color) => setBackgroundColor(color);

  /// 设置选中的渐变预设
  void setGradientPreset(int index) {
    if (index == state.selectedGradientIndex) return;

    _logger.d('设置渐变预设: $index');
    state = state.copyWith(
      selectedGradientIndex: index,
      type: WallpaperType.gradient, // 自动切换到渐变背景类型
    );
  }

  // 兼容旧API
  void setGradient(int index) => setGradientPreset(index);

  /// 设置选中的壁纸
  void setWallpaperPreset(int index) {
    if (index == state.selectedWallpaperIndex) return;

    _logger.d('设置壁纸: $index');
    state = state.copyWith(
      selectedWallpaperIndex: index,
      type: WallpaperType.wallpaper, // 自动切换到壁纸类型
    );
  }

  /// 设置选中的模糊背景
  void setBlurredPreset(int index) {
    if (index == state.selectedBlurIndex) return;

    _logger.d('设置模糊背景: $index');
    state = state.copyWith(
      selectedBlurIndex: index,
      type: WallpaperType.blurred, // 自动切换到模糊背景类型
    );
  }

  // 兼容旧API
  void setBlurred(int index) => setBlurredPreset(index);

  /// 设置自定义壁纸图片
  void setCustomWallpaperImage(Uint8List imageData) {
    _logger.d('设置自定义壁纸图片');
    state = state.copyWith(
      customWallpaperImage: imageData,
      type: WallpaperType.wallpaper, // 自动切换到壁纸类型
    );
  }

  // 兼容旧API
  void setCustomWallpaper(Uint8List imageData) =>
      setCustomWallpaperImage(imageData);

  /// 设置内边距
  void setPadding(double padding) {
    if (padding == state.padding) return;

    _logger.d('设置壁纸内边距: $padding');
    state = state.copyWith(padding: padding);
  }

  /// 设置内凹边距
  void setInset(double inset) {
    if (inset == state.inset) return;

    _logger.d('设置内凹边距: $inset');
    state = state.copyWith(inset: inset);
  }

  /// 设置圆角半径
  void setCornerRadius(double radius) {
    if (radius == state.cornerRadius) return;

    _logger.d('设置圆角半径: $radius');
    state = state.copyWith(cornerRadius: radius);
  }

  /// 设置阴影半径
  void setShadowRadius(double radius) {
    if (radius == state.shadowRadius) return;

    _logger.d('设置阴影半径: $radius');
    state = state.copyWith(shadowRadius: radius);
  }

  /// 设置阴影颜色
  void setShadowColor(Color color) {
    if (color == state.shadowColor) return;

    _logger.d('设置阴影颜色: $color');
    state = state.copyWith(shadowColor: color);
  }

  /// 设置阴影偏移
  void setShadowOffset(Offset offset) {
    if (offset == state.shadowOffset) return;

    _logger.d('设置阴影偏移: $offset');
    state = state.copyWith(shadowOffset: offset);
  }

  /// 设置自动平衡
  void setAutoBalance(bool autoBalance) {
    if (autoBalance == state.autoBalance) return;

    _logger.d('设置自动平衡: $autoBalance');
    state = state.copyWith(autoBalance: autoBalance);
  }

  /// 重置所有设置
  void resetSettings() {
    _logger.d('重置壁纸设置为默认');
    state = WallpaperState.initial();
  }

  // 兼容旧API
  void resetToDefaults() => resetSettings();

  /// 创建背景装饰
  BoxDecoration? createBackgroundDecoration() {
    // 如果类型为none，返回null
    if (state.type == WallpaperType.none) {
      return null;
    }

    // 根据类型生成不同的装饰
    switch (state.type) {
      case WallpaperType.plainColor:
        return BoxDecoration(
          color: state.backgroundColor,
          borderRadius: BorderRadius.circular(state.cornerRadius),
          boxShadow: state.shadowRadius > 0
              ? [
                  BoxShadow(
                    color: state.shadowColor,
                    blurRadius: state.shadowRadius,
                    offset: state.shadowOffset,
                  ),
                ]
              : null,
        );

      case WallpaperType.gradient:
        if (state.selectedGradientIndex != null &&
            state.selectedGradientIndex! < gradientPresets.length) {
          return BoxDecoration(
            gradient: gradientPresets[state.selectedGradientIndex!].gradient,
            borderRadius: BorderRadius.circular(state.cornerRadius),
            boxShadow: state.shadowRadius > 0
                ? [
                    BoxShadow(
                      color: state.shadowColor,
                      blurRadius: state.shadowRadius,
                      offset: state.shadowOffset,
                    ),
                  ]
                : null,
          );
        }
        return BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(state.cornerRadius),
        );

      case WallpaperType.blurred:
        // 使用新的blurredBackgrounds数据结构
        if (state.selectedBlurIndex != null &&
            state.selectedBlurIndex! < blurredBackgrounds.length) {
          final blurBg = blurredBackgrounds[state.selectedBlurIndex!];
          return BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [blurBg.startColor, blurBg.endColor],
            ),
            borderRadius: BorderRadius.circular(state.cornerRadius),
            boxShadow: state.shadowRadius > 0
                ? [
                    BoxShadow(
                      color: state.shadowColor,
                      blurRadius: state.shadowRadius,
                      offset: state.shadowOffset,
                    ),
                  ]
                : null,
          );
        }
        return BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(state.cornerRadius),
        );

      case WallpaperType.wallpaper:
        // 确定图片源
        DecorationImage? image;
        if (state.customWallpaperImage != null) {
          // 使用自定义图片
          image = DecorationImage(
            image: MemoryImage(state.customWallpaperImage!),
            fit: BoxFit.cover,
          );
        } else if (state.selectedWallpaperIndex != null &&
            state.selectedWallpaperIndex! < wallpaperImagePaths.length) {
          // 使用预设图片
          image = DecorationImage(
            image:
                AssetImage(wallpaperImagePaths[state.selectedWallpaperIndex!]),
            fit: BoxFit.cover,
          );
        }

        return BoxDecoration(
          image: image,
          color: Colors.grey.shade100, // 默认背景色
          borderRadius: BorderRadius.circular(state.cornerRadius),
          boxShadow: state.shadowRadius > 0
              ? [
                  BoxShadow(
                    color: state.shadowColor,
                    blurRadius: state.shadowRadius,
                    offset: state.shadowOffset,
                  ),
                ]
              : null,
        );

      default:
        return null;
    }
  }
}
