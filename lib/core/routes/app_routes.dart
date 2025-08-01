import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/editor/presentation/pages/editor_page.dart';
import '../../features/capture/presentation/pages/capture_page.dart';
import '../../features/editor/routes.dart';

/// 应用路由配置
class AppRoutes {
  /// 定义所有路由路径
  static const String home = '/';
  static const String editor = '/editor';

  /// 创建GoRouter实例
  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    routes: [
      // 主页路由 - 直接使用截图捕获页面
      GoRoute(
        path: home,
        builder: (context, state) => const CapturePage(),
      ),

      // 编辑器路由
      ...EditorRoutes.getRoutes(),
    ],
  );
}
