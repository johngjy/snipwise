import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

/// 截图服务
class ScreenshotService {
  /// 控制器
  final ScreenshotController _controller = ScreenshotController();

  /// 获取截图控制器
  ScreenshotController get controller => _controller;

  /// 捕获 Widget 为图像
  Future<Uint8List?> captureWidget(Widget widget, {double? pixelRatio}) async {
    try {
      return await _controller.captureFromWidget(
        widget,
        delay: const Duration(milliseconds: 10),
        pixelRatio: pixelRatio,
      );
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// 捕获屏幕区域
  Future<Uint8List?> captureArea(BuildContext context, Rect area,
      {double? pixelRatio}) async {
    try {
      // 这里需要针对平台实现特定的屏幕区域截图
      // 以下实现较为简化，实际项目中需要扩展
      final RenderRepaintBoundary? boundary =
          context.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        final ui.Image image =
            await boundary.toImage(pixelRatio: pixelRatio ?? 1.0);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final Uint8List fullData = byteData.buffer.asUint8List();

          // 裁剪区域
          if (area != Rect.zero) {
            // 使用 image 库进行裁剪
            final img.Image? fullImage = img.decodeImage(fullData);
            if (fullImage != null) {
              final img.Image croppedImage = img.copyCrop(
                fullImage,
                x: area.left.toInt(),
                y: area.top.toInt(),
                width: area.width.toInt(),
                height: area.height.toInt(),
              );
              return Uint8List.fromList(img.encodePng(croppedImage));
            }
          }

          return fullData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing area: $e');
      return null;
    }
  }

  /// 捕获高分辨率图像的区域
  Future<Uint8List?> captureHighResArea(ui.Image sourceImage, Rect area) async {
    try {
      final ByteData? byteData =
          await sourceImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List fullData = byteData.buffer.asUint8List();

        // 裁剪区域
        if (area != Rect.zero) {
          // 确保坐标在图像范围内
          final int left =
              area.left.clamp(0, sourceImage.width.toDouble()).toInt();
          final int top =
              area.top.clamp(0, sourceImage.height.toDouble()).toInt();
          final int width =
              area.width.clamp(1, sourceImage.width - left).toInt();
          final int height =
              area.height.clamp(1, sourceImage.height - top).toInt();

          // 使用 image 库进行裁剪
          final img.Image? fullImage = img.decodeImage(fullData);
          if (fullImage != null) {
            final img.Image croppedImage = img.copyCrop(
              fullImage,
              x: left,
              y: top,
              width: width,
              height: height,
            );
            return Uint8List.fromList(img.encodePng(croppedImage));
          }
        }

        return fullData;
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing high-res area: $e');
      return null;
    }
  }

  /// 将 ui.Image 转换为 Uint8List
  Future<Uint8List?> imageToBytes(ui.Image image,
      {ui.ImageByteFormat format = ui.ImageByteFormat.png}) async {
    try {
      final ByteData? byteData = await image.toByteData(format: format);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error converting image to bytes: $e');
      return null;
    }
  }

  /// 设置 DPI (主要用于导出)
  Future<Uint8List?> setImageDpi(Uint8List imageData, int dpi) async {
    try {
      // 目前简单实现，实际需要根据格式处理
      final img.Image? decodedImage = img.decodeImage(imageData);
      if (decodedImage != null) {
        // 创建一个新的图像，设置 DPI
        // 注意：image 库中的 DPI 设置有限制，需要扩展
        return Uint8List.fromList(img.encodePng(decodedImage));
      }
      return imageData;
    } catch (e) {
      debugPrint('Error setting image DPI: $e');
      return null;
    }
  }
}
