import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/editor_state_notifier.dart';
import '../notifiers/layout_notifier.dart';
import '../notifiers/tool_notifier.dart';
import '../notifiers/annotation_notifier.dart';
import '../notifiers/wallpaper_settings_notifier.dart';
import '../notifiers/canvas_transform_notifier.dart';
import '../states/editor_state.dart';
import '../states/layout_state.dart';
import '../states/tool_state.dart';
import '../states/annotation_state.dart';
import '../states/wallpaper_settings_state.dart';
import '../states/canvas_transform_state.dart' as cts;
import '../core/editor_state_core.dart';

/// 编辑器核心状态提供者
/// 集中管理和协调所有编辑器相关状态
final editorStateCoreProvider = Provider<EditorStateCore>((ref) {
  return EditorStateCore(ref);
});

/// 编辑器基础状态提供者
/// 管理图像数据、尺寸和基本显示配置
final editorStateProvider =
    NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});

/// 布局管理提供者
/// 处理编辑器布局、窗口尺寸和自动适应
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(() {
  return LayoutNotifier();
});

/// 标注管理提供者
/// 处理绘制对象和注释
final annotationProvider =
    NotifierProvider<AnnotationNotifier, AnnotationState>(() {
  return AnnotationNotifier();
});

/// 工具管理提供者
/// 处理当前选中的工具和工具设置
final toolProvider = NotifierProvider<ToolNotifier, ToolState>(() {
  return ToolNotifier();
});

/// 画布变换提供者
/// 管理画布的缩放、平移和变换操作
final canvasTransformProvider =
    StateNotifierProvider<CanvasTransformNotifier, cts.CanvasTransformState>(
        (ref) {
  return CanvasTransformNotifier(ref);
});

/// 壁纸设置提供者
/// 管理壁纸背景类型、颜色、边距等设置
final wallpaperSettingsProvider =
    StateNotifierProvider<WallpaperSettingsNotifier, WallpaperSettingsState>(
        (ref) {
  return WallpaperSettingsNotifier();
});

/// 工具栏可见性提供者
/// 管理顶部和底部工具栏的显示状态
final toolbarVisibilityProvider = StateProvider<bool>((ref) => true);

/// 壁纸面板可见性提供者
/// 管理壁纸设置面板的显示与隐藏
final wallpaperPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// 当前工具字符串提供者
/// 将枚举类型转换为字符串，便于UI使用
final currentToolProvider = Provider<String>((ref) {
  final toolState = ref.watch(toolProvider);
  final tool = toolState.currentTool;

  switch (tool) {
    case EditorTool.select:
      return 'select';
    case EditorTool.rectangle:
      return 'rectangle';
    case EditorTool.ellipse:
      return 'ellipse';
    case EditorTool.line:
      return 'line';
    case EditorTool.arrow:
      return 'arrow';
    case EditorTool.text:
      return 'text';
    case EditorTool.highlight:
      return 'highlight';
    case EditorTool.freehand:
      return 'freehand';
    case EditorTool.erase:
      return 'rubber';
    case EditorTool.crop:
      return 'crop';
    default:
      return 'select';
  }
});
