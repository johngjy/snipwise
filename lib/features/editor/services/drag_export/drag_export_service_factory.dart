import 'dart:io' show Platform;

import 'drag_export_service.dart';
import 'macos_drag_export_service.dart';
import 'windows_drag_export_service.dart';
import 'unsupported_drag_export_service.dart';

/// 拖拽导出服务工厂类
class DragExportServiceFactory {
  /// 私有构造函数
  DragExportServiceFactory._();

  /// 创建当前平台的拖拽导出服务实例
  static DragExportService create() {
    if (Platform.isMacOS) {
      return MacOSDragExportService();
    } else if (Platform.isWindows) {
      return WindowsDragExportService();
    } else {
      return UnsupportedDragExportService();
    }
  }
}
