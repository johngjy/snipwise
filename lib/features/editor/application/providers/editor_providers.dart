import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_painter/flutter_painter.dart'; // Keep commented out
import '../../domain/models/tool_type.dart';
// Alias domain imports to avoid conflicts
import '../../domain/models/tool_settings.dart' as domain_tool_settings;
import '../../domain/models/editor_state.dart' as domain_editor_state;
import '../../domain/models/cached_text.dart';
import '../notifiers/annotation_notifier.dart';
import '../notifiers/canvas_transform_notifier.dart';
// import '../notifiers/editor_state_notifier.dart'; // Remove unused import (Notifier defined below)
import '../notifiers/layout_notifier.dart';
import '../notifiers/tool_notifier.dart';
import '../states/annotation_state.dart';
import '../states/canvas_transform_state.dart';
// Alias application state imports if they are different and needed, otherwise remove if unused
// import '../states/editor_state.dart' as app_editor_state;
import '../states/layout_state.dart';
import '../states/tool_state.dart';
import 'package:logger/logger.dart'; // Import logger

// Get a logger instance
final _logger = Logger();

/// 布局管理Provider
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(() {
  return LayoutNotifier();
});

/// 编辑器状态Provider
final editorStateProvider =
    NotifierProvider<EditorStateNotifier, domain_editor_state.EditorState>(() {
  return EditorStateNotifier();
});

/// 画布变换Provider
final canvasTransformProvider =
    NotifierProvider<CanvasTransformNotifier, CanvasTransformState>(() {
  return CanvasTransformNotifier();
});

/// 标注管理Provider
final annotationProvider =
    NotifierProvider<AnnotationNotifier, AnnotationState>(() {
  return AnnotationNotifier();
});

/// 工具管理Provider
final toolProvider = NotifierProvider<ToolNotifier, ToolState>(() {
  return ToolNotifier();
});

/// 滚动条显示Provider
final showScrollbarsProvider = Provider<bool>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  // Use layoutProvider instead of layoutSizeProvider
  final layout = ref.watch(layoutProvider);
  // Get original image size from editorStateProvider
  final originalImageSize =
      ref.watch(editorStateProvider.select((s) => s.originalImageSize));

  // Check if originalImageSize is available
  if (originalImageSize == null) {
    return false; // Cannot determine if scrollbars are needed without image size
  }

  // 当缩放比例小于1或者布局尺寸小于原始图片尺寸时显示滚动条
  // Use zoomLevel from transform and currentCanvasViewSize from layout
  final needsScrollbars = transform.zoomLevel < 1.0 ||
      (layout.currentCanvasViewSize.width < originalImageSize.width ||
          layout.currentCanvasViewSize.height < originalImageSize.height);

  return needsScrollbars;
});

/// 图片提供者 - 提供当前正在编辑的图片
final imageProvider = StateProvider<ui.Image?>((ref) => null);

/// 标尺显示Provider (New)
final showRulersProvider = StateProvider<bool>((ref) => false);

/// 按键修饰符Provider (New) - e.g., for Shift key status
final keyModifierProvider = StateProvider<bool>((ref) => false);

/// 编辑器状态通知器 - 处理编辑器状态变更
class EditorStateNotifier
    extends StateNotifier<domain_editor_state.EditorState> {
  // Use the aliased domain state here and in super()
  EditorStateNotifier() : super(const domain_editor_state.EditorState());
  
  /// 重置所有状态
  void resetAllState() {
    _logger.d('重置编辑器状态');
    state = const domain_editor_state.EditorState();
  }
  
  /// 设置加载状态
  void setLoading(bool isLoading) {
    _logger.d('设置加载状态: $isLoading');
    state = state.copyWith(isLoading: isLoading);
  }
  
  /// 加载截图并计算布局
  /// 返回初始缩放比例
  double loadScreenshotWithLayout(Uint8List? imageData, Size imageSize) {
    _logger.d('加载截图数据，图片尺寸: $imageSize');
    
    if (imageData == null) {
      _logger.w('截图数据为空');
      return 1.0;
    }
    
    // 更新图片数据和尺寸
    state = state.copyWith(
      screenshotData: imageData,
      originalImageSize: imageSize,
    );
    
    // 计算初始缩放比例 (简单实现，实际可能需要更复杂的逻辑)
    return 1.0;
  }

  /// 初始化画布控制器 (Commented out due to flutter_painter issues)
  /*
  void initializePainterController(ui.Image image) {
    // 创建背景图层
    final backgroundDrawable = BackgroundDrawable(
      image: image,
    );

    // 创建控制器
    final controller = PainterController(
      drawables: [backgroundDrawable],
    );

    // 设置控制器监听器
    controller.addListener(_onPainterControllerChanged);

    // 更新状态
    state = state.copyWith(
      painterController: controller,
      hasUnsavedChanges: false,
      undoableActionsCount: 0,
      redoableActionsCount: 0,
    );
  }
  */

  /// 控制器变更回调 (Commented out)
  /*
  void _onPainterControllerChanged() {
    if (state.painterController == null) return;

    state = state.copyWith(
      hasUnsavedChanges: true,
      undoableActionsCount: state.painterController!.undoableActionsCount,
      redoableActionsCount: state.painterController!.redoableActionsCount,
    );
  }
  */

  /// 选择工具
  void selectTool(ToolType tool) {
    state = state.copyWith(selectedTool: tool);

    // 根据工具类型设置控制器模式 (Commented out)
    /*
    if (state.painterController != null) {
      switch (tool) {
        case ToolType.select:
          state.painterController!.mode = PainterMode.selectObject;
          break;
        case ToolType.rectangle:
          state.painterController!.mode = PainterMode.shape;
          state.painterController!.shapeFactory = RectangleFactory();
          break;
        case ToolType.arrow:
          state.painterController!.mode = PainterMode.shape;
          state.painterController!.shapeFactory = ArrowFactory();
          break;
        case ToolType.freedraw:
          state.painterController!.mode = PainterMode.freeStyle;
          break;
        case ToolType.text:
          state.painterController!.mode = PainterMode.text;
          break;
      }
    }
    */
  }

  /// 更新工具设置
  void updateToolSettings(domain_tool_settings.ToolSettings settings) {
    // 更新当前工具的设置
    final updatedToolSettings =
        Map<ToolType, domain_tool_settings.ToolSettings>.from(
            state.toolSettings);
    updatedToolSettings[state.selectedTool] = settings;

    state = state.copyWith(toolSettings: updatedToolSettings);

    // 更新控制器设置 (Commented out)
    /*
    if (state.painterController != null) {
      var currentSettings = state.painterController!.settings;
      switch (state.selectedTool) {
        case ToolType.rectangle:
        case ToolType.arrow:
          currentSettings = currentSettings.copyWith(
            shape: currentSettings.shape?.copyWith(
                  color: settings.strokeColor,
                  strokeWidth: settings.strokeWidth,
                ) ??
                ShapeSettings(
                  color: settings.strokeColor,
                  strokeWidth: settings.strokeWidth,
                ),
          );
          break;
        case ToolType.freedraw:
          currentSettings = currentSettings.copyWith(
            freeStyle: currentSettings.freeStyle?.copyWith(
                  color: settings.strokeColor,
                  strokeWidth: settings.strokeWidth,
                ) ??
                FreeStyleSettings(
                  color: settings.strokeColor,
                  strokeWidth: settings.strokeWidth,
                ),
          );
          break;
        case ToolType.text:
          currentSettings = currentSettings.copyWith(
            text: currentSettings.text?.copyWith(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                  textColor: settings.textColor,
                ) ??
                TextSettings(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                  textColor: settings.textColor,
                ),
          );
          break;
        default:
          break;
      }
      state.painterController!.settings = currentSettings;
    }
    */
  }

  /// 撤销操作 (Commented out)
  /*
  void undo() {
    state.painterController?.undo();
  }
  */

  /// 重做操作 (Commented out)
  /*
  void redo() {
    state.painterController?.redo();
  }
  */

  /// 清除所有标注 (Commented out)
  /*
  void clearAll() {
    state.painterController?.clearDrawables();
  }
  */

  /// 导出图片 (Commented out)
  /*
  Future<Uint8List?> exportImage() async {
    return await state.painterController?.exportImage();
  }
  */

  /// 切换文本缓存可见性
  void toggleTextCacheVisibility() {
    state = state.copyWith(isTextCacheVisible: !state.isTextCacheVisible);
  }

  // Add the missing method definition (empty for now)
  void updateWallpaperPaddingWithLayout(EdgeInsets padding) {
    // TODO: Implement logic if needed, or rely on the method in the actual EditorStateNotifier
    // print('Warning: updateWallpaperPaddingWithLayout called on commented-out Notifier'); // Replace print
    _logger
        .w('updateWallpaperPaddingWithLayout called on commented-out Notifier');
  }

  @override
  void dispose() {
    // state.painterController?.removeListener(_onPainterControllerChanged); // Commented out
    // state.painterController?.dispose(); // Commented out
    super.dispose();
  }
}

/// 缓存文本提供者 - 管理界面上的文本缓存
final cachedTextsProvider =
    StateNotifierProvider<CachedTextsNotifier, List<CachedText>>((ref) {
  return CachedTextsNotifier();
});

/// 缓存文本通知器 - 处理文本缓存变更
class CachedTextsNotifier extends StateNotifier<List<CachedText>> {
  CachedTextsNotifier() : super([]);

  /// 添加文本到缓存
  void addText(String content, {String source = '文本标注'}) {
    final newText = CachedText(
      content: content,
      source: source,
      timestamp: DateTime.now(),
    );

    state = [...state, newText];
  }

  /// 清除所有缓存文本
  void clearAll() {
    state = [];
  }

  /// 删除特定缓存文本
  void removeText(CachedText text) {
    state = state.where((t) => t != text).toList();
  }
}
