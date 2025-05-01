import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 导入flutter_painter_v2的主入口文件
import 'package:flutter_painter_v2/flutter_painter.dart';

import 'tool_type.dart';
import 'tool_settings.dart';

part 'editor_state.freezed.dart';

/// 编辑器状态 - 管理编辑器整体状态
@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    /// 当前选择的工具
    @Default(ToolType.select) ToolType selectedTool,

    /// 系统默认设置
    @Default(ToolSettings()) ToolSettings defaultSettings,

    /// 各工具专属设置
    @Default({}) Map<ToolType, ToolSettings> toolSettings,
    
    /// 画布控制器
    @JsonKey(includeFromJson: false, includeToJson: false)
    PainterController? painterController,

    /// 是否有未保存的更改
    @Default(false) bool hasUnsavedChanges,

    /// 可撤销操作数量
    @Default(0) int undoableActionsCount,

    /// 可重做操作数量
    @Default(0) int redoableActionsCount,

    /// 所选对象列表
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<Drawable> selectedObjects,

    /// 缓存的文本内容是否可见
    @Default(false) bool isTextCacheVisible,

    /// 原始截图尺寸 (可选)
    Size? originalImageSize,

    /// 背景边距 (可选)
    @Default(EdgeInsets.zero) EdgeInsets wallpaperPadding,
    
    /// 是否正在加载
    @Default(false) bool isLoading,
    
    /// 截图数据
    Uint8List? screenshotData,
  }) = _EditorState;

  /// 私有构造函数，用于扩展方法
  const EditorState._();

  /// 获取当前工具的设置
  ToolSettings get currentToolSettings {
    return toolSettings[selectedTool] ?? defaultSettings;
  }

  /// 是否有选中对象
  bool get hasSelectedObjects => selectedObjects.isNotEmpty;

  /// 是否可撤销
  bool get canUndo => undoableActionsCount > 0;

  /// 是否可重做
  bool get canRedo => redoableActionsCount > 0;
}
