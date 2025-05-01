import 'package:flutter/material.dart';
import 'drawable.dart';

/// 临时的PainterController类定义，用于解决flutter_painter_v2包导入问题
/// 
/// 这个类模拟了flutter_painter_v2包中的PainterController类，
/// 以便在包导入有问题的情况下仍然能够编译和运行代码。
class PainterController {
  /// 当前选中的可绘制对象
  List<Drawable> get selectedObjects => [];
  
  /// 可撤销操作数量
  int get undoableActionsCount => 0;
  
  /// 可重做操作数量
  int get redoableActionsCount => 0;
  
  /// 背景图片
  ImageProvider? get backgroundImage => null;
  
  /// 设置背景图片
  void setBackgroundImage(ImageProvider image) {}
  
  /// 撤销操作
  void undo() {}
  
  /// 重做操作
  void redo() {}
  
  /// 清除所有绘制内容
  void clear() {}
}
