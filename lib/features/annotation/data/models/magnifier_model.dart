import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// 放大镜数据模型
class MagnifierModel extends Equatable {
  // 唯一标识符
  final String id;

  // 放大镜中心点位置
  final Offset center;

  // 放大镜半径
  final double radius;

  // 放大倍率
  final double zoom;

  // 是否激活
  final bool isActive;

  const MagnifierModel({
    required this.id,
    required this.center,
    this.radius = 100.0,
    this.zoom = 2.0,
    this.isActive = true,
  });

  // 创建带有更新字段的新实例
  MagnifierModel copyWith({
    String? id,
    Offset? center,
    double? radius,
    double? zoom,
    bool? isActive,
  }) {
    return MagnifierModel(
      id: id ?? this.id,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      zoom: zoom ?? this.zoom,
      isActive: isActive ?? this.isActive,
    );
  }

  // 从JSON创建实例
  factory MagnifierModel.fromJson(Map<String, dynamic> json) {
    return MagnifierModel(
      id: json['id'] as String,
      center: Offset(
        json['centerX'] as double,
        json['centerY'] as double,
      ),
      radius: json['radius'] as double,
      zoom: json['zoom'] as double,
      isActive: json['isActive'] as bool,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centerX': center.dx,
      'centerY': center.dy,
      'radius': radius,
      'zoom': zoom,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, center, radius, zoom, isActive];
}
