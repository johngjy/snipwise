import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';

import '../states/wallpaper_settings_state.dart';

/// Wallpaper设置状态管理Notifier
class WallpaperSettingsNotifier extends StateNotifier<WallpaperSettingsState> {
  final Logger _logger = Logger();

  WallpaperSettingsNotifier() : super(WallpaperSettingsState.initial());

  /// 设置Wallpaper类型
  void setWallpaperType(WallpaperType type) {
    _logger.d('设置Wallpaper类型: $type');
    state = state.copyWith(type: type);
  }

  /// 设置背景颜色 (用于纯色背景)
  void setBackgroundColor(Color color) {
    _logger.d('设置背景颜色: $color');
    state = state.copyWith(backgroundColor: color);
  }

  /// 选择渐变预设
  void selectGradientPreset(int index) {
    if (index < 0 || index >= gradientPresets.length) {
      _logger.e('渐变预设索引超出范围: $index');
      return;
    }

    _logger.d('选择渐变预设: $index');
    state = state.copyWith(
      type: WallpaperType.gradient,
      selectedGradientIndex: index,
    );
  }

  /// 选择预设壁纸
  void selectWallpaperPreset(int index) {
    _logger.d('选择预设壁纸: $index');
    state = state.copyWith(
      type: WallpaperType.wallpaper,
      selectedWallpaperIndex: index,
    );
  }

  /// 选择模糊背景预设
  void selectBlurredPreset(int index) {
    if (index < 0 || index >= blurredPresets.length) {
      _logger.e('模糊背景预设索引超出范围: $index');
      return;
    }

    _logger.d('选择模糊背景预设: $index');
    state = state.copyWith(
      type: WallpaperType.blurred,
      selectedBlurIndex: index,
    );
  }

  /// 选择纯色背景
  void selectPlainColor(Color color) {
    _logger.d('选择纯色背景: $color');
    state = state.copyWith(
      type: WallpaperType.plainColor,
      backgroundColor: color,
    );
  }

  /// 从图库选择自定义壁纸
  Future<void> pickCustomWallpaper() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000, // 限制图像尺寸，避免内存问题
        maxHeight: 2000,
      );

      if (image != null) {
        final imageData = await image.readAsBytes();
        _logger.d('已选择自定义壁纸: ${image.name}, 大小: ${imageData.length} 字节');

        state = state.copyWith(
          type: WallpaperType.wallpaper,
          customWallpaperImage: imageData,
          selectedWallpaperIndex: -1, // 表示使用自定义壁纸
        );
      }
    } catch (e) {
      _logger.e('选择自定义壁纸失败', error: e);
    }
  }

  /// 设置内边距
  void setPadding(double value) {
    _logger.d('设置内边距: $value');
    state = state.copyWith(padding: value);
  }

  /// 设置内凹边距
  void setInset(double value) {
    _logger.d('设置内凹边距: $value');
    state = state.copyWith(inset: value);
  }

  /// 设置圆角半径
  void setCornerRadius(double value) {
    _logger.d('设置圆角半径: $value');
    state = state.copyWith(cornerRadius: value);
  }

  /// 设置阴影半径
  void setShadowRadius(double value) {
    _logger.d('设置阴影半径: $value');
    state = state.copyWith(shadowRadius: value);
  }

  /// 设置阴影颜色
  void setShadowColor(Color color) {
    _logger.d('设置阴影颜色: $color');
    state = state.copyWith(shadowColor: color);
  }

  /// 设置阴影偏移
  void setShadowOffset(Offset offset) {
    _logger.d('设置阴影偏移: $offset');
    state = state.copyWith(shadowOffset: offset);
  }

  /// 设置是否自动平衡
  void setAutoBalance(bool value) {
    _logger.d('设置自动平衡: $value');
    state = state.copyWith(autoBalance: value);
  }

  /// 重置所有设置为默认值
  void resetToDefaults() {
    _logger.d('重置所有墙纸设置为默认值');
    state = WallpaperSettingsState.initial();
  }
}
