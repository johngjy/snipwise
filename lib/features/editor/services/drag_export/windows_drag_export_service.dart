import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'drag_export_service.dart';

/// Windows平台下的拖拽导出服务实现
class WindowsDragExportService implements DragExportService {
  /// 与原生端通信的方法通道
  static const MethodChannel _channel = MethodChannel('snipwise_drag_export');

  /// 日志记录器
  final Logger _logger = Logger();

  @override
  Future<bool> startDrag(String filePath, double x, double y) async {
    if (!isSupported()) {
      _logger.w('尝试在不支持的平台(Windows)上启动拖拽');
      return false;
    }

    _logger.d('正在Windows平台启动拖拽，文件: $filePath, 坐标: ($x, $y)');

    try {
      // 调用原生方法
      final bool result = await _channel.invokeMethod<bool>(
            'startImageDrag', // 确保方法名与原生端匹配
            {
              'filePath': filePath,
              'originX': x, // 确保参数名与原生端匹配
              'originY': y,
            },
          ) ??
          false;

      if (result) {
        _logger.d('Windows拖拽操作已成功启动');
      } else {
        _logger.w('Windows拖拽操作启动失败');
      }

      return result;
    } on PlatformException catch (e) {
      _logger.e('Windows平台拖拽错误: ${e.code} - ${e.message}', error: e);
      return false;
    } catch (e) {
      _logger.e('Windows拖拽操作异常', error: e);
      return false;
    }
  }

  @override
  bool isSupported() {
    return Platform.isWindows;
  }
}
