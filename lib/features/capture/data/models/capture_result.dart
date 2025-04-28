import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 截图区域
class CaptureRegion {
  /// X坐标
  final double x;

  /// Y坐标
  final double y;

  /// 宽度
  final double width;

  /// 高度
  final double height;

  const CaptureRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// 转换为 Rect
  Rect toRect() => Rect.fromLTWH(x, y, width, height);
}

/// 截图结果
class CaptureResult {
  /// 图片字节数据
  final Uint8List? imageBytes;

  /// 图片保存路径
  final String? imagePath;

  /// 截图区域
  final CaptureRegion? region;

  /// 截图时的屏幕缩放比例 (Device Pixel Ratio)
  final double scale;

  /// 逻辑矩形
  final Rect? logicalRect;

  const CaptureResult({
    this.imageBytes,
    this.imagePath,
    this.region,
    required this.scale,
    this.logicalRect,
  });

  bool get hasData => imagePath != null || imageBytes != null;
}
