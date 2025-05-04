import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../states/wallpaper_settings_state.dart';
import '../core/editor_state_core.dart';
import '../providers/editor_providers.dart' as ep;
import '../providers/canvas_providers.dart' as cp;
import '../notifiers/wallpaper_settings_notifier.dart';
import 'core_providers.dart' show wallpaperSettingsProvider;

/// 画布背景装饰提供者
/// 根据壁纸设置创建对应的背景装饰效果
final canvasBackgroundDecorationProvider = Provider<BoxDecoration?>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);

  // 如果没有应用壁纸，返回null
  if (wallpaperSettings.type == WallpaperType.none) {
    return null;
  }

  // 根据壁纸类型创建不同的装饰
  switch (wallpaperSettings.type) {
    case WallpaperType.plainColor:
      return BoxDecoration(
        color: wallpaperSettings.backgroundColor,
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
        boxShadow: wallpaperSettings.shadowRadius > 0
            ? [
                BoxShadow(
                  color: wallpaperSettings.shadowColor,
                  blurRadius: wallpaperSettings.shadowRadius,
                  offset: wallpaperSettings.shadowOffset,
                ),
              ]
            : null,
      );

    case WallpaperType.gradient:
      final gradientIndex = wallpaperSettings.selectedGradientIndex;
      if (gradientIndex != null && gradientIndex < gradientPresets.length) {
        return BoxDecoration(
          gradient: gradientPresets[gradientIndex].gradient,
          borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
          boxShadow: wallpaperSettings.shadowRadius > 0
              ? [
                  BoxShadow(
                    color: wallpaperSettings.shadowColor,
                    blurRadius: wallpaperSettings.shadowRadius,
                    offset: wallpaperSettings.shadowOffset,
                  ),
                ]
              : null,
        );
      }
      return BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
      );

    case WallpaperType.blurred:
      Color blurColor = Colors.white;
      if (wallpaperSettings.selectedBlurIndex != null &&
          wallpaperSettings.selectedBlurIndex! < blurredPresets.length) {
        blurColor = blurredPresets[wallpaperSettings.selectedBlurIndex!];
      }
      return BoxDecoration(
        color: blurColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
        boxShadow: wallpaperSettings.shadowRadius > 0
            ? [
                BoxShadow(
                  color: wallpaperSettings.shadowColor,
                  blurRadius: wallpaperSettings.shadowRadius,
                  offset: wallpaperSettings.shadowOffset,
                ),
              ]
            : null,
        backgroundBlendMode: BlendMode.overlay,
      );

    case WallpaperType.wallpaper:
      // 自定义壁纸
      return BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(wallpaperSettings.cornerRadius),
        boxShadow: wallpaperSettings.shadowRadius > 0
            ? [
                BoxShadow(
                  color: wallpaperSettings.shadowColor,
                  blurRadius: wallpaperSettings.shadowRadius,
                  offset: wallpaperSettings.shadowOffset,
                ),
              ]
            : null,
      );

    default:
      return null;
  }
});

/// 可用壁纸列表提供者
final availableWallpapersProvider = Provider<List<Wallpaper>>((ref) {
  // 将来可从资源或网络加载，目前使用预设集合
  return [
    const Wallpaper(id: 'plain_white', name: '纯白色', color: Colors.white),
    const Wallpaper(id: 'light_gray', name: '浅灰色', color: Color(0xFFF5F5F5)),
    const Wallpaper(id: 'black', name: '黑色', color: Colors.black),
    const Wallpaper(id: 'blue', name: '蓝色', color: Colors.blue),
  ];
});

/// 当前选中的壁纸ID提供者
final selectedWallpaperProvider = StateProvider<String?>((ref) {
  // 默认选中纯白色
  return 'plain_white';
});

/// 壁纸颜色提供者
/// 简化从WallpaperSettings获取当前背景颜色
final wallpaperColorProvider = Provider<Color>((ref) {
  final settings = ref.watch(wallpaperSettingsProvider);
  return settings.backgroundColor;
});

/// 壁纸图像提供者
final wallpaperImageProvider = Provider<Uint8List?>((ref) {
  final logger = Logger();
  final editorState = ref.watch(ep.editorStateProvider);

  if (editorState.currentImageData != null) {
    logger.d('壁纸图像提供者: 返回非空图像，数据长度=${editorState.currentImageData.length}');
    return editorState.currentImageData;
  } else {
    logger.w('壁纸图像提供者: 图像数据为空');
    return null;
  }
});

/// 模型用于表示单个壁纸选项
class Wallpaper {
  final String id;
  final String name;
  final Color? color;
  final String? assetPath;

  const Wallpaper({
    required this.id,
    required this.name,
    this.color,
    this.assetPath,
  });
}
