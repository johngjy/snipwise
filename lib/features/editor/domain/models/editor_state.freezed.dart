// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EditorState {
  /// 当前选择的工具
  ToolType get selectedTool;

  /// 系统默认设置
  ToolSettings get defaultSettings;

  /// 各工具专属设置
  Map<ToolType, ToolSettings> get toolSettings;

  /// 画布控制器
  @JsonKey(includeFromJson: false, includeToJson: false)
  PainterController? get painterController;

  /// 是否有未保存的更改
  bool get hasUnsavedChanges;

  /// 可撤销操作数量
  int get undoableActionsCount;

  /// 可重做操作数量
  int get redoableActionsCount;

  /// 所选对象列表
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Drawable> get selectedObjects;

  /// 缓存的文本内容是否可见
  bool get isTextCacheVisible;

  /// 原始截图尺寸 (可选)
  Size? get originalImageSize;

  /// 背景边距 (可选)
  EdgeInsets get wallpaperPadding;

  /// 是否正在加载
  bool get isLoading;

  /// 截图数据
  Uint8List? get screenshotData;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EditorStateCopyWith<EditorState> get copyWith =>
      _$EditorStateCopyWithImpl<EditorState>(this as EditorState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EditorState &&
            (identical(other.selectedTool, selectedTool) ||
                other.selectedTool == selectedTool) &&
            (identical(other.defaultSettings, defaultSettings) ||
                other.defaultSettings == defaultSettings) &&
            const DeepCollectionEquality()
                .equals(other.toolSettings, toolSettings) &&
            (identical(other.painterController, painterController) ||
                other.painterController == painterController) &&
            (identical(other.hasUnsavedChanges, hasUnsavedChanges) ||
                other.hasUnsavedChanges == hasUnsavedChanges) &&
            (identical(other.undoableActionsCount, undoableActionsCount) ||
                other.undoableActionsCount == undoableActionsCount) &&
            (identical(other.redoableActionsCount, redoableActionsCount) ||
                other.redoableActionsCount == redoableActionsCount) &&
            const DeepCollectionEquality()
                .equals(other.selectedObjects, selectedObjects) &&
            (identical(other.isTextCacheVisible, isTextCacheVisible) ||
                other.isTextCacheVisible == isTextCacheVisible) &&
            (identical(other.originalImageSize, originalImageSize) ||
                other.originalImageSize == originalImageSize) &&
            (identical(other.wallpaperPadding, wallpaperPadding) ||
                other.wallpaperPadding == wallpaperPadding) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other.screenshotData, screenshotData));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      selectedTool,
      defaultSettings,
      const DeepCollectionEquality().hash(toolSettings),
      painterController,
      hasUnsavedChanges,
      undoableActionsCount,
      redoableActionsCount,
      const DeepCollectionEquality().hash(selectedObjects),
      isTextCacheVisible,
      originalImageSize,
      wallpaperPadding,
      isLoading,
      const DeepCollectionEquality().hash(screenshotData));

  @override
  String toString() {
    return 'EditorState(selectedTool: $selectedTool, defaultSettings: $defaultSettings, toolSettings: $toolSettings, painterController: $painterController, hasUnsavedChanges: $hasUnsavedChanges, undoableActionsCount: $undoableActionsCount, redoableActionsCount: $redoableActionsCount, selectedObjects: $selectedObjects, isTextCacheVisible: $isTextCacheVisible, originalImageSize: $originalImageSize, wallpaperPadding: $wallpaperPadding, isLoading: $isLoading, screenshotData: $screenshotData)';
  }
}

/// @nodoc
abstract mixin class $EditorStateCopyWith<$Res> {
  factory $EditorStateCopyWith(
          EditorState value, $Res Function(EditorState) _then) =
      _$EditorStateCopyWithImpl;
  @useResult
  $Res call(
      {ToolType selectedTool,
      ToolSettings defaultSettings,
      Map<ToolType, ToolSettings> toolSettings,
      @JsonKey(includeFromJson: false, includeToJson: false)
      PainterController? painterController,
      bool hasUnsavedChanges,
      int undoableActionsCount,
      int redoableActionsCount,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<Drawable> selectedObjects,
      bool isTextCacheVisible,
      Size? originalImageSize,
      EdgeInsets wallpaperPadding,
      bool isLoading,
      Uint8List? screenshotData});

  $ToolSettingsCopyWith<$Res> get defaultSettings;
}

/// @nodoc
class _$EditorStateCopyWithImpl<$Res> implements $EditorStateCopyWith<$Res> {
  _$EditorStateCopyWithImpl(this._self, this._then);

  final EditorState _self;
  final $Res Function(EditorState) _then;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedTool = null,
    Object? defaultSettings = null,
    Object? toolSettings = null,
    Object? painterController = freezed,
    Object? hasUnsavedChanges = null,
    Object? undoableActionsCount = null,
    Object? redoableActionsCount = null,
    Object? selectedObjects = null,
    Object? isTextCacheVisible = null,
    Object? originalImageSize = freezed,
    Object? wallpaperPadding = null,
    Object? isLoading = null,
    Object? screenshotData = freezed,
  }) {
    return _then(_self.copyWith(
      selectedTool: null == selectedTool
          ? _self.selectedTool
          : selectedTool // ignore: cast_nullable_to_non_nullable
              as ToolType,
      defaultSettings: null == defaultSettings
          ? _self.defaultSettings
          : defaultSettings // ignore: cast_nullable_to_non_nullable
              as ToolSettings,
      toolSettings: null == toolSettings
          ? _self.toolSettings
          : toolSettings // ignore: cast_nullable_to_non_nullable
              as Map<ToolType, ToolSettings>,
      painterController: freezed == painterController
          ? _self.painterController
          : painterController // ignore: cast_nullable_to_non_nullable
              as PainterController?,
      hasUnsavedChanges: null == hasUnsavedChanges
          ? _self.hasUnsavedChanges
          : hasUnsavedChanges // ignore: cast_nullable_to_non_nullable
              as bool,
      undoableActionsCount: null == undoableActionsCount
          ? _self.undoableActionsCount
          : undoableActionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      redoableActionsCount: null == redoableActionsCount
          ? _self.redoableActionsCount
          : redoableActionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      selectedObjects: null == selectedObjects
          ? _self.selectedObjects
          : selectedObjects // ignore: cast_nullable_to_non_nullable
              as List<Drawable>,
      isTextCacheVisible: null == isTextCacheVisible
          ? _self.isTextCacheVisible
          : isTextCacheVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      originalImageSize: freezed == originalImageSize
          ? _self.originalImageSize
          : originalImageSize // ignore: cast_nullable_to_non_nullable
              as Size?,
      wallpaperPadding: null == wallpaperPadding
          ? _self.wallpaperPadding
          : wallpaperPadding // ignore: cast_nullable_to_non_nullable
              as EdgeInsets,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      screenshotData: freezed == screenshotData
          ? _self.screenshotData
          : screenshotData // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
    ));
  }

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ToolSettingsCopyWith<$Res> get defaultSettings {
    return $ToolSettingsCopyWith<$Res>(_self.defaultSettings, (value) {
      return _then(_self.copyWith(defaultSettings: value));
    });
  }
}

/// @nodoc

class _EditorState extends EditorState {
  const _EditorState(
      {this.selectedTool = ToolType.select,
      this.defaultSettings = const ToolSettings(),
      final Map<ToolType, ToolSettings> toolSettings = const {},
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.painterController,
      this.hasUnsavedChanges = false,
      this.undoableActionsCount = 0,
      this.redoableActionsCount = 0,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<Drawable> selectedObjects = const [],
      this.isTextCacheVisible = false,
      this.originalImageSize,
      this.wallpaperPadding = EdgeInsets.zero,
      this.isLoading = false,
      this.screenshotData})
      : _toolSettings = toolSettings,
        _selectedObjects = selectedObjects,
        super._();

  /// 当前选择的工具
  @override
  @JsonKey()
  final ToolType selectedTool;

  /// 系统默认设置
  @override
  @JsonKey()
  final ToolSettings defaultSettings;

  /// 各工具专属设置
  final Map<ToolType, ToolSettings> _toolSettings;

  /// 各工具专属设置
  @override
  @JsonKey()
  Map<ToolType, ToolSettings> get toolSettings {
    if (_toolSettings is EqualUnmodifiableMapView) return _toolSettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_toolSettings);
  }

  /// 画布控制器
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final PainterController? painterController;

  /// 是否有未保存的更改
  @override
  @JsonKey()
  final bool hasUnsavedChanges;

  /// 可撤销操作数量
  @override
  @JsonKey()
  final int undoableActionsCount;

  /// 可重做操作数量
  @override
  @JsonKey()
  final int redoableActionsCount;

  /// 所选对象列表
  final List<Drawable> _selectedObjects;

  /// 所选对象列表
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Drawable> get selectedObjects {
    if (_selectedObjects is EqualUnmodifiableListView) return _selectedObjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedObjects);
  }

  /// 缓存的文本内容是否可见
  @override
  @JsonKey()
  final bool isTextCacheVisible;

  /// 原始截图尺寸 (可选)
  @override
  final Size? originalImageSize;

  /// 背景边距 (可选)
  @override
  @JsonKey()
  final EdgeInsets wallpaperPadding;

  /// 是否正在加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 截图数据
  @override
  final Uint8List? screenshotData;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EditorStateCopyWith<_EditorState> get copyWith =>
      __$EditorStateCopyWithImpl<_EditorState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EditorState &&
            (identical(other.selectedTool, selectedTool) ||
                other.selectedTool == selectedTool) &&
            (identical(other.defaultSettings, defaultSettings) ||
                other.defaultSettings == defaultSettings) &&
            const DeepCollectionEquality()
                .equals(other._toolSettings, _toolSettings) &&
            (identical(other.painterController, painterController) ||
                other.painterController == painterController) &&
            (identical(other.hasUnsavedChanges, hasUnsavedChanges) ||
                other.hasUnsavedChanges == hasUnsavedChanges) &&
            (identical(other.undoableActionsCount, undoableActionsCount) ||
                other.undoableActionsCount == undoableActionsCount) &&
            (identical(other.redoableActionsCount, redoableActionsCount) ||
                other.redoableActionsCount == redoableActionsCount) &&
            const DeepCollectionEquality()
                .equals(other._selectedObjects, _selectedObjects) &&
            (identical(other.isTextCacheVisible, isTextCacheVisible) ||
                other.isTextCacheVisible == isTextCacheVisible) &&
            (identical(other.originalImageSize, originalImageSize) ||
                other.originalImageSize == originalImageSize) &&
            (identical(other.wallpaperPadding, wallpaperPadding) ||
                other.wallpaperPadding == wallpaperPadding) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other.screenshotData, screenshotData));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      selectedTool,
      defaultSettings,
      const DeepCollectionEquality().hash(_toolSettings),
      painterController,
      hasUnsavedChanges,
      undoableActionsCount,
      redoableActionsCount,
      const DeepCollectionEquality().hash(_selectedObjects),
      isTextCacheVisible,
      originalImageSize,
      wallpaperPadding,
      isLoading,
      const DeepCollectionEquality().hash(screenshotData));

  @override
  String toString() {
    return 'EditorState(selectedTool: $selectedTool, defaultSettings: $defaultSettings, toolSettings: $toolSettings, painterController: $painterController, hasUnsavedChanges: $hasUnsavedChanges, undoableActionsCount: $undoableActionsCount, redoableActionsCount: $redoableActionsCount, selectedObjects: $selectedObjects, isTextCacheVisible: $isTextCacheVisible, originalImageSize: $originalImageSize, wallpaperPadding: $wallpaperPadding, isLoading: $isLoading, screenshotData: $screenshotData)';
  }
}

/// @nodoc
abstract mixin class _$EditorStateCopyWith<$Res>
    implements $EditorStateCopyWith<$Res> {
  factory _$EditorStateCopyWith(
          _EditorState value, $Res Function(_EditorState) _then) =
      __$EditorStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ToolType selectedTool,
      ToolSettings defaultSettings,
      Map<ToolType, ToolSettings> toolSettings,
      @JsonKey(includeFromJson: false, includeToJson: false)
      PainterController? painterController,
      bool hasUnsavedChanges,
      int undoableActionsCount,
      int redoableActionsCount,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<Drawable> selectedObjects,
      bool isTextCacheVisible,
      Size? originalImageSize,
      EdgeInsets wallpaperPadding,
      bool isLoading,
      Uint8List? screenshotData});

  @override
  $ToolSettingsCopyWith<$Res> get defaultSettings;
}

/// @nodoc
class __$EditorStateCopyWithImpl<$Res> implements _$EditorStateCopyWith<$Res> {
  __$EditorStateCopyWithImpl(this._self, this._then);

  final _EditorState _self;
  final $Res Function(_EditorState) _then;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? selectedTool = null,
    Object? defaultSettings = null,
    Object? toolSettings = null,
    Object? painterController = freezed,
    Object? hasUnsavedChanges = null,
    Object? undoableActionsCount = null,
    Object? redoableActionsCount = null,
    Object? selectedObjects = null,
    Object? isTextCacheVisible = null,
    Object? originalImageSize = freezed,
    Object? wallpaperPadding = null,
    Object? isLoading = null,
    Object? screenshotData = freezed,
  }) {
    return _then(_EditorState(
      selectedTool: null == selectedTool
          ? _self.selectedTool
          : selectedTool // ignore: cast_nullable_to_non_nullable
              as ToolType,
      defaultSettings: null == defaultSettings
          ? _self.defaultSettings
          : defaultSettings // ignore: cast_nullable_to_non_nullable
              as ToolSettings,
      toolSettings: null == toolSettings
          ? _self._toolSettings
          : toolSettings // ignore: cast_nullable_to_non_nullable
              as Map<ToolType, ToolSettings>,
      painterController: freezed == painterController
          ? _self.painterController
          : painterController // ignore: cast_nullable_to_non_nullable
              as PainterController?,
      hasUnsavedChanges: null == hasUnsavedChanges
          ? _self.hasUnsavedChanges
          : hasUnsavedChanges // ignore: cast_nullable_to_non_nullable
              as bool,
      undoableActionsCount: null == undoableActionsCount
          ? _self.undoableActionsCount
          : undoableActionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      redoableActionsCount: null == redoableActionsCount
          ? _self.redoableActionsCount
          : redoableActionsCount // ignore: cast_nullable_to_non_nullable
              as int,
      selectedObjects: null == selectedObjects
          ? _self._selectedObjects
          : selectedObjects // ignore: cast_nullable_to_non_nullable
              as List<Drawable>,
      isTextCacheVisible: null == isTextCacheVisible
          ? _self.isTextCacheVisible
          : isTextCacheVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      originalImageSize: freezed == originalImageSize
          ? _self.originalImageSize
          : originalImageSize // ignore: cast_nullable_to_non_nullable
              as Size?,
      wallpaperPadding: null == wallpaperPadding
          ? _self.wallpaperPadding
          : wallpaperPadding // ignore: cast_nullable_to_non_nullable
              as EdgeInsets,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      screenshotData: freezed == screenshotData
          ? _self.screenshotData
          : screenshotData // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
    ));
  }

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ToolSettingsCopyWith<$Res> get defaultSettings {
    return $ToolSettingsCopyWith<$Res>(_self.defaultSettings, (value) {
      return _then(_self.copyWith(defaultSettings: value));
    });
  }
}

// dart format on
