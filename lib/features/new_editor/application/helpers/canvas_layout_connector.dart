import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import '../managers/layout_manager.dart';
import '../providers/state_providers.dart';

/// 画布布局连接器提供者 - 全局统一版本
final canvasLayoutConnectorProvider = Provider<CanvasLayoutConnector>((ref) {
  return CanvasLayoutConnector(ref);
});

/// 画布布局连接器
/// 处理新截图的布局逻辑，连接布局管理器和画布组件
class CanvasLayoutConnector {
  final Ref _ref;
  final Logger _logger = Logger();

  CanvasLayoutConnector(this._ref);

  /// 处理新截图
  /// 重置状态并根据新截图计算布局
  Future<double> handleNewScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) async {
    _logger.d('处理新截图: 尺寸=${size.width}x${size.height}, 缩放=$capturedScale');

    // 重置布局状态，确保前一个截图的数据被完全清除
    _ref.read(layoutManagerProvider).resetLayoutState();

    // 设置加载状态
    _ref.read(canvasProvider.notifier).setLoading(true);

    try {
      // 获取当前窗口尺寸
      final windowSize = await windowManager.getSize();
      _logger.d('当前窗口尺寸: ${windowSize.width}x${windowSize.height}');

      // 更新可用屏幕尺寸
      _ref.read(layoutManagerProvider).updateAvailableScreenSize(windowSize);

      // 直接加载截图数据到画布
      _logger.d('直接加载截图数据到画布...');
      // 使用Future.microtask确保在widget树构建完成后更新状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).loadScreenshot(
              imageData,
              size,
              capturedScale: capturedScale,
              uiImage: uiImage,
            );
      });

      // 等待截图加载完成
      await Future.delayed(Duration(milliseconds: 50));

      // 计算初始布局，强制居中显示
      _logger.d('计算初始布局...');
      final initialScaleFactor =
          _ref.read(layoutManagerProvider).calculateInitialLayout(size);

      _logger.d('新截图处理完成，初始缩放因子=$initialScaleFactor');

      // 设置加载完成状态
      _ref.read(canvasProvider.notifier).setLoading(false);

      return initialScaleFactor;
    } catch (e, stack) {
      _logger.e('处理新截图出错', error: e, stackTrace: stack);

      // 确保即使出错也取消加载状态
      _ref.read(canvasProvider.notifier).setLoading(false);

      // 出错时返回默认缩放
      return 1.0;
    }
  }

  /// 加载并处理截图
  /// 直接处理图像数据，避免调用editorStateCore以防止循环依赖
  Future<double> processScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) async {
    _logger.d(
        '直接处理截图: 尺寸=${size.width}x${size.height}, 比例=$capturedScale, 数据长度=${imageData.length} 字节');

    try {
      if (imageData.isEmpty) {
        _logger.e('直接处理截图: 收到的图像数据为空！');
        throw Exception('截图数据为空，无法处理');
      }

      // 重置布局状态，确保前一个截图的数据被完全清除
      _ref.read(layoutManagerProvider).resetLayoutState();
      _logger.d('布局状态已重置');

      // 设置加载状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(true);
      });
      _logger.d('设置加载状态为true');

      // 获取当前窗口尺寸并更新
      try {
        final windowSize = await windowManager.getSize();
        _logger.d('当前窗口尺寸=${windowSize.width}x${windowSize.height}');
        _ref.read(layoutManagerProvider).updateAvailableScreenSize(windowSize);
      } catch (e) {
        _logger.w('获取窗口尺寸失败，使用默认值', error: e);
        _ref
            .read(layoutManagerProvider)
            .updateAvailableScreenSize(Size(1920, 1080));
      }

      // 使用Future.microtask确保在widget树构建完成后更新状态
      await Future.microtask(() {
        _logger.d('准备加载截图数据到画布，数据长度=${imageData.length}');
        _ref.read(canvasProvider.notifier).loadScreenshot(
              imageData,
              size,
              capturedScale: capturedScale,
              uiImage: uiImage,
            );
      });
      _logger.d('截图数据已加载到画布');

      // 等待截图加载完成 - 增加延迟以确保处理完成
      await Future.delayed(Duration(milliseconds: 200));

      // 计算初始布局，强制居中显示
      final initialScaleFactor =
          _ref.read(layoutManagerProvider).calculateInitialLayout(size);
      _logger.d('初始布局已计算，缩放因子=$initialScaleFactor');

      // 设置加载完成状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(false);
      });
      _logger.d('设置加载状态为false');

      _logger.d('截图处理完成，初始缩放因子=$initialScaleFactor');

      return initialScaleFactor;
    } catch (e, stack) {
      _logger.e('处理截图失败', error: e, stackTrace: stack);
      // 确保在出错时也取消加载状态
      await Future.microtask(() {
        _ref.read(canvasProvider.notifier).setLoading(false);
      });
      // 确保在出错时也返回一个默认值
      return 1.0;
    }
  }

  /// 处理窗口大小变化
  void handleWindowResize(Size newSize) {
    _logger.d('处理窗口大小变化: ${newSize.width}x${newSize.height}');

    // 更新可用屏幕尺寸
    _ref.read(layoutManagerProvider).updateAvailableScreenSize(newSize);

    // 获取当前画布状态
    final canvasState = _ref.read(canvasProvider);

    // 如果有原始图像尺寸，重新计算布局
    if (canvasState.originalImageSize != null) {
      _ref
          .read(layoutManagerProvider)
          .calculateInitialLayout(canvasState.originalImageSize!);
    }
  }

  /// 处理壁纸内边距变化
  void handlePaddingChange(EdgeInsets padding) {
    _logger.d('处理壁纸内边距变化: $padding');

    // 应用新的内边距到画布
    _ref.read(canvasProvider.notifier).setPadding(padding);

    // 重新调整内容以适应视口
    _ref.read(canvasProvider.notifier).fitContent();
  }
}
