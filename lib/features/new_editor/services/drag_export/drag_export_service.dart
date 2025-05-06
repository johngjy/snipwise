/// 用于处理图像拖拽导出功能的服务接口
abstract class DragExportService {
  /// 启动拖拽操作
  ///
  /// [filePath] 要拖拽的文件路径
  /// [x] 鼠标在屏幕上的X坐标
  /// [y] 鼠标在屏幕上的Y坐标
  ///
  /// 返回拖拽操作是否成功启动
  Future<bool> startDrag(String filePath, double x, double y);

  /// 判断当前平台是否支持拖拽导出功能
  bool isSupported();
}
