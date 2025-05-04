import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/tool_state.dart';
import 'painter_providers.dart';
import 'editor_providers.dart';
// import 'text_cache_provider.dart'; // This provider does not exist

/// PainterController 连接器
/// 连接 Riverpod 状态管理和 PainterController
class PainterControllerConnector extends ConsumerWidget {
  /// 子组件
  final Widget child;

  /// 构造函数
  const PainterControllerConnector({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听工具状态变化
    ref.listen<ToolState>(
      toolProvider,
      (previous, next) => _updatePainterController(ref, previous, next),
    );

    // 监听选中的对象变化 (Temporarily disable text cache logic)
    // ref.listen<ObjectDrawable?>(
    //   selectedObjectDrawableProvider,
    //   (previous, next) => _updateSelectedObject(ref, previous, next),
    // );

    return child;
  }

  /// 更新 PainterController 设置
  void _updatePainterController(
    WidgetRef ref,
    ToolState? previous,
    ToolState next,
  ) {
    // 如果工具没有变化，则不更新
    if (previous?.currentTool == next.currentTool) {
      return;
    }

    final controller = ref.read(painterControllerProvider);

    // 根据当前工具设置 PainterController 的模式
    switch (next.currentTool) {
      case EditorTool.select:
        // 选择工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为无，允许选择对象
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.rectangle:
        // 矩形工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为无，使用矩形工厂
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        final shapeSettings = controller.value.settings.shape.copyWith(
          factory: RectangleFactory(),
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
            shape: shapeSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.ellipse:
        // 椭圆工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为无，使用椭圆工厂
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        final shapeSettings = controller.value.settings.shape.copyWith(
          factory: OvalFactory(),
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
            shape: shapeSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.arrow:
        // 箭头工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为无，使用箭头工厂
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        final shapeSettings = controller.value.settings.shape.copyWith(
          factory: ArrowFactory(),
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
            shape: shapeSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.line:
        // 直线工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为无，使用直线工厂
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        final shapeSettings = controller.value.settings.shape.copyWith(
          factory: LineFactory(),
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
            shape: shapeSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.text:
        // 文本工具
        controller.textFocusNode?.requestFocus();
        // 设置自由绘制模式为无，允许添加文本
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.freehand:
        // 自由绘制工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为绘制
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.draw,
          color: Colors.red,
          strokeWidth: 2.0,
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
          ),
        );
        controller.notifyListeners();
        break;
      case EditorTool.highlight:
        // 高亮工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为绘制，使用黄色粗线
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.draw,
          color: const Color(0xFFFFFF00),
          strokeWidth: 10.0,
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
          ),
        );
        controller.notifyListeners();
        break;
      default:
        // 默认为选择工具
        controller.textFocusNode?.unfocus();
        // 设置自由绘制模式为无，允许选择对象
        final freeStyleSettings = controller.value.settings.freeStyle.copyWith(
          mode: FreeStyleMode.none,
        );
        controller.value = controller.value.copyWith(
          settings: controller.value.settings.copyWith(
            freeStyle: freeStyleSettings,
          ),
        );
        controller.notifyListeners();
        break;
    }
  }

  /// 更新选中的 ObjectDrawable 对象 (Temporarily disabled)
  // void _updateSelectedObject(
  //   WidgetRef ref,
  //   ObjectDrawable? previous,
  //   ObjectDrawable? next,
  // ) {
  //   // 如果选中对象没有变化，则不更新
  //   if (previous == next) {
  //     return;
  //   }

  //   // 更新选中对象
  //   if (next is TextDrawable) {
  //     // 如果是文本对象，添加到文本缓存
  //     if (next.text.trim().isNotEmpty) {
  //       // ref.read(textCacheProvider.notifier).addText(next.text); // textCacheProvider not found
  //     }
  //   }
  // }
}
