import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../states/canvas_state.dart';
import '../states/wallpaper_state.dart';
import '../providers/state_providers.dart';

/// 编辑器核心状态管理器
/// 协调各个状态之间的交互，提供统一的状态管理接口
class EditorStateCore {
  final Ref _ref;
  final Logger _logger = Logger();

  EditorStateCore(this._ref);

  // ====== 状态访问接口 ======

  /// 获取画布状态
  CanvasState get canvasState => _ref.read(canvasProvider);

  /// 获取壁纸设置状态
  WallpaperState get wallpaperState => _ref.read(wallpaperProvider);

  // ====== 协调更新接口 ======

  /// 加载截图数据
  /// 统一更新画布状态和壁纸内边距
  Future<double> loadScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) async {
    _logger.d('核心状态管理器: 加载截图');

    // 获取当前壁纸内边距并同步到画布状态
    final padding = _ref.read(wallpaperProvider).padding;
    final edgeInsets = EdgeInsets.all(padding);

    // 设置加载状态
    _ref.read(canvasProvider.notifier).setLoading(true);

    // 加载截图数据
    _ref.read(canvasProvider.notifier).loadScreenshot(
          imageData,
          size,
          capturedScale: capturedScale,
          uiImage: uiImage,
        );

    // 适应内容到视口
    _ref.read(canvasProvider.notifier).fitContent();

    // 获取适合视口的缩放比例
    final fitScale = canvasState.scale;

    _logger.d('核心状态管理器: 截图加载完成，适合缩放比例=$fitScale');

    return fitScale;
  }

  /// 设置壁纸内边距
  /// 同时更新壁纸设置和画布边距
  void setWallpaperPadding(double padding) {
    _logger.d('核心状态管理器: 设置内边距=$padding');

    // 更新壁纸设置
    _ref.read(wallpaperProvider.notifier).setPadding(padding);

    // 更新画布内边距
    _ref.read(canvasProvider.notifier).setPadding(EdgeInsets.all(padding));
  }

  /// 设置缩放级别
  void setZoomLevel(double scale, {Offset? focalPoint}) {
    _logger.d('核心状态管理器: 设置缩放级别=$scale, 焦点=$focalPoint');

    _ref.read(canvasProvider.notifier).setScale(scale, focalPoint: focalPoint);
  }

  /// 更新画布偏移
  void updateCanvasOffset(Offset delta) {
    _logger.d('核心状态管理器: 更新画布偏移=$delta');

    _ref.read(canvasProvider.notifier).updateOffset(delta);
  }

  /// 设置壁纸类型
  void setWallpaperType(WallpaperType type) {
    _logger.d('核心状态管理器: 设置壁纸类型=$type');

    _ref.read(wallpaperProvider.notifier).setType(type);
  }

  /// 设置背景颜色
  void setBackgroundColor(Color color) {
    _logger.d('核心状态管理器: 设置背景颜色=$color');

    _ref.read(wallpaperProvider.notifier).setBackgroundColor(color);
  }

  /// 设置渐变预设
  void setGradientPreset(int index) {
    _logger.d('核心状态管理器: 设置渐变预设=$index');

    _ref.read(wallpaperProvider.notifier).setGradient(index);
  }

  /// 设置模糊背景
  void setBlurredBackground(int index) {
    _logger.d('核心状态管理器: 设置模糊背景=$index');

    _ref.read(wallpaperProvider.notifier).setBlurred(index);
  }

  /// 设置自定义壁纸
  void setCustomWallpaper(Uint8List imageData) {
    _logger.d('核心状态管理器: 设置自定义壁纸');

    _ref.read(wallpaperProvider.notifier).setCustomWallpaper(imageData);
  }

  /// 设置圆角半径
  void setCornerRadius(double radius) {
    _logger.d('核心状态管理器: 设置圆角半径=$radius');

    _ref.read(wallpaperProvider.notifier).setCornerRadius(radius);
  }

  /// 设置阴影半径
  void setShadowRadius(double radius) {
    _logger.d('核心状态管理器: 设置阴影半径=$radius');

    _ref.read(wallpaperProvider.notifier).setShadowRadius(radius);
  }

  /// 设置阴影颜色
  void setShadowColor(Color color) {
    _logger.d('核心状态管理器: 设置阴影颜色=$color');

    _ref.read(wallpaperProvider.notifier).setShadowColor(color);
  }

  /// 设置阴影偏移
  void setShadowOffset(Offset offset) {
    _logger.d('核心状态管理器: 设置阴影偏移=$offset');

    _ref.read(wallpaperProvider.notifier).setShadowOffset(offset);
  }

  /// 重置所有状态
  void resetAllState() {
    _logger.d('核心状态管理器: 重置所有状态');

    // 重置画布变换
    _ref.read(canvasProvider.notifier).resetTransform();

    // 重置壁纸设置
    _ref.read(wallpaperProvider.notifier).resetToDefaults();
  }

  /// 调整内容适应视口
  double fitContentToViewport() {
    _logger.d('核心状态管理器: 调整内容适应视口');

    _ref.read(canvasProvider.notifier).fitContent();

    return canvasState.scale;
  }

  /// 切换壁纸面板可见性
  void toggleWallpaperPanel() {
    final isVisible = _ref.read(wallpaperPanelVisibleProvider);
    _logger.d('核心状态管理器: 切换壁纸面板可见性，当前=${isVisible}');

    _ref.read(wallpaperPanelVisibleProvider.notifier).state = !isVisible;
  }

  /// 处理缩放手势开始
  void handleScaleStart(Offset focalPoint) {
    _logger.d('核心状态管理器: 处理缩放手势开始，焦点=$focalPoint');

    _ref.read(canvasProvider.notifier).startScale(focalPoint);
  }

  /// 处理缩放手势更新
  void handleScaleUpdate(double scale, Offset focalPoint) {
    _ref.read(canvasProvider.notifier).updateScale(scale, focalPoint);
  }

  /// 处理缩放手势结束
  void handleScaleEnd() {
    _logger.d('核心状态管理器: 处理缩放手势结束');

    _ref.read(canvasProvider.notifier).endScale();
  }
}
