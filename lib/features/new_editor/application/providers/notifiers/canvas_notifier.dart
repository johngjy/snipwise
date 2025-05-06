import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/canvas_state.dart';

/// 画布状态管理器
class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  /// 设置画布缩放比例
  void setScale(double scale) {
    state = state.copyWith(scale: scale);
  }

  /// 设置画布偏移量
  void setOffset(Offset offset) {
    state = state.copyWith(offset: offset);
  }

  /// 设置画布尺寸
  void setSize(Size size) {
    state = state.copyWith(size: size);
  }

  /// 设置加载状态
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// 切换网格显示
  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  /// 切换标尺显示
  void toggleRuler() {
    state = state.copyWith(showRuler: !state.showRuler);
  }

  /// 重置画布状态
  void reset() {
    state = const CanvasState();
  }
}
