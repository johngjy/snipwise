import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Rect;
import 'package:image/image.dart' as img;

import 'file_service.dart';

/// 导出格式
enum ExportFormat {
  png,
  jpg,
  // 后续可添加PDF等
}

/// 导出服务
class ExportService {
  final FileService _fileService;

  ExportService(this._fileService);

  /// 导出图像
  Future<String?> exportImage(
    Uint8List imageData,
    String fileName, {
    ExportFormat format = ExportFormat.png,
    int? dpi,
    int jpgQuality = 90,
  }) async {
    try {
      Uint8List outputData = imageData;
      String extension;

      // 处理不同的格式
      if (format == ExportFormat.jpg) {
        extension = 'jpg';
        // 转换为JPEG格式
        final img.Image? decodedImage = img.decodeImage(imageData);
        if (decodedImage != null) {
          outputData = Uint8List.fromList(
              img.encodeJpg(decodedImage, quality: jpgQuality));
        }
      } else {
        extension = 'png';
        // 如果需要设置DPI，先处理
        if (dpi != null) {
          // 实际DPI设置可能需要更复杂的实现
          // 这里是简化处理
        }
      }

      // 保存文件
      return await _fileService.saveFile(outputData, fileName,
          extension: extension);
    } catch (e) {
      debugPrint('Error exporting image: $e');
      return null;
    }
  }

  /// 导出高分辨率图像
  Future<String?> exportHighResImage(
    ui.Image sourceImage,
    Rect region,
    String fileName, {
    ExportFormat format = ExportFormat.png,
    int? dpi,
    int jpgQuality = 90,
  }) async {
    try {
      // 首先获取完整图像数据
      final ByteData? byteData =
          await sourceImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List fullData = byteData.buffer.asUint8List();

      // 解码源图像
      final img.Image? fullImage = img.decodeImage(fullData);
      if (fullImage == null) return null;

      // 确保区域坐标有效
      final int left =
          region.left.clamp(0, sourceImage.width.toDouble()).toInt();
      final int top =
          region.top.clamp(0, sourceImage.height.toDouble()).toInt();
      final int width = region.width.clamp(1, sourceImage.width - left).toInt();
      final int height =
          region.height.clamp(1, sourceImage.height - top).toInt();

      // 裁剪图像
      final img.Image croppedImage = img.copyCrop(
        fullImage,
        x: left,
        y: top,
        width: width,
        height: height,
      );

      Uint8List outputData;
      String extension;

      // 根据格式导出
      if (format == ExportFormat.jpg) {
        outputData = Uint8List.fromList(
            img.encodeJpg(croppedImage, quality: jpgQuality));
        extension = 'jpg';
      } else {
        outputData = Uint8List.fromList(img.encodePng(croppedImage));
        extension = 'png';
      }

      // 保存文件
      return await _fileService.saveFile(outputData, fileName,
          extension: extension);
    } catch (e) {
      debugPrint('Error exporting high-res image: $e');
      return null;
    }
  }

  /// 导出工程文件
  Future<String?> exportProject(
      Map<String, dynamic> projectData, String fileName) async {
    try {
      // 转换为JSON字符串
      final jsonString = projectData.toString(); // 实际使用应该用 jsonEncode
      final bytes = Uint8List.fromList(jsonString.codeUnits);

      // 保存文件
      return await _fileService.saveFile(bytes, fileName, extension: 'snp');
    } catch (e) {
      debugPrint('Error exporting project: $e');
      return null;
    }
  }
}
