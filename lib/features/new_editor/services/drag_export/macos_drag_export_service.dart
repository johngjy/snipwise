import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'drag_export_service.dart';

/// macOS平台下的拖拽导出服务实现
class MacOSDragExportService implements DragExportService {
  /// 与原生端通信的方法通道
  static const MethodChannel _channel =
      MethodChannel('com.snipwise/drag_export');

  /// 日志记录器
  final Logger _logger = Logger();

  @override
  Future<bool> startDrag(String filePath, double x, double y) async {
    if (!isSupported()) {
      _logger.w('Attempting to start drag on unsupported platform (macOS)');
      return false;
    }

    _logger.d(
        'Starting drag on macOS platform, file: $filePath, coordinates: ($x, $y)');

    try {
      // 调用原生方法 - 确保方法名和参数与Swift端完全匹配
      final bool result = await _channel.invokeMethod<bool>(
            'startDrag',
            {
              'filePath': filePath,
              'originX': x,
              'originY': y,
            },
          ) ??
          false;

      if (result) {
        _logger.d('macOS drag operation successfully started');
      } else {
        _logger.w('macOS drag operation failed to start');
      }

      return result;
    } on PlatformException catch (e) {
      _logger.e('macOS platform drag error: ${e.code} - ${e.message}',
          error: e);
      return false;
    } catch (e) {
      _logger.e('macOS drag operation exception', error: e);
      return false;
    }
  }

  @override
  bool isSupported() {
    return Platform.isMacOS;
  }
}
