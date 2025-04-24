import 'package:flutter/services.dart';
import 'dart:io';

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

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    if (Platform.isMacOS) {
      try {
        await _channel.invokeMethod('minimize');
      } catch (e) {
        print('Failed to minimize window: $e');
      }
    }
  }

  /// 关闭窗口
  Future<void> closeWindow() async {
    if (Platform.isMacOS) {
      try {
        await SystemNavigator.pop();
      } catch (e) {
        print('Failed to close window: $e');
      }
    }
  }
}
