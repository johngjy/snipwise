import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// 处理与原生平台通信的服务
class PlatformChannelService {
  static final PlatformChannelService _instance = PlatformChannelService._();
  static PlatformChannelService get instance => _instance;

  final Logger _logger = Logger();
  final MethodChannel _windowChannel =
      const MethodChannel('com.snipwise.window');

  PlatformChannelService._();

  /// 隐藏窗口（不是最小化）
  Future<bool> hideWindow() async {
    try {
      _logger.d('通过原生方法通道隐藏窗口');
      final bool? result =
          await _windowChannel.invokeMethod<bool>('hideWindow');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('隐藏窗口失败', error: e);
      return false;
    }
  }

  /// 显示窗口并激活（显示在前台）
  Future<bool> showAndActivateWindow() async {
    try {
      _logger.d('通过原生方法通道显示并激活窗口');
      final bool? result =
          await _windowChannel.invokeMethod<bool>('showAndActivateWindow');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('显示和激活窗口失败', error: e);
      return false;
    }
  }

  /// 截图流程 - 隐藏窗口，执行截图，然后重新显示窗口
  Future<String?> startScreenshotFlow() async {
    try {
      _logger.d('启动原生截图流程');
      final String? imagePath =
          await _windowChannel.invokeMethod<String>('startScreenshotFlow');
      return imagePath;
    } on PlatformException catch (e) {
      _logger.e('截图流程失败', error: e);
      return null;
    }
  }
}
