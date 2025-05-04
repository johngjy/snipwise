import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/pages/editor_page.dart';

/// 新版编辑器路由配置
class NewEditorRoutes {
  /// 路由名称
  static const String editorRouteName = 'new-editor';

  /// 路由路径
  static const String editorRoutePath = '/new-editor';

  /// 获取编辑器路由配置
  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        name: editorRouteName,
        path: editorRoutePath,
        builder: (context, state) {
          // 从路由参数中获取图像数据
          final extra = state.extra as Map<String, dynamic>?;
          final imageData = extra?['imageData'] as Uint8List?;
          final imageSize = extra?['imageSize'] as Size?;
          final scale = extra?['scale'] as double?;

          // 返回编辑器页面
          return NewEditorPage(
            imageData: imageData,
            imageSize: imageSize,
            scale: scale,
          );
        },
      ),
    ];
  }

  /// 导航到编辑器页面
  static void navigateToEditor(
    BuildContext context, {
    required Uint8List imageData,
    Size? imageSize,
    double? scale,
  }) {
    GoRouter.of(context).goNamed(
      editorRouteName,
      extra: {
        'imageData': imageData,
        'imageSize': imageSize,
        'scale': scale,
      },
    );
  }
}
