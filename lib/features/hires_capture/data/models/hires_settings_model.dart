import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// 高清截图设置模型
class HiResSettings extends Equatable {
  // 是否启用高清截图模式
  final bool enabled;

  // 默认DPI值 (可选值: 72/150/300/600)
  final int defaultDpi;

  // 默认输出格式 (可选值: 'PNG'/'JPG')
  final String outputFormat;

  // JPEG质量设置 (0-100)
  final int jpgQuality;

  // 源图像缩放比例
  final double sourceScale;

  // 选择区域
  final Rect? selectedRegion;

  const HiResSettings({
    this.enabled = true,
    this.defaultDpi = 300,
    this.outputFormat = 'PNG',
    this.jpgQuality = 90,
    this.sourceScale = 1.0,
    this.selectedRegion,
  });

  // 创建带有更新字段的新实例
  HiResSettings copyWith({
    bool? enabled,
    int? defaultDpi,
    String? outputFormat,
    int? jpgQuality,
    double? sourceScale,
    Rect? selectedRegion,
    bool clearSelectedRegion = false,
  }) {
    return HiResSettings(
      enabled: enabled ?? this.enabled,
      defaultDpi: defaultDpi ?? this.defaultDpi,
      outputFormat: outputFormat ?? this.outputFormat,
      jpgQuality: jpgQuality ?? this.jpgQuality,
      sourceScale: sourceScale ?? this.sourceScale,
      selectedRegion:
          clearSelectedRegion ? null : selectedRegion ?? this.selectedRegion,
    );
  }

  // 从JSON创建实例
  factory HiResSettings.fromJson(Map<String, dynamic> json) {
    return HiResSettings(
      enabled: json['enabled'] as bool? ?? true,
      defaultDpi: json['defaultDpi'] as int? ?? 300,
      outputFormat: json['outputFormat'] as String? ?? 'PNG',
      jpgQuality: json['jpgQuality'] as int? ?? 90,
      sourceScale: json['sourceScale'] as double? ?? 1.0,
      selectedRegion: json['selectedRegion'] != null
          ? Rect.fromLTWH(
              json['selectedRegion']['left'] as double,
              json['selectedRegion']['top'] as double,
              json['selectedRegion']['width'] as double,
              json['selectedRegion']['height'] as double,
            )
          : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'defaultDpi': defaultDpi,
      'outputFormat': outputFormat,
      'jpgQuality': jpgQuality,
      'sourceScale': sourceScale,
      'selectedRegion': selectedRegion != null
          ? {
              'left': selectedRegion!.left,
              'top': selectedRegion!.top,
              'width': selectedRegion!.width,
              'height': selectedRegion!.height,
            }
          : null,
    };
  }

  @override
  List<Object?> get props => [
        enabled,
        defaultDpi,
        outputFormat,
        jpgQuality,
        sourceScale,
        selectedRegion
      ];
}
