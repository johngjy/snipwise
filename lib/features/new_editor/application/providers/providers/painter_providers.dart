import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import '../notifiers/painter_notifier.dart';
import '../states/painter_state.dart';

/// 绘图工具状态提供者
final painterStateProvider =
    StateNotifierProvider<PainterNotifier, PainterState>((ref) {
  return PainterNotifier();
});

/// 绘制模式提供者
final drawingModeProvider = Provider<DrawingMode>((ref) {
  return ref.watch(painterStateProvider).drawingMode;
});

/// 线条宽度提供者
final strokeWidthProvider = Provider<double>((ref) {
  return ref.watch(painterStateProvider).strokeWidth;
});

/// 线条颜色提供者
final strokeColorProvider = Provider<Color>((ref) {
  return ref.watch(painterStateProvider).strokeColor;
});

/// 填充颜色提供者
final fillColorProvider = Provider<Color>((ref) {
  return ref.watch(painterStateProvider).fillColor;
});

/// 是否填充提供者
final isFilledProvider = Provider<bool>((ref) {
  return ref.watch(painterStateProvider).isFilled;
});

/// 是否显示调色板提供者
final showColorPickerProvider = Provider<bool>((ref) {
  return ref.watch(painterStateProvider).showColorPicker;
});

/// 文本缓存提供者
final textCacheProvider = Provider<List<String>>((ref) {
  return ref.watch(painterStateProvider).textCache;
});

/// 显示文本缓存对话框提供者
final showTextCacheDialogProvider = Provider<bool>((ref) {
  return ref.watch(painterStateProvider).showTextCacheDialog;
});

/// 选中的绘图对象提供者
final selectedObjectProvider = Provider<ObjectDrawable?>((ref) {
  return ref.watch(painterStateProvider).selectedObject;
});

/// 绘图控制器提供者
final painterControllerProvider = Provider<PainterController?>((ref) {
  return ref.watch(painterStateProvider).controller;
});
