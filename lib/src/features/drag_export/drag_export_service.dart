import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// 负责处理图像拖拽导出的服务
/// 处理图像保存为临时文件并通过平台通道与原生代码交互
class DragExportService {
  DragExportService._();
  static final DragExportService _instance = DragExportService._();
  static DragExportService get instance => _instance;

  final Logger _logger = Logger();
  final MethodChannel _channel = const MethodChannel('snipwise_drag_export');

  /// 处理拖拽开始时的操作
  /// - 保存图像为临时文件
  /// - 调用平台特定拖拽API
  ///
  /// [imageBytes] - 要导出的图像数据
  /// [position] - 拖拽起始位置（屏幕坐标）
  Future<void> startImageDrag(Uint8List imageBytes, Offset position) async {
    String? tempFilePath;

    try {
      _logger.d('拖拽导出开始 在坐标 (${position.dx}, ${position.dy})');

      // 1. 创建唯一文件名的临时文件
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempFilePath =
          '${tempDir.path}${Platform.pathSeparator}snipwise_export_$timestamp.png';

      // 2. 写入图像数据
      _logger.d('写入临时文件: $tempFilePath');
      await File(tempFilePath).writeAsBytes(imageBytes, flush: true);

      // 3. 调用平台特定实现
      await _channel.invokeMethod('startImageDrag', {
        'filePath': tempFilePath,
        'originX': position.dx,
        'originY': position.dy,
      });

      _logger.d('平台拖拽请求已发送');
    } on PlatformException catch (e) {
      _logger.e('平台拖拽失败: $e');
      await _cleanupFailedTempFile(tempFilePath);
      rethrow;
    } catch (e) {
      _logger.e('拖拽导出错误: $e');
      await _cleanupFailedTempFile(tempFilePath);
      rethrow;
    }
  }

  /// 清理由于拖拽失败而创建的临时文件
  Future<void> _cleanupFailedTempFile(String? path) async {
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          _logger.d('已清理临时文件: $path');
        }
      } catch (e) {
        _logger.w('清理临时文件失败: $e');
      }
    }
  }
}
