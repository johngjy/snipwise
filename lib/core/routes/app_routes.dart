import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/editor/presentation/pages/cached_text_example_page.dart';
import '../../features/editor/presentation/pages/editor_page.dart';
import '../../features/capture/presentation/pages/capture_page.dart';

/// 应用路由配置
class AppRoutes {
  /// 定义所有路由路径
  static const String home = '/';
  static const String cachedTextExample = '/cached-text-example';
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

      // 缓存文本示例页面
      GoRoute(
        path: cachedTextExample,
        builder: (context, state) => const CachedTextExamplePage(),
      ),
      
      // 编辑器页面
      GoRoute(
        path: editor,
        builder: (context, state) {
          // 获取路由参数
          final Map<String, dynamic> params = state.extra as Map<String, dynamic>? ?? {};
          final imageData = params['imageData'];
          final scale = params['scale'];
          final logicalRect = params['logicalRect'];
          return EditorPage(
            imageData: imageData,
            scale: scale,
            logicalRect: logicalRect,
          );
        },
      ),
    ],
  );
}

/// 主页操作按钮
class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'cached_text_example',
      onPressed: () => context.push(AppRoutes.cachedTextExample),
      icon: const Icon(Icons.text_fields),
      label: const Text('缓存文本示例'),
    );
  }
}
