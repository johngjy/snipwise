import 'package:flutter/material.dart';
import 'app_routes.dart'; // Restore original import
import '../../features/capture/presentation/pages/capture_page.dart';
import '../../features/editor/presentation/pages/editor_page.dart';
// Remove unused imports
// import 'package:window_manager/window_manager.dart';
// import '../../features/home/presentation/pages/home_page.dart';
// import '../../features/settings/presentation/pages/settings_page.dart';

/// 应用路由器
class AppRouter {
  /// 生成路由
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 首次启动时检查页面历史，避免创建重复页面 - Keep original logic
    // if (settings.name == AppRoutes.capture &&
    //     Navigator.defaultRouteName != AppRoutes.capture) {
    //   return MaterialPageRoute(builder: (_) => const CapturePage());
    // }

    switch (settings.name) {
      case AppRoutes.capture:
        return MaterialPageRoute(builder: (_) => const CapturePage());

      case AppRoutes.editor:
        // 编辑页面可能需要接收截图的数据
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => EditorPage(
            imageData: args is Map<String, dynamic> ? args['imageData'] : null,
            // imagePath: args is Map<String, dynamic> ? args['imagePath'] : null, // REMOVED this line
            scale: args is Map<String, dynamic> ? args['scale'] : null,
            logicalRect:
                args is Map<String, dynamic> ? args['logicalRect'] : null,
          ),
        );

      // Add cases for home and settings if they exist in AppRoutes
      // case AppRoutes.home:
      //   return MaterialPageRoute(builder: (_) => const HomePage());
      // case AppRoutes.settings:
      //  return MaterialPageRoute(builder: (_) => const SettingsPage());

      default:
        // 默认返回截图页面 - Keep original default
        return MaterialPageRoute(builder: (_) => const CapturePage());
    }
  }
}
