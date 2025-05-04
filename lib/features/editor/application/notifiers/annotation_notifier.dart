import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

import '../providers/editor_providers.dart';
import '../states/annotation_state.dart';
import '../states/tool_state.dart';
import '../providers/painter_providers.dart';

/// 矩形标注对象
class RectangleAnnotation implements EditorObject {
  @override
  final String id;

  @override
  final Rect bounds;

  final Color strokeColor;
  final double strokeWidth;
  final bool isFilled;
  final Color fillColor;

  const RectangleAnnotation({
    required this.id,
    required this.bounds,
    required this.strokeColor,
    required this.strokeWidth,
    required this.isFilled,
    required this.fillColor,
  });
}

/// 椭圆标注对象
class EllipseAnnotation implements EditorObject {
  @override
  final String id;

  @override
  final Rect bounds;

  final Color strokeColor;
  final double strokeWidth;
  final bool isFilled;
  final Color fillColor;

  const EllipseAnnotation({
    required this.id,
    required this.bounds,
    required this.strokeColor,
    required this.strokeWidth,
    required this.isFilled,
    required this.fillColor,
  });
}

/// 箭头标注对象
class ArrowAnnotation implements EditorObject {
  @override
  final String id;

  final Offset start;
  final Offset end;

  @override
  Rect get bounds {
    return Rect.fromPoints(start, end);
  }

  final Color strokeColor;
  final double strokeWidth;

  const ArrowAnnotation({
    required this.id,
    required this.start,
    required this.end,
    required this.strokeColor,
    required this.strokeWidth,
  });
}

/// 直线标注对象
class LineAnnotation implements EditorObject {
  @override
  final String id;

  final Offset start;
  final Offset end;

  @override
  Rect get bounds {
    return Rect.fromPoints(start, end);
  }

  final Color strokeColor;
  final double strokeWidth;

  const LineAnnotation({
    required this.id,
    required this.start,
    required this.end,
    required this.strokeColor,
    required this.strokeWidth,
  });
}

/// 文本标注对象
class TextAnnotation implements EditorObject {
  @override
  final String id;

  @override
  final Rect bounds;

  final String text;
  final TextStyle textStyle;
  final Color backgroundColor;
  final bool hasBackground;

  const TextAnnotation({
    required this.id,
    required this.bounds,
    required this.text,
    required this.textStyle,
    required this.backgroundColor,
    required this.hasBackground,
  });
}

/// 标注管理Notifier
class AnnotationNotifier extends Notifier<AnnotationState> {
  static const _uuid = Uuid();

  @override
  AnnotationState build() => AnnotationState.initial();

  /// 添加标注
  void addAnnotation(EditorObject annotation) {
    final List<EditorObject> updatedAnnotations = [
      ...state.annotations,
      annotation
    ];
    state = state.copyWith(
      annotations: updatedAnnotations,
      selectedAnnotationId: annotation.id,
    );
    _checkAndExpandWallpaper(updatedAnnotations);
  }

  /// 更新标注
  void updateAnnotation(EditorObject updatedAnnotation) {
    final List<EditorObject> updatedAnnotations =
        state.annotations.map((annotation) {
      if (annotation.id == updatedAnnotation.id) {
        return updatedAnnotation;
      }
      return annotation;
    }).toList();
    state = state.copyWith(annotations: updatedAnnotations);
    _checkAndExpandWallpaper(updatedAnnotations);
  }

  /// 移除标注
  void removeAnnotation(String id) {
    final List<EditorObject> updatedAnnotations =
        state.annotations.where((annotation) => annotation.id != id).toList();
    state = state.copyWith(
      annotations: updatedAnnotations,
      selectedAnnotationId:
          state.selectedAnnotationId == id ? null : state.selectedAnnotationId,
    );
  }

  /// 选择标注
  void selectAnnotation(String? id) {
    state = state.copyWith(selectedAnnotationId: id);
  }

  /// 清除所有标注
  void clearAnnotations() {
    state = AnnotationState.initial();
  }

  /// 创建一个新的标注对象（根据当前选择的工具）
  EditorObject? createAnnotation(Rect rect) {
    final toolState = ref.read(toolProvider);
    final String id = _uuid.v4();
    switch (toolState.currentTool) {
      case EditorTool.rectangle:
        final shapeSettings = toolState.shapeSettings;
        return RectangleAnnotation(
          id: id,
          bounds: rect,
          strokeColor: shapeSettings.strokeColor,
          strokeWidth: shapeSettings.strokeWidth,
          isFilled: shapeSettings.isFilled,
          fillColor: shapeSettings.fillColor,
        );
      case EditorTool.ellipse:
        final shapeSettings = toolState.shapeSettings;
        return EllipseAnnotation(
          id: id,
          bounds: rect,
          strokeColor: shapeSettings.strokeColor,
          strokeWidth: shapeSettings.strokeWidth,
          isFilled: shapeSettings.isFilled,
          fillColor: shapeSettings.fillColor,
        );
      case EditorTool.arrow:
        final shapeSettings = toolState.shapeSettings;
        return ArrowAnnotation(
          id: id,
          start: rect.topLeft,
          end: rect.bottomRight,
          strokeColor: shapeSettings.strokeColor,
          strokeWidth: shapeSettings.strokeWidth,
        );
      case EditorTool.line:
        final shapeSettings = toolState.shapeSettings;
        return LineAnnotation(
          id: id,
          start: rect.topLeft,
          end: rect.bottomRight,
          strokeColor: shapeSettings.strokeColor,
          strokeWidth: shapeSettings.strokeWidth,
        );
      case EditorTool.text:
        final textSettings = toolState.textSettings;
        return TextAnnotation(
          id: id,
          bounds: rect,
          text: "点击编辑文本",
          textStyle: textSettings.textStyle,
          backgroundColor: textSettings.backgroundColor,
          hasBackground: textSettings.hasBackground,
        );
      default:
        return null;
    }
  }

  /// 计算所有标注的边界
  Rect _calculateAnnotationsBounds(List<EditorObject> annotations) {
    if (annotations.isEmpty) {
      return Rect.zero;
    }
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    for (final annotation in annotations) {
      final Rect bounds = annotation.bounds;
      if (bounds.left < left) left = bounds.left;
      if (bounds.top < top) top = bounds.top;
      if (bounds.right > right) right = bounds.right;
      if (bounds.bottom > bottom) bottom = bounds.bottom;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 检查并扩展Wallpaper边距
  void _checkAndExpandWallpaper(List<EditorObject> annotations) {
    if (annotations.isEmpty) return;

    final originalImageSize =
        ref.read(editorStateProvider.select((s) => s.originalImageSize));
    final currentPadding =
        ref.read(editorStateProvider.select((s) => s.wallpaperPadding));

    if (originalImageSize == null) return;

    final Rect annotationBounds = _calculateAnnotationsBounds(annotations);
    final Rect imageBounds = Rect.fromLTWH(
      0,
      0,
      originalImageSize.width,
      originalImageSize.height,
    );

    double leftPadding = currentPadding.left;
    double topPadding = currentPadding.top;
    double rightPadding = currentPadding.right;
    double bottomPadding = currentPadding.bottom;

    if (annotationBounds.left < 0) {
      leftPadding = math.max(leftPadding, -annotationBounds.left + 10);
    }
    if (annotationBounds.top < 0) {
      topPadding = math.max(topPadding, -annotationBounds.top + 10);
    }
    if (annotationBounds.right > imageBounds.right) {
      rightPadding = math.max(
          rightPadding, annotationBounds.right - imageBounds.right + 10);
    }
    if (annotationBounds.bottom > imageBounds.bottom) {
      bottomPadding = math.max(
          bottomPadding, annotationBounds.bottom - imageBounds.bottom + 10);
    }

    if (leftPadding != currentPadding.left ||
        topPadding != currentPadding.top ||
        rightPadding != currentPadding.right ||
        bottomPadding != currentPadding.bottom) {
      final newPadding = EdgeInsets.fromLTRB(
          leftPadding, topPadding, rightPadding, bottomPadding);
      ref
          .read(editorStateProvider.notifier)
          .updateWallpaperPaddingWithLayout(newPadding);
    }
  }
}
