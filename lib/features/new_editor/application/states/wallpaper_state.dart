import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// 墙纸类型枚举
enum WallpaperType {
  none,
  gradient,
  wallpaper,
  blurred,
  plainColor,
}

/// 渐变预设类型
class GradientPreset {
  final String name;
  final Gradient gradient;

  const GradientPreset({
    required this.name,
    required this.gradient,
  });
}

/// 墙纸设置状态类
class WallpaperState extends Equatable {
  /// 墙纸类型
  final WallpaperType type;

  /// 背景颜色 (用于纯色背景)
  final Color backgroundColor;

  /// 选中的渐变预设索引
  final int? selectedGradientIndex;

  /// 选中的墙纸索引
  final int? selectedWallpaperIndex;

  /// 选中的模糊背景索引
  final int? selectedBlurIndex;

  /// 自定义墙纸图片数据
  final Uint8List? customWallpaperImage;

  /// 四周统一内边距
  final double padding;

  /// 内凹边距
  final double inset;

  /// 圆角半径
  final double cornerRadius;

  /// 阴影半径
  final double shadowRadius;

  /// 阴影颜色
  final Color shadowColor;

  /// 阴影偏移
  final Offset shadowOffset;

  /// 是否自动平衡
  final bool autoBalance;

  /// 构造函数
  const WallpaperState({
    this.type = WallpaperType.none,
    this.backgroundColor = Colors.white,
    this.selectedGradientIndex,
    this.selectedWallpaperIndex,
    this.selectedBlurIndex,
    this.customWallpaperImage,
    this.padding = 0.0,
    this.inset = 0.0,
    this.cornerRadius = 8.0,
    this.shadowRadius = 0.0,
    this.shadowColor = Colors.black26,
    this.shadowOffset = const Offset(0, 2),
    this.autoBalance = false,
  });

  /// 创建初始状态
  factory WallpaperState.initial() => const WallpaperState();

  /// 使用copyWith创建新实例
  WallpaperState copyWith({
    WallpaperType? type,
    Color? backgroundColor,
    int? selectedGradientIndex,
    int? selectedWallpaperIndex,
    int? selectedBlurIndex,
    Uint8List? customWallpaperImage,
    double? padding,
    double? inset,
    double? cornerRadius,
    double? shadowRadius,
    Color? shadowColor,
    Offset? shadowOffset,
    bool? autoBalance,
  }) {
    return WallpaperState(
      type: type ?? this.type,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedGradientIndex:
          selectedGradientIndex ?? this.selectedGradientIndex,
      selectedWallpaperIndex:
          selectedWallpaperIndex ?? this.selectedWallpaperIndex,
      selectedBlurIndex: selectedBlurIndex ?? this.selectedBlurIndex,
      customWallpaperImage: customWallpaperImage ?? this.customWallpaperImage,
      padding: padding ?? this.padding,
      inset: inset ?? this.inset,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      shadowRadius: shadowRadius ?? this.shadowRadius,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      autoBalance: autoBalance ?? this.autoBalance,
    );
  }

  @override
  List<Object?> get props => [
        type,
        backgroundColor,
        selectedGradientIndex,
        selectedWallpaperIndex,
        selectedBlurIndex,
        customWallpaperImage,
        padding,
        inset,
        cornerRadius,
        shadowRadius,
        shadowColor,
        shadowOffset,
        autoBalance,
      ];
}

/// 渐变预设列表
final List<GradientPreset> gradientPresets = [
  // 粉红紫色渐变
  GradientPreset(
    name: 'Rose',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF78CA0), Color(0xFFA355F7)],
    ),
  ),
  // 蓝紫渐变
  GradientPreset(
    name: 'Ocean',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4776E6), Color(0xFF1E308B)],
    ),
  ),
  // 蓝绿渐变
  GradientPreset(
    name: 'Teal',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF38EF7D), Color(0xFF11A5FC)],
    ),
  ),
  // 橙红渐变
  GradientPreset(
    name: 'Sunset',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFE6580), Color(0xFFFF9C5B)],
    ),
  ),
  // 紫蓝渐变
  GradientPreset(
    name: 'Lavender',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
    ),
  ),
  // 粉色渐变
  GradientPreset(
    name: 'Pink',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF0080), Color(0xFFFF8CAB)],
    ),
  ),
  // 蓝色渐变
  GradientPreset(
    name: 'Blue',
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4B79E4), Color(0xFF7FACFF)],
    ),
  ),
  // 绿色渐变
  GradientPreset(
    name: 'Green',
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3CB371), Color(0xFF9DE5AA)],
    ),
  ),
];

/// 墙纸图片列表
final List<String> wallpaperImagePaths = [
  'assets/wallpapers/abstract1.jpg',
  'assets/wallpapers/abstract2.jpg',
  'assets/wallpapers/abstract3.jpg',
  'assets/wallpapers/abstract4.jpg',
  'assets/wallpapers/abstract5.jpg',
  'assets/wallpapers/abstract6.jpg',
  'assets/wallpapers/abstract7.jpg',
  'assets/wallpapers/abstract8.jpg',
];

/// 纯色背景列表
final List<Color> plainColors = [
  Colors.white,
  Colors.black,
  Colors.grey.shade200,
  Colors.blueGrey.shade100,
  Colors.blue.shade100,
  Colors.red.shade100,
  Colors.green.shade100,
  Colors.yellow.shade100,
  Colors.purple.shade100,
  Colors.pink.shade100,
  Colors.orange.shade100,
  Colors.teal.shade100,
];

/// 模糊背景类型
enum BlurBackgroundType {
  light,
  dark,
  colorful,
  natureDark,
  natureLight,
  gradient,
  gradientDark,
  pastel,
}

/// 模糊背景设置
class BlurredBackground {
  final String name;
  final Color startColor;
  final Color endColor;
  final BlurBackgroundType type;

  const BlurredBackground({
    required this.name,
    required this.startColor,
    required this.endColor,
    required this.type,
  });
}

/// 模糊背景预设列表
final List<BlurredBackground> blurredBackgrounds = [
  // 浅色模糊背景
  const BlurredBackground(
    name: 'Light',
    startColor: Color(0xFFFFFFFF),
    endColor: Color(0xFFEEEEEE),
    type: BlurBackgroundType.light,
  ),
  // 暗色模糊背景
  const BlurredBackground(
    name: 'Dark',
    startColor: Color(0xFF333333),
    endColor: Color(0xFF111111),
    type: BlurBackgroundType.dark,
  ),
  // 多彩模糊背景
  const BlurredBackground(
    name: 'Colorful',
    startColor: Color(0xFFFF5F6D),
    endColor: Color(0xFFFFB950),
    type: BlurBackgroundType.colorful,
  ),
  // 自然暗色模糊背景
  const BlurredBackground(
    name: 'Nature Dark',
    startColor: Color(0xFF2C3E50),
    endColor: Color(0xFF4CA1AF),
    type: BlurBackgroundType.natureDark,
  ),
  // 自然亮色模糊背景
  const BlurredBackground(
    name: 'Nature Light',
    startColor: Color(0xFF56CCF2),
    endColor: Color(0xFF2F80ED),
    type: BlurBackgroundType.natureLight,
  ),
  // 渐变模糊背景
  const BlurredBackground(
    name: 'Gradient',
    startColor: Color(0xFFEE9CA7),
    endColor: Color(0xFFFFDDE1),
    type: BlurBackgroundType.gradient,
  ),
  // 暗色渐变模糊背景
  const BlurredBackground(
    name: 'Gradient Dark',
    startColor: Color(0xFF6A11CB),
    endColor: Color(0xFF2575FC),
    type: BlurBackgroundType.gradientDark,
  ),
  // 柔和色模糊背景
  const BlurredBackground(
    name: 'Pastel',
    startColor: Color(0xFFA8E6CF),
    endColor: Color(0xFFDCEDC1),
    type: BlurBackgroundType.pastel,
  ),
];
