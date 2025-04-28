import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;

import 'drag_export_service.dart';
import 'drag_export_service_factory.dart';

/// 导出格式枚举
enum DragExportFormat {
  /// PNG格式 - 无损，支持透明度
  png,

  /// JPEG格式 - 有损压缩，文件更小
  jpg,
}

/// 拖拽导出适配器类
///
/// 将通用的拖拽导出功能适配到各平台特定的实现
class DragExportAdapter {
  /// 单例实例
  static final DragExportAdapter _instance = DragExportAdapter._();

  /// 获取单例实例
  static DragExportAdapter get instance => _instance;

  /// 私有构造函数
  DragExportAdapter._();

  /// 日志记录器
  final Logger _logger = Logger();

  /// 平台特定的服务实现
  final DragExportService _service = DragExportServiceFactory.create();

  /// 最大重试次数
  static const int _maxRetries = 2;

  /// 默认JPEG质量 (1-100)
  static const int _defaultJpegQuality = 90;

  /// 检查当前平台是否支持拖拽导出
  bool get isSupported => _service.isSupported();

  /// 执行拖拽导出操作
  ///
  /// [imageBytes] - 要拖拽的图像数据
  /// [position] - 拖拽起始位置（屏幕坐标）
  /// [format] - 导出格式，默认为PNG
  /// [jpegQuality] - JPEG质量 (1-100)，仅当format为jpg时有效
  /// [retryCount] - 当前重试次数（用于内部递归调用）
  Future<bool> startDrag(
    Uint8List imageBytes,
    Offset position, {
    DragExportFormat format = DragExportFormat.png,
    int jpegQuality = _defaultJpegQuality,
    int retryCount = 0,
  }) async {
    String? tempFilePath;

    try {
      // 获取图像大小信息以便日志
      final double imageSizeKB = imageBytes.length / 1024;
      _logger.d('开始拖拽导出操作，坐标: (${position.dx}, ${position.dy})，'
          '图像大小: ${imageSizeKB.toStringAsFixed(2)} KB，'
          '格式: ${format.name.toUpperCase()}');

      // 检查是否支持拖拽
      if (!isSupported) {
        _logger.w('当前平台不支持拖拽导出功能：${Platform.operatingSystem}');
        return false;
      }

      // 检查图像数据
      if (imageBytes.isEmpty) {
        _logger.e('图像数据为空，无法执行拖拽操作');
        return false;
      }

      // 1. 创建临时文件
      final tempDir = await getTemporaryDirectory();
      _logger.d('临时目录路径: ${tempDir.path}');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = format == DragExportFormat.jpg ? 'jpg' : 'png';
      tempFilePath =
          '${tempDir.path}${Platform.pathSeparator}snipwise_export_$timestamp.$extension';
      _logger.d('将使用临时文件路径: $tempFilePath');

      // 2. 准备输出数据
      late Uint8List outputBytes;
      if (format == DragExportFormat.jpg && imageBytes[0] == 0x89) {
        // 检查PNG签名
        _logger.d('转换PNG到JPEG格式');
        try {
          // 解码PNG数据
          final img.Image? decodedImage = img.decodeImage(imageBytes);
          if (decodedImage == null) {
            _logger.e('无法解码图像数据');
            return false;
          }

          // 编码为JPEG
          outputBytes = Uint8List.fromList(
            img.encodeJpg(decodedImage, quality: jpegQuality),
          );

          _logger.d('PNG到JPEG转换成功，'
              '原始大小: ${imageSizeKB.toStringAsFixed(2)} KB, '
              '转换后: ${(outputBytes.length / 1024).toStringAsFixed(2)} KB');
        } catch (e) {
          _logger.e('图像格式转换失败', error: e);
          // 转换失败时回退到原始格式
          outputBytes = imageBytes;

          // 修正文件扩展名
          tempFilePath = tempFilePath.replaceAll('.jpg', '.png');
          _logger.w('回退到PNG格式, 新路径: $tempFilePath');
        }
      } else {
        // 不需要转换的情况
        outputBytes = imageBytes;
      }

      // 3. 保存图像到临时文件
      _logger.d('正在保存图像到临时文件: $tempFilePath');
      final file = File(tempFilePath);

      try {
        await file.writeAsBytes(outputBytes, flush: true);

        // 验证文件是否成功写入且有效
        final fileStats = await file.stat();
        if (fileStats.size <= 0) {
          throw Exception('文件写入失败，文件大小为0');
        }

        _logger.d(
            '图像已成功保存，文件大小: ${(fileStats.size / 1024).toStringAsFixed(2)} KB');

        // 检查文件是否存在
        if (await file.exists()) {
          _logger.d('已确认临时文件存在: $tempFilePath');
        } else {
          _logger.e('临时文件不存在，写入似乎成功但文件未找到');
          return false;
        }
      } catch (e) {
        _logger.e('保存图像到临时文件失败', error: e);
        return false;
      }

      // 4. 调用平台特定实现
      _logger.d('调用平台特定实现 (${Platform.operatingSystem})，传递参数: '
          'filePath=$tempFilePath, x=${position.dx}, y=${position.dy}');

      final result = await _service.startDrag(
        tempFilePath,
        position.dx,
        position.dy,
      );

      if (result) {
        _logger.d('拖拽操作已成功启动，请拖动到目标应用');
        return true;
      } else {
        _logger.w('拖拽操作启动失败，平台特定实现返回false');

        // 如果失败且未超过最大重试次数，则重试
        if (retryCount < _maxRetries) {
          _logger.d('尝试重新启动拖拽操作 (${retryCount + 1}/$_maxRetries)');
          await _cleanupFailedTempFile(tempFilePath);
          return startDrag(
            imageBytes,
            position,
            format: format,
            jpegQuality: jpegQuality,
            retryCount: retryCount + 1,
          );
        } else {
          _logger.e('达到最大重试次数 ($_maxRetries)，拖拽操作启动失败');
          await _cleanupFailedTempFile(tempFilePath);
          return false;
        }
      }
    } catch (e, stackTrace) {
      _logger.e('拖拽操作异常', error: e, stackTrace: stackTrace);
      await _cleanupFailedTempFile(tempFilePath);

      // 如果异常且未超过最大重试次数，则重试
      if (retryCount < _maxRetries) {
        _logger.d('拖拽操作遇到异常，尝试重试 (${retryCount + 1}/$_maxRetries)');
        return startDrag(
          imageBytes,
          position,
          format: format,
          jpegQuality: jpegQuality,
          retryCount: retryCount + 1,
        );
      }

      return false;
    }
  }

  /// 清理临时文件（如果拖拽失败）
  Future<void> _cleanupFailedTempFile(String? filePath) async {
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          _logger.d('已清理临时文件: $filePath');
        } else {
          _logger.d('临时文件不存在，无需清理: $filePath');
        }
      } catch (e) {
        _logger.w('清理临时文件失败: $e');
      }
    }
  }
}
