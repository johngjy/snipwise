import 'drag_export_service.dart';

/// 不支持平台的拖拽导出服务实现
class UnsupportedDragExportService implements DragExportService {
  @override
  Future<bool> startDrag(String filePath, double x, double y) async {
    // 不支持的平台总是返回失败
    return false;
  }

  @override
  bool isSupported() {
    return false;
  }
}
