import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../core/editor_state_core.dart';
import '../notifiers/canvas_notifier.dart';
import '../states/canvas_state.dart';
import 'wallpaper_providers.dart'; // 显式导入以解决未定义错误

// 重新导出壁纸相关所有提供者
export 'wallpaper_providers.dart';

/// 画布状态提供者
/// 提供对画布状态的访问和管理
final canvasProvider =
    StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});

/// 编辑器核心状态管理器提供者
/// 提供对核心状态管理器的访问，用于协调各状态间的交互
final editorStateCoreProvider = Provider<EditorStateCore>((ref) {
  return EditorStateCore(ref);
});

/// 画布是否溢出视口提供者
/// 判断当前画布内容是否超出可视区域
final canvasOverflowProvider = Provider<bool>((ref) {
  final canvasState = ref.watch(canvasProvider);
  return canvasState.isOverflowing;
});

/// 加载状态提供者
/// 提供当前编辑器是否在加载中的状态
final isLoadingProvider = Provider<bool>((ref) {
  final canvasState = ref.watch(canvasProvider);
  return canvasState.isLoading;
});

/// 画布背景装饰提供者 - 已弃用
/// 请使用wallpaperDecorationProvider替代
@Deprecated('Use wallpaperDecorationProvider instead')
final canvasBackgroundDecorationProvider = Provider<BoxDecoration?>((ref) {
  return ref.watch(wallpaperDecorationProvider);
});
