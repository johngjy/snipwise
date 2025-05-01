import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_painter/flutter_painter.dart';
import '../../application/providers/editor_providers.dart';
import '../../domain/models/tool_type.dart';
import 'editor_toolbar.dart';
import 'style_toolbar.dart';
import 'cached_text_dialog.dart';

/// 画板编辑器组件 - 集成flutter_painter实现绘图标注功能
class PainterEditor extends ConsumerWidget {
  /// 构造函数
  const PainterEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final cachedTexts = ref.watch(cachedTextsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 顶部工具栏
          EditorToolbar(
            selectedTool: editorState.selectedTool,
            canUndo: editorState.canUndo,
            canRedo: editorState.canRedo,
            hasUnsavedChanges: editorState.hasUnsavedChanges,
            onToolSelected: (tool) {
              ref.read(editorStateProvider.notifier).selectTool(tool);
            },
            onUndo: () {
              ref.read(editorStateProvider.notifier).undo();
            },
            onRedo: () {
              ref.read(editorStateProvider.notifier).redo();
            },
            onClearAll: () {
              ref.read(editorStateProvider.notifier).clearAll();
            },
            onShowTextCache: () {
              ref
                  .read(editorStateProvider.notifier)
                  .toggleTextCacheVisibility();
            },
            onExportImage: () async {
              final imageData =
                  await ref.read(editorStateProvider.notifier).exportImage();
              if (imageData != null) {
                // 处理导出的图片数据
                // 例如：保存到文件或分享
              }
            },
          ),

          // 主要编辑区域
          Expanded(
            child: Stack(
              children: [
                // 绘图区域
                if (editorState.painterController != null)
                  FlutterPainter(
                    controller: editorState.painterController!,
                  )
                else
                  const Center(
                    child: Text('请加载图片'),
                  ),

                // 样式工具栏 - 基于当前选择的工具显示不同选项
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: StyleToolbar(
                    toolType: editorState.selectedTool,
                    settings: editorState.currentToolSettings,
                    onSettingsChanged: (settings) {
                      ref
                          .read(editorStateProvider.notifier)
                          .updateToolSettings(settings);
                    },
                  ),
                ),

                // 文本缓存对话框
                if (editorState.isTextCacheVisible)
                  CachedTextDialog(
                    texts: cachedTexts,
                    onClose: () {
                      ref
                          .read(editorStateProvider.notifier)
                          .toggleTextCacheVisibility();
                    },
                    onClearAll: () {
                      ref.read(cachedTextsProvider.notifier).clearAll();
                    },
                    onRemoveText: (text) {
                      ref.read(cachedTextsProvider.notifier).removeText(text);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
