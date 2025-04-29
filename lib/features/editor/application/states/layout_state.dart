import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 编辑器布局状态类
class LayoutState extends Equatable {
  /// 可用屏幕尺寸
  final Size? availableScreenSize;

  /// 最小画布尺寸
  final Size minCanvasSize;

  /// 编辑器窗口尺寸
  final Size editorWindowSize;

  /// 当前画布视觉尺寸
  final Size currentCanvasViewSize;

  /// 历史面板是否打开
  final bool isHistoryPanelOpen;

  /// 顶部工具栏高度
  final double topToolbarHeight;

  /// 底部工具栏高度
  final double bottomToolbarHeight;

  /// 用户是否手动调整过窗口大小
  final bool userHasManuallyResized;

  const LayoutState({
    this.availableScreenSize,
    required this.minCanvasSize,
    required this.editorWindowSize,
    required this.currentCanvasViewSize,
    this.isHistoryPanelOpen = false,
    this.topToolbarHeight = 38.0,
    this.bottomToolbarHeight = 38.0,
    this.userHasManuallyResized = false,
  });

  /// 创建初始状态
  factory LayoutState.initial() => const LayoutState(
        minCanvasSize: Size(900, 500),
        editorWindowSize: Size(900, 576), // 包含了工具栏高度
        currentCanvasViewSize: Size(900, 500),
      );

  /// 计算工具栏总高度
  double get totalToolbarHeight => topToolbarHeight + bottomToolbarHeight;

  /// 获取最小窗口基础尺寸
  Size get minWindowBaseSize =>
      Size(minCanvasSize.width, minCanvasSize.height + totalToolbarHeight);

  /// 获取最大画布尺寸
  Size? get maxCanvasSize {
    if (availableScreenSize == null) return null;

    const double screenEdgeMargin = 20.0; // 窗口距离屏幕边缘的固定视觉边距
    return Size(
      availableScreenSize!.width - screenEdgeMargin * 2,
      availableScreenSize!.height - screenEdgeMargin * 2 - totalToolbarHeight,
    );
  }

  /// 使用copyWith创建新实例
  LayoutState copyWith({
    Size? availableScreenSize,
    Size? minCanvasSize,
    Size? editorWindowSize,
    Size? currentCanvasViewSize,
    bool? isHistoryPanelOpen,
    double? topToolbarHeight,
    double? bottomToolbarHeight,
    bool? userHasManuallyResized,
  }) {
    return LayoutState(
      availableScreenSize: availableScreenSize ?? this.availableScreenSize,
      minCanvasSize: minCanvasSize ?? this.minCanvasSize,
      editorWindowSize: editorWindowSize ?? this.editorWindowSize,
      currentCanvasViewSize:
          currentCanvasViewSize ?? this.currentCanvasViewSize,
      isHistoryPanelOpen: isHistoryPanelOpen ?? this.isHistoryPanelOpen,
      topToolbarHeight: topToolbarHeight ?? this.topToolbarHeight,
      bottomToolbarHeight: bottomToolbarHeight ?? this.bottomToolbarHeight,
      userHasManuallyResized:
          userHasManuallyResized ?? this.userHasManuallyResized,
    );
  }

  @override
  List<Object?> get props => [
        availableScreenSize,
        minCanvasSize,
        editorWindowSize,
        currentCanvasViewSize,
        isHistoryPanelOpen,
        topToolbarHeight,
        bottomToolbarHeight,
        userHasManuallyResized,
      ];
}
