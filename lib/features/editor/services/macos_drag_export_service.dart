import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'drag_export_service.dart';

/// macOS平台特定的拖放导出服务实现
class MacOSDragExportService implements DragExportService {
  final _logger = Logger();
  static const _channel = MethodChannel('com.snipwise.drag_export');

  @override
  Future<bool> startDrag(Uint8List imageBytes, String format) async {
    try {
      // 创建临时文件保存图像
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/drag_export_image.$format');
      await tempFile.writeAsBytes(imageBytes);

      _logger.d('准备开始拖放操作: ${tempFile.path}, 图像大小: ${imageBytes.length} 字节');

      // 调用原生方法启动拖放
      final result = await _channel.invokeMethod<bool>(
        'startDrag',
        {'filePath': tempFile.path},
      );

      _logger.d('拖放操作结果: $result');
      return result ?? false;
    } catch (e, stackTrace) {
      _logger.e('拖放操作失败: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
