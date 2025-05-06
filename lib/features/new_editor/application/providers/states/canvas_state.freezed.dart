// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canvas_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CanvasState {
  /// 画布缩放比例
  double get scale;

  /// 画布偏移量
  Offset get offset;

  /// 画布尺寸
  Size? get size;

  /// 是否正在加载
  bool get isLoading;

  /// 是否显示网格
  bool get showGrid;

  /// 是否显示标尺
  bool get showRuler;

  /// Create a copy of CanvasState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CanvasStateCopyWith<CanvasState> get copyWith =>
      _$CanvasStateCopyWithImpl<CanvasState>(this as CanvasState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CanvasState &&
            (identical(other.scale, scale) || other.scale == scale) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.showGrid, showGrid) ||
                other.showGrid == showGrid) &&
            (identical(other.showRuler, showRuler) ||
                other.showRuler == showRuler));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, scale, offset, size, isLoading, showGrid, showRuler);

  @override
  String toString() {
    return 'CanvasState(scale: $scale, offset: $offset, size: $size, isLoading: $isLoading, showGrid: $showGrid, showRuler: $showRuler)';
  }
}

/// @nodoc
abstract mixin class $CanvasStateCopyWith<$Res> {
  factory $CanvasStateCopyWith(
          CanvasState value, $Res Function(CanvasState) _then) =
      _$CanvasStateCopyWithImpl;
  @useResult
  $Res call(
      {double scale,
      Offset offset,
      Size? size,
      bool isLoading,
      bool showGrid,
      bool showRuler});
}

/// @nodoc
class _$CanvasStateCopyWithImpl<$Res> implements $CanvasStateCopyWith<$Res> {
  _$CanvasStateCopyWithImpl(this._self, this._then);

  final CanvasState _self;
  final $Res Function(CanvasState) _then;

  /// Create a copy of CanvasState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scale = null,
    Object? offset = null,
    Object? size = freezed,
    Object? isLoading = null,
    Object? showGrid = null,
    Object? showRuler = null,
  }) {
    return _then(_self.copyWith(
      scale: null == scale
          ? _self.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as Offset,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      showGrid: null == showGrid
          ? _self.showGrid
          : showGrid // ignore: cast_nullable_to_non_nullable
              as bool,
      showRuler: null == showRuler
          ? _self.showRuler
          : showRuler // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _CanvasState implements CanvasState {
  const _CanvasState(
      {this.scale = 1.0,
      this.offset = Offset.zero,
      this.size,
      this.isLoading = false,
      this.showGrid = false,
      this.showRuler = false});

  /// 画布缩放比例
  @override
  @JsonKey()
  final double scale;

  /// 画布偏移量
  @override
  @JsonKey()
  final Offset offset;

  /// 画布尺寸
  @override
  final Size? size;

  /// 是否正在加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 是否显示网格
  @override
  @JsonKey()
  final bool showGrid;

  /// 是否显示标尺
  @override
  @JsonKey()
  final bool showRuler;

  /// Create a copy of CanvasState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CanvasStateCopyWith<_CanvasState> get copyWith =>
      __$CanvasStateCopyWithImpl<_CanvasState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CanvasState &&
            (identical(other.scale, scale) || other.scale == scale) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.showGrid, showGrid) ||
                other.showGrid == showGrid) &&
            (identical(other.showRuler, showRuler) ||
                other.showRuler == showRuler));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, scale, offset, size, isLoading, showGrid, showRuler);

  @override
  String toString() {
    return 'CanvasState(scale: $scale, offset: $offset, size: $size, isLoading: $isLoading, showGrid: $showGrid, showRuler: $showRuler)';
  }
}

/// @nodoc
abstract mixin class _$CanvasStateCopyWith<$Res>
    implements $CanvasStateCopyWith<$Res> {
  factory _$CanvasStateCopyWith(
          _CanvasState value, $Res Function(_CanvasState) _then) =
      __$CanvasStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double scale,
      Offset offset,
      Size? size,
      bool isLoading,
      bool showGrid,
      bool showRuler});
}

/// @nodoc
class __$CanvasStateCopyWithImpl<$Res> implements _$CanvasStateCopyWith<$Res> {
  __$CanvasStateCopyWithImpl(this._self, this._then);

  final _CanvasState _self;
  final $Res Function(_CanvasState) _then;

  /// Create a copy of CanvasState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? scale = null,
    Object? offset = null,
    Object? size = freezed,
    Object? isLoading = null,
    Object? showGrid = null,
    Object? showRuler = null,
  }) {
    return _then(_CanvasState(
      scale: null == scale
          ? _self.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as Offset,
      size: freezed == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      showGrid: null == showGrid
          ? _self.showGrid
          : showGrid // ignore: cast_nullable_to_non_nullable
              as bool,
      showRuler: null == showRuler
          ? _self.showRuler
          : showRuler // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
