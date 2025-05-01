import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'routes/app_routes.dart';
import '../features/status_bar/presentation/pages/status_bar_menu_page.dart';

/// 应用主入口
class MainApp extends ConsumerStatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WindowListener {
  /// 全局导航键
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // 注册方法通道处理程序
    _registerMethodCallHandlers();
  }

  /// 注册方法通道处理程序
  void _registerMethodCallHandlers() {
    // 状态栏相关的方法调用处理
    // 目前在状态栏服务中已经处理了
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  /// 窗口关闭请求回调
  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      // 显示确认对话框
      final navigatorState = navigatorKey.currentState;
      if (navigatorState != null && navigatorState.mounted) {
        final shouldClose = await showDialog<bool>(
          context: navigatorState.context,
          builder: (context) => AlertDialog(
            title: const Text('确认退出'),
            content: const Text('是否确认退出应用？未保存的更改将会丢失。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认'),
              ),
            ],
          ),
        );

        if (shouldClose == true) {
          await windowManager.destroy();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用GoRouter进行路由管理
    return MaterialApp.router(
      routerConfig: AppRoutes.router,
      title: 'Snipwise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
    );
  }
}

// 提供访问导航器的全局辅助方法
class NavigationService {
  static GlobalKey<NavigatorState> get navigatorKey =>
      _MainAppState.navigatorKey;

  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed<T>(routeName, arguments: arguments);
  }

  static void goBack<T>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }
}
