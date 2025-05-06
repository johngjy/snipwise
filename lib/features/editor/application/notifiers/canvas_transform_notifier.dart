import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:equatable/equatable.dart';

import '../states/canvas_transform_state.dart' as cts;
import '../providers/editor_providers.dart';
import '../providers/painter_providers.dart';

/// 画布变换状态
class CanvasTransformState extends Equatable {
  /// 缩放级别
  final double zoomLevel;

  /// 画布偏移量
  final Offset canvasOffset;

  /// 构造函数
  const CanvasTransformState({
    required this.zoomLevel,
    required this.canvasOffset,
  });

  /// 创建初始状态
  factory CanvasTransformState.initial() => const CanvasTransformState(
        zoomLevel: 1.0,
        canvasOffset: Offset.zero,
      );

  /// 使用copyWith创建新实例
  CanvasTransformState copyWith({
    double? zoomLevel,
    Offset? canvasOffset,
  }) {
    return CanvasTransformState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      canvasOffset: canvasOffset ?? this.canvasOffset,
    );
  }

  @override
  List<Object?> get props => [zoomLevel, canvasOffset];

  /// 最小缩放级别
  static const double minZoom = 0.1;

  /// 最大缩放级别
  static const double maxZoom = 5.0;
}

/// 画布变换通知器
/// 管理画布的缩放和平移状态
class CanvasTransformNotifier extends StateNotifier<cts.CanvasTransformState> {
  /// WidgetRef
  final Ref ref;

  /// 上次缩放值
  double _lastScale = 1.0;

  /// 缩放开始位置
  // Offset? _scaleStartFocalPoint; // Marked as unused, removing for now

  /// 视图尺寸
  Size? _viewSize;

  /// 内容尺寸
  Size? _contentSize;

  /// 构造函数
  CanvasTransformNotifier(this.ref) : super(cts.CanvasTransformState.initial());

  /// 设置初始缩放比例
  /// 通常在加载新内容或适配窗口时调用
  void setInitialScale(double scale) {
    final clampedScale = scale.clamp(
      cts.CanvasTransformState.minZoom,
      cts.CanvasTransformState.maxZoom,
    );
    state = state.copyWith(
      zoomLevel: clampedScale,
      canvasOffset: Offset.zero, // Reset offset when setting initial scale
    );
    // 同步更新 PainterController 和全局状态
    _updatePainterControllerTransform();
    ref.read(canvasScaleProvider.notifier).state = clampedScale;
    if (kDebugMode) {
      print('🐛 Initial scale set to: $clampedScale');
    }
  }

  /// 设置缩放级别
  void setZoomLevel(double zoomLevel, {Offset? focalPoint}) {
    // 约束缩放级别在合理范围内
    final constrainedZoom = zoomLevel.clamp(
        cts.CanvasTransformState.minZoom, cts.CanvasTransformState.maxZoom);

    if (kDebugMode) {
      print(
          '🐛 Setting zoom level: $constrainedZoom, Focal Point: $focalPoint');
    }

    // 计算新的缩放值相对于当前缩放值的比例
    final currentZoom = state.zoomLevel;
    final scaleRatio = constrainedZoom / currentZoom;

    // 如果缩放比例接近1，表示几乎没有变化，直接返回
    if ((scaleRatio - 1.0).abs() < 0.001) {
      return;
    }

    // 获取当前偏移量
    Offset currentOffset = state.canvasOffset;

    // 如果提供了焦点，计算新的偏移量以保持焦点位置
    if (focalPoint != null) {
      // 计算焦点相对于当前偏移量的位置
      final focalPointX = focalPoint.dx - currentOffset.dx;
      final focalPointY = focalPoint.dy - currentOffset.dy;

      // 计算新的偏移量
      final newOffsetX = focalPoint.dx - focalPointX * scaleRatio;
      final newOffsetY = focalPoint.dy - focalPointY * scaleRatio;

      currentOffset = Offset(newOffsetX, newOffsetY);
    }

    // 更新状态
    state = state.copyWith(
      zoomLevel: constrainedZoom,
      canvasOffset: currentOffset,
    );

    // 同步更新PainterController
    _updatePainterControllerTransform();

    // 更新全局缩放比例状态
    ref.read(canvasScaleProvider.notifier).state = constrainedZoom;
  }

  /// 开始缩放操作 (用于多点触控/手势)
  void startScale(Offset focalPoint) {
    // _scaleStartFocalPoint = focalPoint; // Not used currently
    _lastScale = 1.0; // Reset last scale factor for relative scaling
  }

  /// 更新缩放操作 (用于多点触控/手势)
  void updateScale(double scale, Offset focalPoint) {
    // 计算相对于上一次更新的缩放增量
    final scaleDelta = scale / _lastScale;
    _lastScale = scale; // Update last scale factor for next update

    // 计算基于增量的新缩放级别
    final newZoomLevel = state.zoomLevel * scaleDelta;

    // 设置新的缩放级别，使用手势焦点作为缩放中心点
    setZoomLevel(newZoomLevel, focalPoint: focalPoint);
  }

  /// 更新平移操作 (用于拖拽)
  void updateTranslation(Offset delta) {
    final currentOffset = state.canvasOffset;
    final newOffset = Offset(
      currentOffset.dx + delta.dx,
      currentOffset.dy + delta.dy,
    );

    state = state.copyWith(canvasOffset: newOffset);

    // 同步更新PainterController
    _updatePainterControllerTransform();
  }

  /// 结束缩放操作 (用于多点触控/手势)
  void endScale() {
    // _scaleStartFocalPoint = null; // Not used currently
    _lastScale = 1.0; // Reset scale factor
  }

  /// 设置视图尺寸 (用于内容居中计算)
  void setViewSize(Size size) {
    _viewSize = size;
    _adjustContentPosition();
  }

  /// 设置内容尺寸 (用于内容居中计算)
  void setContentSize(Size size) {
    _contentSize = size;
    _adjustContentPosition();
  }

  /// 根据视图和内容尺寸调整内容位置 (居中)
  void _adjustContentPosition() {
    if (_viewSize != null && _contentSize != null) {
      _centerContent(_contentSize!, _viewSize!, state.zoomLevel);
    }
  }

  /// 将内容居中显示
  void _centerContent(Size contentSize, Size viewSize, double scale) {
    // 计算缩放后的内容尺寸
    final double scaledWidth = contentSize.width * scale;
    final double scaledHeight = contentSize.height * scale;

    // 计算居中时的偏移量
    final double offsetX = (viewSize.width - scaledWidth) / 2;
    final double offsetY = (viewSize.height - scaledHeight) / 2;

    // 更新状态
    state = state.copyWith(
      canvasOffset: Offset(offsetX, offsetY),
    );
    // Make sure to sync after centering
    _updatePainterControllerTransform();
  }

  /// 平移画布 (辅助方法, 可选)
  void panCanvas(Offset delta) {
    updateTranslation(delta);
  }

  /// 重置变换
  void resetTransform() {
    state = cts.CanvasTransformState.initial();

    // 同步更新全局缩放比例状态
    ref.read(canvasScaleProvider.notifier).state = state.zoomLevel;
    // Sync painter controller
    _updatePainterControllerTransform();
  }

  /// 鼠标滚轮缩放处理
  void handleMouseWheelZoom(PointerScrollEvent event, Offset localPosition) {
    // 计算缩放增量 - 向上滚动放大，向下滚动缩小
    final delta = event.scrollDelta.dy;
    // Use smaller factor for smoother zoom
    final scaleFactor = delta > 0 ? 0.98 : 1.02;

    // 计算新的缩放级别
    final newZoomLevel = state.zoomLevel * scaleFactor;

    // 设置新的缩放级别，使用鼠标位置作为焦点
    setZoomLevel(newZoomLevel, focalPoint: localPosition);
  }

  /// 同步更新PainterController的变换
  /// 将当前的缩放和平移应用到PainterController
  void _updatePainterControllerTransform() {
    // Add safety check: Although StateNotifier doesn't have `mounted`,
    // we rely on Riverpod to handle disposal. Accessing `ref` might still be unsafe
    // if called within a disposed context (e.g., delayed future).
    // However, direct calls within the notifier methods should be safe.
    try {
      // 获取PainterController实例 - 使用read而非watch避免循环依赖
      final controllerState = ref.read(painterControllerProvider);

      // 安全地获取工具实例
      final utils = ref.read(painterProvidersUtilsProvider);

      // 设置缩放级别 (Using placeholder implementation)
      utils.setZoomLevel(controllerState, state.zoomLevel);

      // 设置平移量 (Using placeholder implementation)
      utils.setTranslation(controllerState, state.canvasOffset);

      if (kDebugMode) {
        print(
            'PainterController变换同步 - 缩放: ${state.zoomLevel}, 偏移: ${state.canvasOffset}');
      }
    } catch (e) {
      // Catch potential errors if providers are disposed, etc.
      if (kDebugMode) {
        print('更新PainterController变换失败: $e');
      }
    }
  }
}

/// 画布变换Provider
/// 管理画布的缩放和平移状态
final canvasTransformProvider =
    StateNotifierProvider<CanvasTransformNotifier, cts.CanvasTransformState>(
        (ref) {
  return CanvasTransformNotifier(ref);
});

/// 画布缩放Provider
/// 提供当前画布的缩放级别
final canvasScaleProvider = StateProvider<double>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  return transformState.zoomLevel;
});
