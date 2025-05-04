import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 统一的画布状态类
/// 整合了原有编辑器中分散在多个状态类中的画布相关状态
class CanvasState extends Equatable {
  /// 原始截图尺寸
  final Size? originalImageSize;

  /// 当前图像数据 (二进制)
  final Uint8List? imageData;

  /// 当前加载的UI图像
  final ui.Image? uiImage;

  /// 捕获的屏幕比例
  final double capturedScale;

  /// 画布缩放级别
  final double scale;

  /// 画布偏移量
  final Offset offset;

  /// 壁纸内边距
  final EdgeInsets padding;

  /// 画布总尺寸 (包含内边距)
  final Size? totalSize;

  /// 可见的画布区域尺寸
  final Size viewportSize;

  /// 加载状态
  final bool isLoading;

  /// 是否启用壁纸
  final bool isWallpaperEnabled;

  /// 构造函数
  const CanvasState({
    this.originalImageSize,
    this.imageData,
    this.uiImage,
    this.capturedScale = 1.0,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.padding = EdgeInsets.zero,
    this.totalSize,
    this.viewportSize = const Size(900, 600),
    this.isLoading = false,
    this.isWallpaperEnabled = true,
  });

  /// 创建初始状态
  factory CanvasState.initial() => const CanvasState();

  /// 使用copyWith创建新实例
  CanvasState copyWith({
    Size? originalImageSize,
    Uint8List? imageData,
    ui.Image? uiImage,
    double? capturedScale,
    double? scale,
    Offset? offset,
    EdgeInsets? padding,
    Size? totalSize,
    Size? viewportSize,
    bool? isLoading,
    bool? isWallpaperEnabled,
  }) {
    return CanvasState(
      originalImageSize: originalImageSize ?? this.originalImageSize,
      imageData: imageData ?? this.imageData,
      uiImage: uiImage ?? this.uiImage,
      capturedScale: capturedScale ?? this.capturedScale,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      padding: padding ?? this.padding,
      totalSize: totalSize ?? this.totalSize,
      viewportSize: viewportSize ?? this.viewportSize,
      isLoading: isLoading ?? this.isLoading,
      isWallpaperEnabled: isWallpaperEnabled ?? this.isWallpaperEnabled,
    );
  }

  /// 计算画布内容是否溢出视口
  bool get isOverflowing {
    if (totalSize == null) return false;

    final scaledWidth = totalSize!.width * scale;
    final scaledHeight = totalSize!.height * scale;

    return scaledWidth > viewportSize.width ||
        scaledHeight > viewportSize.height ||
        offset != Offset.zero;
  }

  /// 计算适合视口的缩放比例
  double calculateFitScale() {
    if (originalImageSize == null ||
        originalImageSize!.isEmpty ||
        viewportSize.isEmpty) {
      return 1.0;
    }

    // 计算包含内边距的总内容尺寸
    final contentWidth =
        originalImageSize!.width + padding.left + padding.right;
    final contentHeight =
        originalImageSize!.height + padding.top + padding.bottom;

    // 计算宽高比
    final widthRatio = viewportSize.width / contentWidth;
    final heightRatio = viewportSize.height / contentHeight;

    // 取较小值确保内容完全可见
    return widthRatio < heightRatio ? widthRatio : heightRatio;
  }

  /// 计算使内容居中的偏移量
  Offset calculateCenterOffset() {
    if (originalImageSize == null || totalSize == null) return Offset.zero;

    final scaledWidth = totalSize!.width * scale;
    final scaledHeight = totalSize!.height * scale;

    final offsetX = (viewportSize.width - scaledWidth) / 2;
    final offsetY = (viewportSize.height - scaledHeight) / 2;

    return Offset(offsetX, offsetY);
  }

  @override
  List<Object?> get props => [
        originalImageSize,
        imageData,
        uiImage,
        capturedScale,
        scale,
        offset,
        padding,
        totalSize,
        viewportSize,
        isLoading,
        isWallpaperEnabled,
      ];
}
