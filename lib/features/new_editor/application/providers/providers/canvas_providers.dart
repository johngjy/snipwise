import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/canvas_notifier.dart';
import '../states/canvas_state.dart';

/// 画布状态提供者
final canvasStateProvider =
    StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});

/// 画布缩放比例提供者
final canvasScaleProvider = Provider<double>((ref) {
  return ref.watch(canvasStateProvider).scale;
});

/// 画布偏移量提供者
final canvasOffsetProvider = Provider<Offset>((ref) {
  return ref.watch(canvasStateProvider).offset;
});

/// 画布尺寸提供者
final canvasSizeProvider = Provider<Size?>((ref) {
  return ref.watch(canvasStateProvider).size;
});

/// 画布加载状态提供者
final canvasLoadingProvider = Provider<bool>((ref) {
  return ref.watch(canvasStateProvider).isLoading;
});

/// 画布网格显示状态提供者
final canvasShowGridProvider = Provider<bool>((ref) {
  return ref.watch(canvasStateProvider).showGrid;
});

/// 画布标尺显示状态提供者
final canvasShowRulerProvider = Provider<bool>((ref) {
  return ref.watch(canvasStateProvider).showRuler;
});
