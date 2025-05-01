// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ToolSettings {
  /// 线条宽度
  double get strokeWidth;

  /// 线条颜色
  @ColorSerializer()
  Color get strokeColor;

  /// 填充颜色
  @NullableColorSerializer()
  Color? get fillColor;

  /// 圆角半径 (用于矩形)
  double get cornerRadius;

  /// 文本大小
  double get fontSize;

  /// 文本字体
  String get fontFamily;

  /// 文本颜色
  @ColorSerializer()
  Color get textColor;

  /// 文本对齐方式
  @JsonKey(includeFromJson: false, includeToJson: false)
  TextAlign get textAlign;

  /// Create a copy of ToolSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ToolSettingsCopyWith<ToolSettings> get copyWith =>
      _$ToolSettingsCopyWithImpl<ToolSettings>(
          this as ToolSettings, _$identity);

  /// Serializes this ToolSettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ToolSettings &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.strokeColor, strokeColor) ||
                other.strokeColor == strokeColor) &&
            (identical(other.fillColor, fillColor) ||
                other.fillColor == fillColor) &&
            (identical(other.cornerRadius, cornerRadius) ||
                other.cornerRadius == cornerRadius) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.textColor, textColor) ||
                other.textColor == textColor) &&
            (identical(other.textAlign, textAlign) ||
                other.textAlign == textAlign));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, strokeWidth, strokeColor,
      fillColor, cornerRadius, fontSize, fontFamily, textColor, textAlign);

  @override
  String toString() {
    return 'ToolSettings(strokeWidth: $strokeWidth, strokeColor: $strokeColor, fillColor: $fillColor, cornerRadius: $cornerRadius, fontSize: $fontSize, fontFamily: $fontFamily, textColor: $textColor, textAlign: $textAlign)';
  }
}

/// @nodoc
abstract mixin class $ToolSettingsCopyWith<$Res> {
  factory $ToolSettingsCopyWith(
          ToolSettings value, $Res Function(ToolSettings) _then) =
      _$ToolSettingsCopyWithImpl;
  @useResult
  $Res call(
      {double strokeWidth,
      @ColorSerializer() Color strokeColor,
      @NullableColorSerializer() Color? fillColor,
      double cornerRadius,
      double fontSize,
      String fontFamily,
      @ColorSerializer() Color textColor,
      @JsonKey(includeFromJson: false, includeToJson: false)
      TextAlign textAlign});
}

/// @nodoc
class _$ToolSettingsCopyWithImpl<$Res> implements $ToolSettingsCopyWith<$Res> {
  _$ToolSettingsCopyWithImpl(this._self, this._then);

  final ToolSettings _self;
  final $Res Function(ToolSettings) _then;

  /// Create a copy of ToolSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokeWidth = null,
    Object? strokeColor = null,
    Object? fillColor = freezed,
    Object? cornerRadius = null,
    Object? fontSize = null,
    Object? fontFamily = null,
    Object? textColor = null,
    Object? textAlign = null,
  }) {
    return _then(_self.copyWith(
      strokeWidth: null == strokeWidth
          ? _self.strokeWidth
          : strokeWidth // ignore: cast_nullable_to_non_nullable
              as double,
      strokeColor: null == strokeColor
          ? _self.strokeColor
          : strokeColor // ignore: cast_nullable_to_non_nullable
              as Color,
      fillColor: freezed == fillColor
          ? _self.fillColor
          : fillColor // ignore: cast_nullable_to_non_nullable
              as Color?,
      cornerRadius: null == cornerRadius
          ? _self.cornerRadius
          : cornerRadius // ignore: cast_nullable_to_non_nullable
              as double,
      fontSize: null == fontSize
          ? _self.fontSize
          : fontSize // ignore: cast_nullable_to_non_nullable
              as double,
      fontFamily: null == fontFamily
          ? _self.fontFamily
          : fontFamily // ignore: cast_nullable_to_non_nullable
              as String,
      textColor: null == textColor
          ? _self.textColor
          : textColor // ignore: cast_nullable_to_non_nullable
              as Color,
      textAlign: null == textAlign
          ? _self.textAlign
          : textAlign // ignore: cast_nullable_to_non_nullable
              as TextAlign,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ToolSettings extends ToolSettings {
  const _ToolSettings(
      {this.strokeWidth = 2.0,
      @ColorSerializer() this.strokeColor = Colors.red,
      @NullableColorSerializer() this.fillColor,
      this.cornerRadius = 0.0,
      this.fontSize = 14.0,
      this.fontFamily = 'Roboto',
      @ColorSerializer() this.textColor = Colors.black,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.textAlign = TextAlign.left})
      : super._();
  factory _ToolSettings.fromJson(Map<String, dynamic> json) =>
      _$ToolSettingsFromJson(json);

  /// 线条宽度
  @override
  @JsonKey()
  final double strokeWidth;

  /// 线条颜色
  @override
  @JsonKey()
  @ColorSerializer()
  final Color strokeColor;

  /// 填充颜色
  @override
  @NullableColorSerializer()
  final Color? fillColor;

  /// 圆角半径 (用于矩形)
  @override
  @JsonKey()
  final double cornerRadius;

  /// 文本大小
  @override
  @JsonKey()
  final double fontSize;

  /// 文本字体
  @override
  @JsonKey()
  final String fontFamily;

  /// 文本颜色
  @override
  @JsonKey()
  @ColorSerializer()
  final Color textColor;

  /// 文本对齐方式
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final TextAlign textAlign;

  /// Create a copy of ToolSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ToolSettingsCopyWith<_ToolSettings> get copyWith =>
      __$ToolSettingsCopyWithImpl<_ToolSettings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ToolSettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ToolSettings &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.strokeColor, strokeColor) ||
                other.strokeColor == strokeColor) &&
            (identical(other.fillColor, fillColor) ||
                other.fillColor == fillColor) &&
            (identical(other.cornerRadius, cornerRadius) ||
                other.cornerRadius == cornerRadius) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.textColor, textColor) ||
                other.textColor == textColor) &&
            (identical(other.textAlign, textAlign) ||
                other.textAlign == textAlign));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, strokeWidth, strokeColor,
      fillColor, cornerRadius, fontSize, fontFamily, textColor, textAlign);

  @override
  String toString() {
    return 'ToolSettings(strokeWidth: $strokeWidth, strokeColor: $strokeColor, fillColor: $fillColor, cornerRadius: $cornerRadius, fontSize: $fontSize, fontFamily: $fontFamily, textColor: $textColor, textAlign: $textAlign)';
  }
}

/// @nodoc
abstract mixin class _$ToolSettingsCopyWith<$Res>
    implements $ToolSettingsCopyWith<$Res> {
  factory _$ToolSettingsCopyWith(
          _ToolSettings value, $Res Function(_ToolSettings) _then) =
      __$ToolSettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double strokeWidth,
      @ColorSerializer() Color strokeColor,
      @NullableColorSerializer() Color? fillColor,
      double cornerRadius,
      double fontSize,
      String fontFamily,
      @ColorSerializer() Color textColor,
      @JsonKey(includeFromJson: false, includeToJson: false)
      TextAlign textAlign});
}

/// @nodoc
class __$ToolSettingsCopyWithImpl<$Res>
    implements _$ToolSettingsCopyWith<$Res> {
  __$ToolSettingsCopyWithImpl(this._self, this._then);

  final _ToolSettings _self;
  final $Res Function(_ToolSettings) _then;

  /// Create a copy of ToolSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? strokeWidth = null,
    Object? strokeColor = null,
    Object? fillColor = freezed,
    Object? cornerRadius = null,
    Object? fontSize = null,
    Object? fontFamily = null,
    Object? textColor = null,
    Object? textAlign = null,
  }) {
    return _then(_ToolSettings(
      strokeWidth: null == strokeWidth
          ? _self.strokeWidth
          : strokeWidth // ignore: cast_nullable_to_non_nullable
              as double,
      strokeColor: null == strokeColor
          ? _self.strokeColor
          : strokeColor // ignore: cast_nullable_to_non_nullable
              as Color,
      fillColor: freezed == fillColor
          ? _self.fillColor
          : fillColor // ignore: cast_nullable_to_non_nullable
              as Color?,
      cornerRadius: null == cornerRadius
          ? _self.cornerRadius
          : cornerRadius // ignore: cast_nullable_to_non_nullable
              as double,
      fontSize: null == fontSize
          ? _self.fontSize
          : fontSize // ignore: cast_nullable_to_non_nullable
              as double,
      fontFamily: null == fontFamily
          ? _self.fontFamily
          : fontFamily // ignore: cast_nullable_to_non_nullable
              as String,
      textColor: null == textColor
          ? _self.textColor
          : textColor // ignore: cast_nullable_to_non_nullable
              as Color,
      textAlign: null == textAlign
          ? _self.textAlign
          : textAlign // ignore: cast_nullable_to_non_nullable
              as TextAlign,
    ));
  }
}

// dart format on
