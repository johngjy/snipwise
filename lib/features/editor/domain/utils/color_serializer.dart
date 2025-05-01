import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Color类型的JSON转换器
class ColorSerializer implements JsonConverter<Color, int> {
  const ColorSerializer();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color color) => color.value;
}

/// 可空Color类型的JSON转换器
class NullableColorSerializer implements JsonConverter<Color?, int?> {
  const NullableColorSerializer();

  @override
  Color? fromJson(int? json) => json != null ? Color(json) : null;

  @override
  int? toJson(Color? color) => color?.value;
}
