import 'package:flutter/material.dart';
import 'package:desktop_window/desktop_window.dart';
import 'app/routes/app_router.dart';
import 'app/routes/app_routes.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置桌面窗口大小
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DesktopWindow.setWindowSize(const Size(1000, 180));
    await DesktopWindow.setMinWindowSize(const Size(800, 180));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snipwise',
      debugShowCheckedModeBanner: false,
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
    );
  }
}

/// 导航观察器，用于监控页面导航情况
class _NavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 可以在这里添加导航日志或防止重复页面的逻辑
  }
}
