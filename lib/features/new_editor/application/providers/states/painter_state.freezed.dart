// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'painter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PainterState {
  /// 当前绘制模式
  DrawingMode get drawingMode;

  /// 线条宽度
  double get strokeWidth;

  /// 线条颜色
  Color get strokeColor;

  /// 填充颜色
  Color get fillColor;

  /// 是否填充
  bool get isFilled;

  /// 是否显示调色板
  bool get showColorPicker;

  /// 文本缓存
  List<String> get textCache;

  /// 是否显示文本缓存对话框
  bool get showTextCacheDialog;

  /// 选中的绘图对象
  ObjectDrawable? get selectedObject;

  /// 绘图控制器
  PainterController? get controller;

  /// Create a copy of PainterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PainterStateCopyWith<PainterState> get copyWith =>
      _$PainterStateCopyWithImpl<PainterState>(
          this as PainterState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PainterState &&
            (identical(other.drawingMode, drawingMode) ||
                other.drawingMode == drawingMode) &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.strokeColor, strokeColor) ||
                other.strokeColor == strokeColor) &&
            (identical(other.fillColor, fillColor) ||
                other.fillColor == fillColor) &&
            (identical(other.isFilled, isFilled) ||
                other.isFilled == isFilled) &&
            (identical(other.showColorPicker, showColorPicker) ||
                other.showColorPicker == showColorPicker) &&
            const DeepCollectionEquality().equals(other.textCache, textCache) &&
            (identical(other.showTextCacheDialog, showTextCacheDialog) ||
                other.showTextCacheDialog == showTextCacheDialog) &&
            (identical(other.selectedObject, selectedObject) ||
                other.selectedObject == selectedObject) &&
            (identical(other.controller, controller) ||
                other.controller == controller));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      drawingMode,
      strokeWidth,
      strokeColor,
      fillColor,
      isFilled,
      showColorPicker,
      const DeepCollectionEquality().hash(textCache),
      showTextCacheDialog,
      selectedObject,
      controller);

  @override
  String toString() {
    return 'PainterState(drawingMode: $drawingMode, strokeWidth: $strokeWidth, strokeColor: $strokeColor, fillColor: $fillColor, isFilled: $isFilled, showColorPicker: $showColorPicker, textCache: $textCache, showTextCacheDialog: $showTextCacheDialog, selectedObject: $selectedObject, controller: $controller)';
  }
}

/// @nodoc
abstract mixin class $PainterStateCopyWith<$Res> {
  factory $PainterStateCopyWith(
          PainterState value, $Res Function(PainterState) _then) =
      _$PainterStateCopyWithImpl;
  @useResult
  $Res call(
      {DrawingMode drawingMode,
      double strokeWidth,
      Color strokeColor,
      Color fillColor,
      bool isFilled,
      bool showColorPicker,
      List<String> textCache,
      bool showTextCacheDialog,
      ObjectDrawable? selectedObject,
      PainterController? controller});
}

/// @nodoc
class _$PainterStateCopyWithImpl<$Res> implements $PainterStateCopyWith<$Res> {
  _$PainterStateCopyWithImpl(this._self, this._then);

  final PainterState _self;
  final $Res Function(PainterState) _then;

  /// Create a copy of PainterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? drawingMode = null,
    Object? strokeWidth = null,
    Object? strokeColor = null,
    Object? fillColor = null,
    Object? isFilled = null,
    Object? showColorPicker = null,
    Object? textCache = null,
    Object? showTextCacheDialog = null,
    Object? selectedObject = freezed,
    Object? controller = freezed,
  }) {
    return _then(_self.copyWith(
      drawingMode: null == drawingMode
          ? _self.drawingMode
          : drawingMode // ignore: cast_nullable_to_non_nullable
              as DrawingMode,
      strokeWidth: null == strokeWidth
          ? _self.strokeWidth
          : strokeWidth // ignore: cast_nullable_to_non_nullable
              as double,
      strokeColor: null == strokeColor
          ? _self.strokeColor
          : strokeColor // ignore: cast_nullable_to_non_nullable
              as Color,
      fillColor: null == fillColor
          ? _self.fillColor
          : fillColor // ignore: cast_nullable_to_non_nullable
              as Color,
      isFilled: null == isFilled
          ? _self.isFilled
          : isFilled // ignore: cast_nullable_to_non_nullable
              as bool,
      showColorPicker: null == showColorPicker
          ? _self.showColorPicker
          : showColorPicker // ignore: cast_nullable_to_non_nullable
              as bool,
      textCache: null == textCache
          ? _self.textCache
          : textCache // ignore: cast_nullable_to_non_nullable
              as List<String>,
      showTextCacheDialog: null == showTextCacheDialog
          ? _self.showTextCacheDialog
          : showTextCacheDialog // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedObject: freezed == selectedObject
          ? _self.selectedObject
          : selectedObject // ignore: cast_nullable_to_non_nullable
              as ObjectDrawable?,
      controller: freezed == controller
          ? _self.controller
          : controller // ignore: cast_nullable_to_non_nullable
              as PainterController?,
    ));
  }
}

/// @nodoc

class _PainterState implements PainterState {
  const _PainterState(
      {this.drawingMode = DrawingMode.none,
      this.strokeWidth = 2.0,
      this.strokeColor = Colors.red,
      this.fillColor = Colors.blue,
      this.isFilled = false,
      this.showColorPicker = false,
      final List<String> textCache = const [],
      this.showTextCacheDialog = false,
      this.selectedObject,
      this.controller})
      : _textCache = textCache;

  /// 当前绘制模式
  @override
  @JsonKey()
  final DrawingMode drawingMode;

  /// 线条宽度
  @override
  @JsonKey()
  final double strokeWidth;

  /// 线条颜色
  @override
  @JsonKey()
  final Color strokeColor;

  /// 填充颜色
  @override
  @JsonKey()
  final Color fillColor;

  /// 是否填充
  @override
  @JsonKey()
  final bool isFilled;

  /// 是否显示调色板
  @override
  @JsonKey()
  final bool showColorPicker;

  /// 文本缓存
  final List<String> _textCache;

  /// 文本缓存
  @override
  @JsonKey()
  List<String> get textCache {
    if (_textCache is EqualUnmodifiableListView) return _textCache;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_textCache);
  }

  /// 是否显示文本缓存对话框
  @override
  @JsonKey()
  final bool showTextCacheDialog;

  /// 选中的绘图对象
  @override
  final ObjectDrawable? selectedObject;

  /// 绘图控制器
  @override
  final PainterController? controller;

  /// Create a copy of PainterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PainterStateCopyWith<_PainterState> get copyWith =>
      __$PainterStateCopyWithImpl<_PainterState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PainterState &&
            (identical(other.drawingMode, drawingMode) ||
                other.drawingMode == drawingMode) &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.strokeColor, strokeColor) ||
                other.strokeColor == strokeColor) &&
            (identical(other.fillColor, fillColor) ||
                other.fillColor == fillColor) &&
            (identical(other.isFilled, isFilled) ||
                other.isFilled == isFilled) &&
            (identical(other.showColorPicker, showColorPicker) ||
                other.showColorPicker == showColorPicker) &&
            const DeepCollectionEquality()
                .equals(other._textCache, _textCache) &&
            (identical(other.showTextCacheDialog, showTextCacheDialog) ||
                other.showTextCacheDialog == showTextCacheDialog) &&
            (identical(other.selectedObject, selectedObject) ||
                other.selectedObject == selectedObject) &&
            (identical(other.controller, controller) ||
                other.controller == controller));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      drawingMode,
      strokeWidth,
      strokeColor,
      fillColor,
      isFilled,
      showColorPicker,
      const DeepCollectionEquality().hash(_textCache),
      showTextCacheDialog,
      selectedObject,
      controller);

  @override
  String toString() {
    return 'PainterState(drawingMode: $drawingMode, strokeWidth: $strokeWidth, strokeColor: $strokeColor, fillColor: $fillColor, isFilled: $isFilled, showColorPicker: $showColorPicker, textCache: $textCache, showTextCacheDialog: $showTextCacheDialog, selectedObject: $selectedObject, controller: $controller)';
  }
}

/// @nodoc
abstract mixin class _$PainterStateCopyWith<$Res>
    implements $PainterStateCopyWith<$Res> {
  factory _$PainterStateCopyWith(
          _PainterState value, $Res Function(_PainterState) _then) =
      __$PainterStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DrawingMode drawingMode,
      double strokeWidth,
      Color strokeColor,
      Color fillColor,
      bool isFilled,
      bool showColorPicker,
      List<String> textCache,
      bool showTextCacheDialog,
      ObjectDrawable? selectedObject,
      PainterController? controller});
}

/// @nodoc
class __$PainterStateCopyWithImpl<$Res>
    implements _$PainterStateCopyWith<$Res> {
  __$PainterStateCopyWithImpl(this._self, this._then);

  final _PainterState _self;
  final $Res Function(_PainterState) _then;

  /// Create a copy of PainterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? drawingMode = null,
    Object? strokeWidth = null,
    Object? strokeColor = null,
    Object? fillColor = null,
    Object? isFilled = null,
    Object? showColorPicker = null,
    Object? textCache = null,
    Object? showTextCacheDialog = null,
    Object? selectedObject = freezed,
    Object? controller = freezed,
  }) {
    return _then(_PainterState(
      drawingMode: null == drawingMode
          ? _self.drawingMode
          : drawingMode // ignore: cast_nullable_to_non_nullable
              as DrawingMode,
      strokeWidth: null == strokeWidth
          ? _self.strokeWidth
          : strokeWidth // ignore: cast_nullable_to_non_nullable
              as double,
      strokeColor: null == strokeColor
          ? _self.strokeColor
          : strokeColor // ignore: cast_nullable_to_non_nullable
              as Color,
      fillColor: null == fillColor
          ? _self.fillColor
          : fillColor // ignore: cast_nullable_to_non_nullable
              as Color,
      isFilled: null == isFilled
          ? _self.isFilled
          : isFilled // ignore: cast_nullable_to_non_nullable
              as bool,
      showColorPicker: null == showColorPicker
          ? _self.showColorPicker
          : showColorPicker // ignore: cast_nullable_to_non_nullable
              as bool,
      textCache: null == textCache
          ? _self._textCache
          : textCache // ignore: cast_nullable_to_non_nullable
              as List<String>,
      showTextCacheDialog: null == showTextCacheDialog
          ? _self.showTextCacheDialog
          : showTextCacheDialog // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedObject: freezed == selectedObject
          ? _self.selectedObject
          : selectedObject // ignore: cast_nullable_to_non_nullable
              as ObjectDrawable?,
      controller: freezed == controller
          ? _self.controller
          : controller // ignore: cast_nullable_to_non_nullable
              as PainterController?,
    ));
  }
}

// dart format on
