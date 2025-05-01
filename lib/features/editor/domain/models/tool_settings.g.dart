// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ToolSettings _$ToolSettingsFromJson(Map<String, dynamic> json) =>
    _ToolSettings(
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeColor: json['strokeColor'] == null
          ? Colors.red
          : const ColorSerializer()
              .fromJson((json['strokeColor'] as num).toInt()),
      fillColor: const NullableColorSerializer()
          .fromJson((json['fillColor'] as num?)?.toInt()),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      textColor: json['textColor'] == null
          ? Colors.black
          : const ColorSerializer()
              .fromJson((json['textColor'] as num).toInt()),
    );

Map<String, dynamic> _$ToolSettingsToJson(_ToolSettings instance) =>
    <String, dynamic>{
      'strokeWidth': instance.strokeWidth,
      'strokeColor': const ColorSerializer().toJson(instance.strokeColor),
      'fillColor': const NullableColorSerializer().toJson(instance.fillColor),
      'cornerRadius': instance.cornerRadius,
      'fontSize': instance.fontSize,
      'fontFamily': instance.fontFamily,
      'textColor': const ColorSerializer().toJson(instance.textColor),
    };
