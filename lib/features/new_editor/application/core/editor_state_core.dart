import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import '../states/canvas_state.dart';
import '../states/wallpaper_state.dart';
import '../providers/state_providers.dart';
import '../helpers/canvas_layout_connector.dart'
    show canvasLayoutConnectorProvider;
import '../managers/layout_manager.dart';
import '../providers/canvas_providers.dart' show canvasTransformProvider;

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
  /// 统一更新画布状态和壁纸内边距，使用新的布局管理器
  Future<double> loadScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) async {
    _logger.d(
        '核心状态管理器: 开始加载截图, 尺寸=${size.width}x${size.height}, 比例=$capturedScale, 数据长度=${imageData.length} 字节');

    try {
      if (imageData.isEmpty) {
        _logger.e('核心状态管理器: 收到的图像数据为空！');
        throw Exception('截图数据为空，无法加载');
      }

      // 先设置加载状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(true);
      });
      _logger.d('核心状态管理器: 已设置加载状态=true');

      // 重置所有状态
      await Future.microtask(() {
        resetAllState();
        _logger.d('核心状态管理器: 已重置所有状态');
      });

      // 使用布局连接器处理截图
      final connector = _ref.read(canvasLayoutConnectorProvider);
      _logger.d('核心状态管理器: 使用布局连接器处理截图');

      // 使用processScreenshot方法避免循环依赖
      final initialScaleFactor = await connector.processScreenshot(
          imageData, size,
          capturedScale: capturedScale, uiImage: uiImage);

      _logger.d('核心状态管理器: 截图加载完成，初始缩放因子=$initialScaleFactor');

      return initialScaleFactor;
    } catch (e, stack) {
      _logger.e('核心状态管理器: 截图加载失败', error: e, stackTrace: stack);
      // 确保在出错时取消加载状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(false);
      });
      // 确保在出错时也返回一个默认值
      return 1.0;
    }
  }

  /// 处理第二次及后续截图
  /// 完全重置状态并基于新截图重新计算布局
  Future<double> handleSubsequentScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) async {
    _logger.d(
        '核心状态管理器: 处理后续截图，尺寸=${size.width}x${size.height}, 比例=$capturedScale');

    try {
      // 先设置加载状态，避免用户看到过渡状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(true);
      });
      _logger.d('核心状态管理器: 设置加载状态为true');

      // 重置所有状态 - 确保完全清除旧数据
      await Future.microtask(() {
        // 重置基础状态
        resetAllState();
        _logger.d('核心状态管理器: 已重置所有状态');

        // 确保画布变换重置
        _ref.read(canvasTransformProvider.notifier).setZoomLevel(1.0);
        _ref.read(canvasTransformProvider.notifier).setOffset(Offset.zero);
        _logger.d('核心状态管理器: 已重置画布变换');

        // 确保画布内边距重置
        _ref.read(canvasProvider.notifier).setPadding(EdgeInsets.zero);
        _logger.d('核心状态管理器: 已重置画布内边距');

        // 确保壁纸面板隐藏
        _ref.read(wallpaperPanelVisibleProvider.notifier).state = false;
        _logger.d('核心状态管理器: 已隐藏壁纸面板');
      });

      // 等待状态重置完成
      await Future.delayed(Duration(milliseconds: 150));
      _logger.d('核心状态管理器: 延迟完成，确保状态重置已应用');

      // 加载新截图
      _logger.d('核心状态管理器: 开始加载新截图');
      final result = await loadScreenshot(imageData, size,
          capturedScale: capturedScale, uiImage: uiImage);

      _logger.d('核心状态管理器: 后续截图处理完成，初始缩放因子=$result');
      return result;
    } catch (e, stack) {
      _logger.e('核心状态管理器: 处理后续截图失败', error: e, stackTrace: stack);
      // 确保即使出错也取消加载状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(false);
      });
      // 确保在出错时也返回一个默认值
      return 1.0;
    }
  }

  /// 设置壁纸内边距
  /// 同时更新壁纸设置和画布边距
  void setWallpaperPadding(double padding) {
    _logger.d('核心状态管理器: 设置内边距=$padding');

    // 更新壁纸设置
    _ref.read(wallpaperProvider.notifier).setPadding(padding);

    // 使用布局连接器处理内边距变化
    _ref
        .read(canvasLayoutConnectorProvider)
        .handlePaddingChange(EdgeInsets.all(padding));
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

    // 重置布局状态
    _ref.read(layoutManagerProvider).resetLayoutState();

    // 重置画布变换
    _ref.read(canvasProvider.notifier).resetTransform();

    // 重置壁纸设置
    _ref.read(wallpaperProvider.notifier).resetToDefaults();

    // 重置壁纸面板显示状态
    _ref.read(wallpaperPanelVisibleProvider.notifier).state = false;
  }

  /// 调整内容适应视口
  double fitContentToViewport() {
    _logger.d('核心状态管理器: 调整内容适应视口');

    // 获取当前画布状态
    final state = _ref.read(canvasProvider);

    // 如果有原始图像尺寸，重新计算布局
    if (state.originalImageSize != null) {
      return _ref
          .read(layoutManagerProvider)
          .calculateInitialLayout(state.originalImageSize!);
    } else {
      // 否则使用常规方法
      _ref.read(canvasProvider.notifier).fitContent();
      return state.scale;
    }
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

  /// 处理窗口大小变化
  void handleWindowResize(Size newSize) {
    _logger.d('核心状态管理器: 处理窗口大小变化 ${newSize.width}x${newSize.height}');

    _ref.read(canvasLayoutConnectorProvider).handleWindowResize(newSize);
  }
}
