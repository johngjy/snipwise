import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'app/routes/app_routes.dart';
import 'app/routes/app_router.dart';
import 'core/services/clipboard_service.dart';
import 'features/capture/services/capture_service.dart';
import 'features/capture/presentation/providers/capture_mode_provider.dart';
import 'features/hires_capture/presentation/providers/hires_capture_provider.dart';
import 'package:logger/logger.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    // 设置窗口属性
    await windowManager.setTitle('Snipwise');
    await windowManager.setPreventClose(true); // 拦截关闭事件
  }

  // 初始化服务
  initServices();

  // 设置系统UI覆盖样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // 运行App
  runApp(const MyApp());
}

/// 初始化各种服务
void initServices() {
  // 初始化剪贴板服务
  ClipboardService.instance;
}

/// 处理APP退出清理工作
void handleAppExit() {
  // 清理剪贴板服务资源
  ClipboardService.instance.dispose();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CaptureModeProvider()),
        ChangeNotifierProvider(create: (_) => HiResCapureProvider()),
      ],
      child: MaterialApp(
        title: 'Snipwise',
        debugShowCheckedModeBanner: false,
        navigatorKey: CaptureService.instance.navigatorKey,
        builder: (context, child) {
          return Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => child ?? const SizedBox(),
              ),
            ],
          );
        },
        theme: ThemeData(
          fontFamily: Platform.isMacOS ? '.AppleSystemUIFont' : 'Segoe UI',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
          ),
        ),
        darkTheme: ThemeData(
          fontFamily: Platform.isMacOS ? '.AppleSystemUIFont' : 'Segoe UI',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRoutes.capture,
        navigatorObservers: [_NavigatorObserver()],
      ),
    );
  }
}

/// 导航观察器，用于监控页面导航情况
class _NavigatorObserver extends NavigatorObserver {
  final _logger = Logger();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logger.d(
        '路由推入: ${route.settings.name} (前一个路由: ${previousRoute?.settings.name})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logger.d(
        '路由弹出: ${route.settings.name} (回到路由: ${previousRoute?.settings.name})');
  }
}
