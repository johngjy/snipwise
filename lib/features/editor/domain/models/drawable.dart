/// 临时的Drawable类定义，用于解决flutter_painter_v2包导入问题
/// 
/// 这个类模拟了flutter_painter_v2包中的Drawable类，
/// 以便在包导入有问题的情况下仍然能够编译和运行代码。
abstract class Drawable {
  /// 绘制对象的唯一标识符
  String get id;
}

/// 临时的可绘制对象列表，用于解决类型问题
class DrawableList extends List<Drawable> {
  DrawableList() : super();
  
  factory DrawableList.empty() => DrawableList();
}
