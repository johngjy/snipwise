import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// 项目数据模型
class ProjectModel extends Equatable {
  // 项目ID
  final String id;

  // 项目名称
  final String name;

  // 创建时间
  final DateTime createdAt;

  // 修改时间
  final DateTime modifiedAt;

  // 图像路径
  final String? imagePath;

  // 项目保存路径
  final String? savePath;

  // 缩略图
  final Image? thumbnail;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.imagePath,
    this.savePath,
    this.thumbnail,
  });

  // 创建带有更新字段的新实例
  ProjectModel copyWith({
    String? name,
    DateTime? modifiedAt,
    String? imagePath,
    String? savePath,
    Image? thumbnail,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      imagePath: imagePath ?? this.imagePath,
      savePath: savePath ?? this.savePath,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  // 从JSON创建实例
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      imagePath: json['imagePath'] as String?,
      savePath: json['savePath'] as String?,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'imagePath': imagePath,
      'savePath': savePath,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, createdAt, modifiedAt, imagePath, savePath];
}
