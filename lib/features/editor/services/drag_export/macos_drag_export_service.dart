import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'drag_export_service.dart';

/// macOS平台下的拖拽导出服务实现
class MacOSDragExportService implements DragExportService {
  /// 与原生端通信的方法通道
  static const MethodChannel _channel = MethodChannel('snipwise_drag_export');

  /// 日志记录器
  final Logger _logger = Logger();

  @override
  Future<bool> startDrag(String filePath, double x, double y) async {
    if (!isSupported()) {
      _logger.w('尝试在不支持的平台(macOS)上启动拖拽');
      return false;
    }

    _logger.d('正在macOS平台启动拖拽，文件: $filePath, 坐标: ($x, $y)');

    try {
      // 调用原生方法 - 确保方法名和参数与Swift端完全匹配
      final bool result = await _channel.invokeMethod<bool>(
            'startImageDrag',
            {
              'filePath': filePath,
              'originX': x,
              'originY': y,
            },
          ) ??
          false;

      if (result) {
        _logger.d('macOS拖拽操作已成功启动');
      } else {
        _logger.w('macOS拖拽操作启动失败');
      }

      return result;
    } on PlatformException catch (e) {
      _logger.e('macOS平台拖拽错误: ${e.code} - ${e.message}', error: e);
      return false;
    } catch (e) {
      _logger.e('macOS拖拽操作异常', error: e);
      return false;
    }
  }

  @override
  bool isSupported() {
    return Platform.isMacOS;
  }
}
