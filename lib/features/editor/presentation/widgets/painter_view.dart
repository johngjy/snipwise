import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/painter_providers.dart';
import '../../application/providers/editor_providers.dart';
import '../widgets/text_cache_dialog.dart';

/// Painter 视图组件
/// 使用 flutter_painter_v2 实现的绘图编辑器视图
class PainterView extends ConsumerWidget {
  /// 构造函数
  const PainterView({
    super.key,
    this.onDrawableBoundsChanged,
  });

  /// 当绘制对象边界变化时回调
  final Function(Rect?)? onDrawableBoundsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取 PainterController
    final controller = ref.watch(painterControllerProvider);

    // 获取编辑器状态
    final editorState = ref.watch(editorStateProvider);

    // 获取文本缓存对话框显示状态
    final showTextCacheDialog = ref.watch(showTextCacheDialogProvider);

    // 监听绘制对象变化，更新边界
    ref.listen(painterControllerProvider, (previous, current) {
      if (previous?.value.drawables != current.value.drawables) {
        _trackDrawableBounds(ref, current.value.drawables);
      }
    });

    // 如果没有图像数据，显示占位符
    if (editorState.currentImageData == null) {
      return const Center(
        child: Text('请选择或捕获一张图片'),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onPanEnd: (_) => _checkPanEnd(ref),
          child: FlutterPainter(
            key: const ValueKey('painter_view'),
            controller: controller,
            onDrawableCreated: (drawable) => _onDrawableCreated(ref, drawable),
            onDrawableDeleted: (drawable) => _onDrawableDeleted(ref, drawable),
            onSelectedObjectDrawableChanged: (drawable) =>
                _onSelectedObjectDrawableChanged(ref, drawable),
          ),
        ),
        if (kDebugMode)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withAlpha((255 * 0.5).round()),
              child: Consumer(builder: (context, ref, _) {
                final debugScale = ref.watch(canvasScaleProvider);
                return Text(
                  '缩放: ${(debugScale * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              }),
            ),
          ),
        if (showTextCacheDialog)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withAlpha((255 * 0.5).round()),
              child: const Center(
                child: TextCacheDialog(),
              ),
            ),
          ),
      ],
    );
  }

  /// 当创建新的 Drawable 对象时调用
  void _onDrawableCreated(WidgetRef ref, Drawable drawable) {
    // 添加延迟，等待对象完全渲染后再检查边界
    // 对于文本对象尤其重要，因为文本可能需要一些时间来计算正确的尺寸
    Future.delayed(const Duration(milliseconds: 100), () {
      if (drawable is ObjectDrawable) {
        // 如果这是唯一的对象，立即检查边界
        if (ref.read(painterControllerProvider).value.drawables.length == 1) {
          _trackDrawableBounds(ref, [drawable]);
        } else {
          // 否则检查所有对象
          _trackDrawableBounds(
              ref, ref.read(painterControllerProvider).value.drawables);
        }
      }
    });
  }

  /// 当删除 Drawable 对象时调用
  void _onDrawableDeleted(WidgetRef ref, Drawable drawable) {
    // 更新绘制对象边界
    _trackDrawableBounds(
        ref, ref.read(painterControllerProvider).value.drawables);
  }

  /// 当选中的对象变化时调用
  void _onSelectedObjectDrawableChanged(
      WidgetRef ref, ObjectDrawable? drawable) {
    // 更新选中状态
    ref.read(selectedObjectDrawableProvider.notifier).state = drawable;
  }

  /// 监听拖动结束事件，用于替代直接的 onDrawableMoved 和 onDrawableResized
  void _checkPanEnd(WidgetRef ref) {
    // 更新绘制对象边界
    final drawables = ref.read(painterControllerProvider).value.drawables;
    _trackDrawableBounds(ref, drawables);
    if (kDebugMode) {
      print('PainterView: 交互结束，检查对象边界');
    }
  }

  /// 跟踪所有 drawable 的边界矩形
  void _trackDrawableBounds(WidgetRef ref, List<Drawable> drawables) {
    if (drawables.isEmpty) {
      // 如果没有对象，清除边界
      if (onDrawableBoundsChanged != null) {
        onDrawableBoundsChanged!(null);
      }
      return;
    }

    // 计算所有 drawable 的边界矩形
    Rect? boundingRect = _calculateBoundingRect(drawables);

    if (boundingRect != null && onDrawableBoundsChanged != null) {
      onDrawableBoundsChanged!(boundingRect);
    }

    if (kDebugMode && boundingRect != null) {
      print('PainterView: 绘制对象边界 = $boundingRect, 对象数量: ${drawables.length}');
    }
  }

  /// 计算所有 drawable 的边界矩形
  Rect? _calculateBoundingRect(List<Drawable> drawables) {
    if (drawables.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    bool hasValidBounds = false;

    for (var drawable in drawables) {
      Rect? bounds = _getDrawableBounds(drawable);
      if (bounds != null) {
        minX = math.min(minX, bounds.left);
        minY = math.min(minY, bounds.top);
        maxX = math.max(maxX, bounds.right);
        maxY = math.max(maxY, bounds.bottom);
        hasValidBounds = true;
      }
    }

    if (!hasValidBounds) return null;

    return Rect.fromLTRB(minX.isFinite ? minX : 0, minY.isFinite ? minY : 0,
        maxX.isFinite ? maxX : 0, maxY.isFinite ? maxY : 0);
  }

  /// 获取单个 drawable 的边界矩形
  Rect? _getDrawableBounds(Drawable drawable) {
    if (drawable is! ObjectDrawable) return null;

    try {
      // 获取位置和尺寸信息
      final position = drawable.position;
      Size size;

      if (drawable is TextDrawable) {
        size = drawable.getSize();
      } else if (drawable is FreeStyleDrawable) {
        size = drawable.getSize();
      } else if (drawable is ShapeDrawable) {
        size = drawable.getSize();
      } else {
        // 对于其他类型，尝试获取通用尺寸
        size = drawable.getSize();
      }

      // 返回边界矩形
      return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    } catch (e) {
      if (kDebugMode) {
        print('获取drawable边界失败: $e');
      }
      return null;
    }
  }
}
