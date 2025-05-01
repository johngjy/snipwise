import 'package:flutter/services.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:logger/logger.dart';

/// 窗口操作服务
class WindowService with WindowListener {
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
  Future<void> minimizeWindow({bool withoutAnimation = false}) async {
    try {
      if (Platform.isMacOS) {
        if (withoutAnimation) {
          // 使用无动画最小化
          await _channel.invokeMethod('minimizeWithoutAnimation');
          _logger.d('Window minimized without animation');
        } else {
          // 使用普通最小化
          await _channel.invokeMethod('minimize');
          _logger.d('Window minimized with animation');
        }
      } else {
        // 使用 window_manager 在其他平台最小化
        await windowManager.minimize();
        _logger.d('Window minimized using window_manager');
      }
    } catch (e) {
      _logger.e('Failed to minimize window', error: e);
    }
  }

  /// 无动画最小化窗口 - 截图时使用
  Future<void> minimizeWindowWithoutAnimation() async {
    await minimizeWindow(withoutAnimation: true);
  }

  /// 关闭窗口
  Future<void> closeWindow() async {
    _logger.i('手动关闭窗口被调用...');
    try {
      // 统一使用 windowManager.close()，理论上它应该处理好与原生按钮的交互
      await windowManager.close();
      _logger.i('windowManager.close() 调用成功，但窗口可能仍未关闭。');
    } catch (e) {
      // 如果 close() 失败（例如窗口已被阻止关闭），则记录错误
      _logger.e('windowManager.close() 调用失败。', error: e);

      // 强制退出应用 - 作为最后的手段
      exit(0);
    }
  }

  /// 开始拖动窗口
  Future<void> startDragging() async {
    try {
      await windowManager.startDragging();
      _logger.d('Started dragging window');
    } catch (e) {
      _logger.e('Failed to start dragging window', error: e);
    }
  }

  Future<void> initialize() async {
    try {
      await windowManager.ensureInitialized();

      // 针对各平台的特定设置
      if (Platform.isMacOS) {
        // macOS 特定窗口设置
        await windowManager
            .setTitleBarStyle(TitleBarStyle.hidden); // 允许自定义标题栏但保留原生控制按钮
        await windowManager.setResizable(true); // 允许窗口调整大小
        await windowManager.setClosable(true); // 明确允许窗口关闭
        await windowManager.setMinimizable(true);
      } else {
        // 非 macOS 平台设置
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      }

      // 通用设置
      await windowManager.setTitle('Snipwise');

      // 注册窗口监听器
      windowManager.addListener(this);

      _logger.d('Window manager initialized for ${Platform.operatingSystem}');
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

  /// 设置窗口大小
  Future<void> resizeWindow(Size size) async {
    try {
      await windowManager.setSize(size);
      _logger.d('Window size set to: ${size.width} x ${size.height}');
    } catch (e) {
      _logger.e('Failed to set window size', error: e);
    }
  }

  // WindowListener 接口实现 - 这些方法将被 window_manager 自动调用

  @override
  void onWindowClose() {
    _logger.i('捕获到窗口关闭事件 (onWindowClose)');
    // 直接调用退出，不再调用 windowManager.close()
    exit(0);
  }

  @override
  void onWindowFocus() {
    // 窗口获得焦点时的处理
    _logger.d('Window focused');
  }

  @override
  void onWindowBlur() {
    // 窗口失去焦点时的处理
    try {
      // 只记录，但不做其他操作，避免与screen_capturer冲突
      _logger.i('Window blurred');
    } catch (e) {
      // 错误被静默捕获，不传播
    }
  }

  @override
  void onWindowMaximize() {
    // 窗口最大化时的处理
    _logger.d('Window maximized');
  }

  @override
  void onWindowUnmaximize() {
    // 窗口取消最大化时的处理
    _logger.d('Window unmaximized');
  }

  @override
  void onWindowMinimize() {
    // 窗口最小化时的处理
    _logger.d('Window minimized');
  }

  @override
  void onWindowRestore() {
    // 窗口恢复时的处理
    _logger.d('Window restored');
  }

  @override
  void onWindowResize() {
    // 窗口大小改变时的处理
    _logger.d('Window resized');
  }

  @override
  void onWindowMove() {
    // 窗口移动时的处理
    _logger.d('Window moved');
  }

  @override
  void onWindowEnterFullScreen() {
    // 窗口进入全屏时的处理
    _logger.d('Window entered full screen');
  }

  @override
  void onWindowLeaveFullScreen() {
    // 窗口离开全屏时的处理
    _logger.d('Window left full screen');
  }
}
