import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/editor_page.dart';

/// 编辑器路由管理
class EditorRoutes {
  /// 获取编辑器相关路由
  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) {
          final Map<String, dynamic> params =
              state.extra as Map<String, dynamic>? ?? {};

          final dynamic imageData = params['imageData'];
          final double? scale = params['scale'];
          final Rect? logicalRect = params['logicalRect'];

          return EditorPage(
            imageData: imageData,
            scale: scale,
            logicalRect: logicalRect,
          );
        },
      ),
    ];
  }

  /// 导航到编辑器页面
  static void navigateToEditor(
    BuildContext context, {
    required dynamic imageData,
    double? scale,
    Rect? logicalRect,
  }) {
    Navigator.pushNamed(
      context,
      '/editor',
      arguments: {
        'imageData': imageData,
        'scale': scale,
        'logicalRect': logicalRect,
      },
    );
  }
}
