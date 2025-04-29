import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 编辑器核心状态类
class EditorState extends Equatable {
  /// 原始截图尺寸
  final Size? originalImageSize;

  /// 当前图像数据
  final dynamic currentImageData;

  /// 背景颜色
  final Color wallpaperColor;

  /// 背景边距
  final EdgeInsets wallpaperPadding;

  /// 加载状态
  final bool isLoading;

  /// 是否启用背景
  final bool isWallpaperEnabled;

  const EditorState({
    this.originalImageSize,
    this.currentImageData,
    this.wallpaperColor = Colors.white,
    this.wallpaperPadding = EdgeInsets.zero,
    this.isLoading = false,
    this.isWallpaperEnabled = true,
  });

  /// 创建初始状态
  factory EditorState.initial() => const EditorState();

  /// 使用copyWith创建新实例
  EditorState copyWith({
    Size? originalImageSize,
    dynamic currentImageData,
    Color? wallpaperColor,
    EdgeInsets? wallpaperPadding,
    bool? isLoading,
    bool? isWallpaperEnabled,
  }) {
    return EditorState(
      originalImageSize: originalImageSize ?? this.originalImageSize,
      currentImageData: currentImageData ?? this.currentImageData,
      wallpaperColor: wallpaperColor ?? this.wallpaperColor,
      wallpaperPadding: wallpaperPadding ?? this.wallpaperPadding,
      isLoading: isLoading ?? this.isLoading,
      isWallpaperEnabled: isWallpaperEnabled ?? this.isWallpaperEnabled,
    );
  }

  @override
  List<Object?> get props => [
        originalImageSize,
        currentImageData,
        wallpaperColor,
        wallpaperPadding,
        isLoading,
        isWallpaperEnabled,
      ];
}
