import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import 'core/main_app.dart';

final _logger = Logger();

/// 应用程序主入口点
void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 配置窗口属性
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    ),
    () async {
      // 窗口准备好显示后的操作
      await windowManager.show();
      await windowManager.focus();

      // 在macOS上初始化状态栏服务
      if (Platform.isMacOS) {
        await _initializeStatusBar();
      }
    },
  );

  // 运行应用
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

Future<void> _initializeStatusBar() async {
  try {
    // 注意：我们不再调用Flutter端的状态栏服务初始化方法
    // 因为我们已经在原生Swift代码中实现了状态栏功能
    // 这里只是为了保持代码结构的完整性

    _logger.i('状态栏由原生代码处理，Flutter端不再初始化');

    // 如果将来需要在Flutter端处理状态栏点击事件，可以取消下面的注释
    /*
    final statusBarService = StatusBarService.instance;
    statusBarService.onStatusBarItemClicked = () async {
      // 当状态栏图标被点击时的处理逻辑
      _logger.i('状态栏图标被点击');
    };
    */
  } catch (e) {
    _logger.e('状态栏处理出错: $e');
  }
}
