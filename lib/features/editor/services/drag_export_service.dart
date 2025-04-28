import 'dart:typed_data';

/// 拖放导出服务的接口
/// 用于实现不同平台的拖放功能
abstract class DragExportService {
  /// 启动拖放操作
  ///
  /// [imageBytes] 图像数据的字节数组
  /// [format] 图像格式（如 'png', 'jpg'）
  ///
  /// 返回是否成功启动拖放操作
  Future<bool> startDrag(Uint8List imageBytes, String format);
}
