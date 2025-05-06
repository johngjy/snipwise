import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'drag_export_service.dart';

/// Windows平台下的拖拽导出服务实现
class WindowsDragExportService implements DragExportService {
  /// 与原生端通信的方法通道
  static const MethodChannel _channel =
      MethodChannel('com.snipwise/drag_export');

  /// 日志记录器
  final Logger _logger = Logger();

  @override
  Future<bool> startDrag(String filePath, double x, double y) async {
    if (!isSupported()) {
      _logger.w('Attempting to start drag on unsupported platform (Windows)');
      return false;
    }

    _logger.d(
        'Starting drag on Windows platform, file: $filePath, coordinates: ($x, $y)');

    try {
      // 调用原生方法
      final bool result = await _channel.invokeMethod<bool>(
            'startDrag', // 确保方法名与原生端匹配
            {
              'filePath': filePath,
              'originX': x, // 确保参数名与原生端匹配
              'originY': y,
            },
          ) ??
          false;

      if (result) {
        _logger.d('Windows drag operation successfully started');
      } else {
        _logger.w('Windows drag operation failed to start');
      }

      return result;
    } on PlatformException catch (e) {
      _logger.e('Windows platform drag error: ${e.code} - ${e.message}',
          error: e);
      return false;
    } catch (e) {
      _logger.e('Windows drag operation exception', error: e);
      return false;
    }
  }

  @override
  bool isSupported() {
    return Platform.isWindows;
  }
}
