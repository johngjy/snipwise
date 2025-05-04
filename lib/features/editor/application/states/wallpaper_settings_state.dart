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
class WallpaperSettingsState extends Equatable {
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
  const WallpaperSettingsState({
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
  factory WallpaperSettingsState.initial() => const WallpaperSettingsState();

  /// 使用copyWith创建新实例
  WallpaperSettingsState copyWith({
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
    return WallpaperSettingsState(
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
      colors: [Color(0xFF4FC3F7), Color(0xFF0D47A1)],
    ),
  ),
  // 紫色渐变
  GradientPreset(
    name: 'Purple',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
    ),
  ),
  // 绿色渐变
  GradientPreset(
    name: 'Green',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFADF7B6), Color(0xFF079330)],
    ),
  ),
  // 橙色渐变
  GradientPreset(
    name: 'Orange',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
    ),
  ),
  // 灰色渐变
  GradientPreset(
    name: 'Grey',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF616161), Color(0xFF9E9E9E)],
    ),
  ),
  // 蓝黑渐变
  GradientPreset(
    name: 'Deep',
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2C3E50), Color(0xFF000000)],
    ),
  ),
  // 天蓝渐变
  GradientPreset(
    name: 'Sky',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    ),
  ),
  // 黄橙渐变
  GradientPreset(
    name: 'Amber',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
    ),
  ),
  // 粉蓝渐变
  GradientPreset(
    name: 'Soft',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9FA8DA), Color(0xFFE1BEE7)],
    ),
  ),
  // 红橙渐变
  GradientPreset(
    name: 'Fire',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF416C), Color(0xFFFF9068)],
    ),
  ),
  // 蓝粉渐变
  GradientPreset(
    name: 'Magic',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF12D6DF), Color(0xFFFC2872)],
    ),
  ),
  // 彩虹渐变
  GradientPreset(
    name: 'Rainbow',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFF7F00),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFF4B0082),
        Color(0xFF9400D3),
      ],
    ),
  ),
  // 黑白渐变
  GradientPreset(
    name: 'Mono',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF000000), Color(0xFF666666)],
    ),
  ),
  // 柔和渐变
  GradientPreset(
    name: 'Pastel',
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF9F9F9), Color(0xFFEEEEEE)],
    ),
  ),
];

/// 模糊背景预设
final List<Color> blurredPresets = [
  const Color(0xFF654321), // 棕色模糊
  Colors.white, // 白色模糊
  Colors.grey.shade700, // 灰色模糊
];

/// 纯色预设
final List<Color> plainColorPresets = [
  Colors.black,
  Colors.white,
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.blue,
  Colors.deepPurple,
  Colors.grey,
  Colors.blueGrey,
  const Color(0xFF333333),
  Colors.white70,
  Colors.pink.shade200,
  Colors.orange.shade200,
  Colors.amber.shade200,
  Colors.lightGreen.shade200,
  Colors.lightBlue.shade200,
  Colors.purple.shade200,
];
