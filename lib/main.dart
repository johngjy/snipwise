import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/status_bar_service.dart';
import 'core/main_app.dart';
import 'core/routes/app_routes.dart';

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
    
    print('状态栏由原生代码处理，Flutter端不再初始化');
    
    // 如果将来需要在Flutter端处理状态栏点击事件，可以取消下面的注释
    /*
    final statusBarService = StatusBarService.instance;
    statusBarService.onStatusBarItemClicked = () async {
      // 当状态栏图标被点击时的处理逻辑
      print('状态栏图标被点击');
    };
    */
  } catch (e) {
    print('状态栏处理出错: $e');
  }
}

/// 显示状态栏选项
void _showStatusBarOptions(StatusBarService statusBarService) {
  // 这里可以添加原生菜单项的实现
  // 目前使用日志模拟
  print('状态栏菜单选项：');
  print('1. 主页');
  print('2. 缓存文本示例');

  // 在实际应用中，这里可以通过原生方法调用添加菜单项
  // 当用户点击这些菜单项时，原生代码会通过statusItemClicked方法通知Flutter
}
