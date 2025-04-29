import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 编辑器对象接口
abstract class EditorObject {
  String get id;
  Rect get bounds;
}

/// 标注状态类
class AnnotationState extends Equatable {
  /// 标注列表
  final List<EditorObject> annotations;

  /// 当前选中的标注ID
  final String? selectedAnnotationId;

  const AnnotationState({
    this.annotations = const [],
    this.selectedAnnotationId,
  });

  /// 创建初始状态
  factory AnnotationState.initial() => const AnnotationState();

  /// 使用copyWith创建新实例
  AnnotationState copyWith({
    List<EditorObject>? annotations,
    String? selectedAnnotationId,
  }) {
    return AnnotationState(
      annotations: annotations ?? this.annotations,
      selectedAnnotationId: selectedAnnotationId ?? this.selectedAnnotationId,
    );
  }

  /// 清除选中状态
  AnnotationState clearSelection() {
    return copyWith(selectedAnnotationId: null);
  }

  /// 获取当前选中的标注
  EditorObject? get selectedAnnotation {
    if (selectedAnnotationId == null) return null;
    try {
      return annotations.firstWhere(
        (annotation) => annotation.id == selectedAnnotationId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [annotations, selectedAnnotationId];
}
