import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/capture/presentation/pages/capture_page.dart';
import '../../features/editor/presentation/pages/editor_page.dart';

/// 应用路由器
class AppRouter {
  /// 生成路由
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 首次启动时检查页面历史，避免创建重复页面
    if (settings.name == AppRoutes.capture &&
        Navigator.defaultRouteName != AppRoutes.capture) {
      return MaterialPageRoute(builder: (_) => const CapturePage());
    }

    switch (settings.name) {
      case AppRoutes.capture:
        return MaterialPageRoute(builder: (_) => const CapturePage());

      case AppRoutes.editor:
        // 编辑页面可能需要接收截图的数据
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => EditorPage(
            imageData: args is Map<String, dynamic> ? args['imageData'] : null,
            imagePath: args is Map<String, dynamic> ? args['imagePath'] : null,
          ),
        );

      default:
        // 默认返回截图页面
        return MaterialPageRoute(builder: (_) => const CapturePage());
    }
  }
}
