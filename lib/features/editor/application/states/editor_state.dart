import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 编辑器核心状态类
class EditorState extends Equatable {
  /// 原始截图尺寸
  final Size? originalImageSize;

  /// 当前图像数据 (Uint8List)
  final dynamic currentImageData;

  /// 当前加载的UI图像
  final ui.Image? imageAsUiImage;

  /// 捕获的屏幕比例
  final double capturedScale;

  /// 背景颜色
  final Color wallpaperColor;

  /// 背景边距
  final EdgeInsets wallpaperPadding;

  /// 加载状态
  final bool isLoading;

  /// 是否启用背景
  final bool isWallpaperEnabled;

  /// 缩放菜单是否可见
  final bool isZoomMenuVisible;

  /// 新建按钮菜单是否可见
  final bool isNewButtonMenuVisible;

  const EditorState({
    this.originalImageSize,
    this.currentImageData,
    this.imageAsUiImage,
    this.capturedScale = 1.0,
    this.wallpaperColor = Colors.white,
    this.wallpaperPadding = EdgeInsets.zero,
    this.isLoading = false,
    this.isWallpaperEnabled = true,
    this.isZoomMenuVisible = false,
    this.isNewButtonMenuVisible = false,
  });

  /// 创建初始状态
  factory EditorState.initial() => const EditorState();

  /// 使用copyWith创建新实例
  EditorState copyWith({
    Size? originalImageSize,
    dynamic currentImageData,
    ui.Image? imageAsUiImage,
    double? capturedScale,
    Color? wallpaperColor,
    EdgeInsets? wallpaperPadding,
    bool? isLoading,
    bool? isWallpaperEnabled,
    bool? isZoomMenuVisible,
    bool? isNewButtonMenuVisible,
  }) {
    return EditorState(
      originalImageSize: originalImageSize ?? this.originalImageSize,
      currentImageData: currentImageData ?? this.currentImageData,
      imageAsUiImage: imageAsUiImage ?? this.imageAsUiImage,
      capturedScale: capturedScale ?? this.capturedScale,
      wallpaperColor: wallpaperColor ?? this.wallpaperColor,
      wallpaperPadding: wallpaperPadding ?? this.wallpaperPadding,
      isLoading: isLoading ?? this.isLoading,
      isWallpaperEnabled: isWallpaperEnabled ?? this.isWallpaperEnabled,
      isZoomMenuVisible: isZoomMenuVisible ?? this.isZoomMenuVisible,
      isNewButtonMenuVisible:
          isNewButtonMenuVisible ?? this.isNewButtonMenuVisible,
    );
  }

  @override
  List<Object?> get props => [
        originalImageSize,
        currentImageData,
        imageAsUiImage,
        capturedScale,
        wallpaperColor,
        wallpaperPadding,
        isLoading,
        isWallpaperEnabled,
        isZoomMenuVisible,
        isNewButtonMenuVisible,
      ];
}
