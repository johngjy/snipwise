import 'package:flutter/services.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:logger/logger.dart';

/// 窗口操作服务
class WindowService {
  /// 窗口操作的方法通道
  static const MethodChannel _channel =
      MethodChannel('com.snipwise.app/window');

  /// 私有构造函数，防止实例化
  WindowService._();

  /// 单例实例
  static final WindowService _instance = WindowService._();

  /// 获取实例
  static WindowService get instance => _instance;

  final _logger = Logger();

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    if (Platform.isMacOS) {
      try {
        await _channel.invokeMethod('minimize');
      } catch (e) {
        _logger.e('Failed to minimize window', error: e);
      }
    }
  }

  /// 关闭窗口
  Future<void> closeWindow() async {
    if (Platform.isMacOS) {
      try {
        await SystemNavigator.pop();
      } catch (e) {
        _logger.e('Failed to close window', error: e);
      }
    }
  }

  Future<void> initialize() async {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
      await windowManager.setTitle('Snipwise');
      _logger.d('Window manager initialized');
    } catch (e) {
      _logger.e('Failed to initialize window manager', error: e);
    }
  }

  Future<void> setWindowTitle(String title) async {
    try {
      await windowManager.setTitle(title);
      _logger.d('Window title set to: $title');
    } catch (e) {
      _logger.e('Failed to set window title', error: e);
    }
  }
}
