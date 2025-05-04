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

  /// 上次更新时间戳，用于平滑处理
  int _lastUpdateTimestamp = 0;

  /// 防抖时间间隔(毫秒)
  static const int _debounceInterval = 16; // 约60fps

  /// 视图尺寸
  Size? _viewSize;

  /// 内容尺寸
  Size? _contentSize;

  /// 日志工具
  final Logger _logger = Logger();

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

  /// 同时设置缩放级别和偏移量
  /// 用于复杂的变换操作，如鼠标滚轮缩放
  void setZoomAndOffset(double zoomLevel, Offset offset) {
    // 当前时间戳
    final now = DateTime.now().millisecondsSinceEpoch;

    // 如果更新太频繁，考虑跳过一些帧以提高性能
    if (now - _lastUpdateTimestamp < _debounceInterval) {
      return;
    }

    _lastUpdateTimestamp = now;

    final clampedZoom = zoomLevel.clamp(
      cts.CanvasTransformState.minZoom,
      cts.CanvasTransformState.maxZoom,
    );

    // 验证偏移量是否合理 - 在某些极端情况下可能会导致NaN或Infinity
    if (offset.dx.isNaN ||
        offset.dy.isNaN ||
        offset.dx.isInfinite ||
        offset.dy.isInfinite) {
      _logger.e("检测到无效的偏移量: $offset, 使用当前偏移量代替");
      offset = state.canvasOffset;
    }

    state = state.copyWith(
      zoomLevel: clampedZoom,
      canvasOffset: offset,
    );

    // 同步更新PainterController
    _updatePainterControllerTransform();

    // 更新全局缩放比例状态
    ref.read(canvasScaleProvider.notifier).state = clampedZoom;
  }

  /// 设置缩放级别
  /// 调整为不使用命名参数，以适应多个调用点
  void setZoomLevel(double zoomLevel) {
    // 限制缩放范围
    final clampedZoom = zoomLevel.clamp(
      cts.CanvasTransformState.minZoom,
      cts.CanvasTransformState.maxZoom,
    );

    // 应用新状态
    state = state.copyWith(zoomLevel: clampedZoom);

    // 同步更新全局状态和控制器
    _updatePainterControllerTransform();
    ref.read(canvasScaleProvider.notifier).state = clampedZoom;
  }

  /// 更新画布偏移
  void setOffset(Offset offset) {
    // 验证偏移量
    if (offset.dx.isNaN ||
        offset.dy.isNaN ||
        offset.dx.isInfinite ||
        offset.dy.isInfinite) {
      _logger.e("检测到无效的偏移量: $offset, 忽略此次更新");
      return;
    }

    state = state.copyWith(canvasOffset: offset);
    _updatePainterControllerTransform();
  }

  /// 开始缩放操作
  void startScale(Offset focalPoint) {
    // 重置追踪数据
    _lastScale = 1.0;
    _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      state = state.copyWith(
        isScaling: true,
        scaleStartFocalPoint: focalPoint,
        scaleStartZoomLevel: state.zoomLevel,
      );
    } catch (e) {
      // 处理可能的错误，例如属性不存在
      _logger.e("启动缩放时出错: $e");
    }
  }

  /// 更新缩放
  void updateScale(double scale, Offset focalPoint) {
    try {
      // 防止状态错误
      if (!state.isScaling) {
        startScale(focalPoint);
        return;
      }

      // 当前时间戳
      final now = DateTime.now().millisecondsSinceEpoch;

      // 如果更新太频繁，考虑跳过一些帧以提高性能
      if (now - _lastUpdateTimestamp < _debounceInterval) {
        return;
      }

      _lastUpdateTimestamp = now;

      // 计算平滑的缩放增量 - 避免突然的变化
      double effectiveScale = scale;
      if (_lastScale != 0) {
        // 使用较小的增量来平滑缩放
        final double deltaScale = scale / _lastScale;
        effectiveScale = 1.0 + (deltaScale - 1.0) * 0.7; // 减少增量的70%
      }
      _lastScale = scale;

      // 计算新的缩放级别，应用限制
      final baseZoomLevel = state.scaleStartZoomLevel > 0
          ? state.scaleStartZoomLevel
          : state.zoomLevel;

      final newZoomLevel = (baseZoomLevel * effectiveScale).clamp(
        cts.CanvasTransformState.minZoom,
        cts.CanvasTransformState.maxZoom,
      );

      // 如果焦点无效，使用中心点
      if (focalPoint.dx.isNaN ||
          focalPoint.dy.isNaN ||
          focalPoint.dx.isInfinite ||
          focalPoint.dy.isInfinite) {
        focalPoint =
            Offset(_viewSize?.width ?? 500 / 2, _viewSize?.height ?? 400 / 2);
      }

      // 计算偏移量
      final currentOffset = state.canvasOffset;
      final scaleRatio = newZoomLevel / state.zoomLevel;

      final focalPointX = focalPoint.dx - currentOffset.dx;
      final focalPointY = focalPoint.dy - currentOffset.dy;

      final newOffsetX = focalPoint.dx - focalPointX * scaleRatio;
      final newOffsetY = focalPoint.dy - focalPointY * scaleRatio;

      // 应用缩放变化和新的偏移量
      state = state.copyWith(
          zoomLevel: newZoomLevel,
          canvasOffset: Offset(newOffsetX, newOffsetY));

      // 同步更新全局状态和控制器
      _updatePainterControllerTransform();
      ref.read(canvasScaleProvider.notifier).state = newZoomLevel;
    } catch (e) {
      // 处理更新过程中的错误
      _logger.e("更新缩放时出错: $e");
    }
  }

  /// 更新平移
  void updateTranslation(Offset delta) {
    try {
      // 防止无效的输入
      if (delta.dx.isNaN ||
          delta.dy.isNaN ||
          delta.dx.isInfinite ||
          delta.dy.isInfinite) {
        _logger.e("检测到无效的偏移增量: $delta, 忽略此次更新");
        return;
      }

      // 限制单次平移的最大距离，避免突然的大幅移动
      final maxDelta = 100.0;
      final safeDelta = Offset(delta.dx.clamp(-maxDelta, maxDelta),
          delta.dy.clamp(-maxDelta, maxDelta));

      final newOffset = state.canvasOffset + safeDelta;
      state = state.copyWith(canvasOffset: newOffset);
      _updatePainterControllerTransform();
    } catch (e) {
      _logger.e("更新平移时出错: $e");
    }
  }

  /// 结束缩放操作
  void endScale() {
    try {
      state = state.copyWith(
        isScaling: false,
        scaleStartFocalPoint: null,
      );

      // 重置追踪值
      _lastScale = 1.0;
    } catch (e) {
      _logger.e("结束缩放时出错: $e");
    }
  }

  /// 设置视图尺寸
  void setViewSize(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      _logger.w("尝试设置无效的视图尺寸: $size, 已忽略");
      return;
    }
    _viewSize = size;
  }

  /// 设置内容尺寸
  void setContentSize(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      _logger.w("尝试设置无效的内容尺寸: $size, 已忽略");
      return;
    }
    _contentSize = size;
  }

  /// 自动适应内容到视图
  void fitContentToView() {
    if (_viewSize == null || _contentSize == null) {
      _logger.w("适应内容到视图失败: 尺寸信息不完整");
      return;
    }

    // 确保尺寸有效
    if (_viewSize!.width <= 0 ||
        _viewSize!.height <= 0 ||
        _contentSize!.width <= 0 ||
        _contentSize!.height <= 0) {
      _logger.w("适应内容到视图失败: 无效的尺寸");
      return;
    }

    try {
      // 计算最佳缩放比例
      final widthRatio = _viewSize!.width / _contentSize!.width;
      final heightRatio = _viewSize!.height / _contentSize!.height;
      final fitScale = (widthRatio < heightRatio ? widthRatio : heightRatio)
          .clamp(cts.CanvasTransformState.minZoom,
              cts.CanvasTransformState.maxZoom);

      // 计算居中偏移
      final scaledWidth = _contentSize!.width * fitScale;
      final scaledHeight = _contentSize!.height * fitScale;
      final offsetX = (_viewSize!.width - scaledWidth) / 2;
      final offsetY = (_viewSize!.height - scaledHeight) / 2;

      // 应用变换
      state = state.copyWith(
        zoomLevel: fitScale,
        canvasOffset: Offset(offsetX, offsetY),
      );

      // 同步更新
      _updatePainterControllerTransform();
      ref.read(canvasScaleProvider.notifier).state = fitScale;

      _logger.d("适应内容到视图: 缩放=$fitScale, 偏移=($offsetX, $offsetY)");
    } catch (e) {
      _logger.e("适应内容到视图时出错: $e");
    }
  }

  /// 重置变换
  void resetTransform() {
    try {
      state = cts.CanvasTransformState.initial();
      _updatePainterControllerTransform();
      ref.read(canvasScaleProvider.notifier).state = 1.0;
      _logger.d("重置变换: 缩放=1.0, 偏移=(0,0)");
    } catch (e) {
      _logger.e("重置变换时出错: $e");
    }
  }

  /// 更新PainterController的变换
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
      _logger.e('更新PainterController变换失败: $e');
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
