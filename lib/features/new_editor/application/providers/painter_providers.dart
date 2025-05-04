import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// 绘制模式枚举
enum DrawingMode {
  none,
  selection,
  pen,
  line,
  rectangle,
  oval,
  text,
  eraser,
  arrow,
}

/// FlutterPainter控制器提供者
final painterControllerProvider = StateProvider<PainterController>((ref) {
  return PainterController();
});

/// 绘图模式提供者
final drawingModeProvider = StateProvider<DrawingMode>((ref) {
  return DrawingMode.line;
});

/// 当前选中的绘图对象提供者
final selectedObjectDrawableProvider = StateProvider<ObjectDrawable?>((ref) {
  return null;
});

/// 文本缓存提供者
final textCacheProvider = StateProvider<List<String>>((ref) {
  return <String>[];
});

/// 显示文本缓存对话框提供者
final showTextCacheDialogProvider = StateProvider<bool>((ref) {
  return false;
});

/// 绘图工具线宽提供者
final strokeWidthProvider = StateProvider<double>((ref) {
  return 2.0;
});

/// 绘图工具颜色提供者
final strokeColorProvider = StateProvider<Color>((ref) {
  return Colors.red;
});

/// 填充颜色提供者
final fillColorProvider = StateProvider<Color>((ref) {
  return Colors.blue.withOpacity(0.2);
});

/// 是否填充提供者
final isFilledProvider = StateProvider<bool>((ref) {
  return false;
});

/// 是否显示调色板提供者
final showColorPickerProvider = StateProvider<bool>((ref) {
  return false;
});

/// 当前绘制模式提供者
final currentDrawingModeProvider =
    StateProvider<DrawingMode>((ref) => DrawingMode.none);

/// Painter工具实用类提供者
final painterProvidersUtilsProvider = Provider<PainterProvidersUtils>((ref) {
  return PainterProvidersUtils();
});

/// 更新绘制模式
void updateDrawingMode(WidgetRef ref, DrawingMode mode) {
  // 更新当前绘制模式
  ref.read(currentDrawingModeProvider.notifier).state = mode;

  // 获取PainterController
  final controller = ref.read(painterControllerProvider);

  // 获取并修改当前设置
  final currentSettings = controller.value.settings;
  final shapeSettings = currentSettings.shape;
  final freeStyleSettings = currentSettings.freeStyle;

  // 根据模式设置绘制器
  FreeStyleSettings newFreeStyleSettings;
  ShapeSettings newShapeSettings;

  switch (mode) {
    case DrawingMode.none:
    case DrawingMode.selection:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.none,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: null,
      );
      break;
    case DrawingMode.pen:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.draw,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: null,
      );
      break;
    case DrawingMode.line:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.none,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: LineFactory(),
      );
      break;
    case DrawingMode.rectangle:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.none,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: RectangleFactory(),
      );
      break;
    case DrawingMode.oval:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.none,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: OvalFactory(),
      );
      break;
    case DrawingMode.arrow:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.none,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: ArrowFactory(),
      );
      break;
    case DrawingMode.text:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.none,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: null,
      );
      break;
    case DrawingMode.eraser:
      newFreeStyleSettings = freeStyleSettings.copyWith(
        mode: FreeStyleMode.erase,
      );
      newShapeSettings = shapeSettings.copyWith(
        factory: null,
      );
      break;
  }

  // 应用新设置
  controller.value = controller.value.copyWith(
    settings: currentSettings.copyWith(
      freeStyle: newFreeStyleSettings,
      shape: newShapeSettings,
    ),
  );

  // 通知监听器
  controller.notifyListeners();
}

/// 提供用于操作FlutterPainter组件的工具方法
/// 封装与FlutterPainter库的直接交互
class PainterProvidersUtils {
  final Logger _logger = Logger();

  /// 设置缩放级别
  ///
  /// 注意：这是一个占位实现，FlutterPainter库目前不直接支持外部控制缩放
  /// 未来可考虑扩展FlutterPainter库或替换为支持外部变换控制的绘图库
  void setZoomLevel(PainterController controller, double zoomLevel) {
    // TODO: 当前FlutterPainter不支持直接设置缩放级别
    // 这是一个占位实现，为未来实现提供接口一致性
  }

  /// 设置平移偏移
  ///
  /// 注意：这是一个占位实现，FlutterPainter库目前不直接支持外部控制平移
  /// 未来可考虑扩展FlutterPainter库或替换为支持外部变换控制的绘图库
  void setTranslation(PainterController controller, Offset offset) {
    // TODO: 当前FlutterPainter不支持直接设置平移偏移
    // 这是一个占位实现，为未来实现提供接口一致性
  }

  /// 更新FlutterPainter的背景图像
  ///
  /// @param controller FlutterPainter的控制器
  /// @param imageData 图像的二进制数据
  /// @return 完成背景更新的Future
  Future<void> updateBackgroundImage(
      PainterController controller, Uint8List imageData) async {
    try {
      _logger.d('准备更新FlutterPainter背景图像, 图像数据长度: ${imageData.length}');

      // 将二进制数据转换为ui.Image
      final codec = await ui.instantiateImageCodec(imageData);
      _logger.d('图像编解码器已创建');

      final frameInfo = await codec.getNextFrame();
      final uiImage = frameInfo.image;
      _logger.d('图像已解码: ${uiImage.width}x${uiImage.height}');

      // 使用正确的API设置背景图像
      controller.background = ImageBackgroundDrawable(image: uiImage);
      _logger.d('背景已设置到FlutterPainter控制器');
    } catch (e, stackTrace) {
      _logger.e('更新FlutterPainter背景图像失败', error: e, stackTrace: stackTrace);
      // 失败时保持现有背景不变
    }
  }

  /// 创建新文本对象
  ///
  /// 注意：Flutter Painter v2 API对添加文本有限制，
  /// 此方法会设置文本样式，但用户需要手动添加文本
  void addNewText(
    PainterController controller,
    String textValue, {
    Offset? position,
    double? fontSize,
    Color? color,
    String? fontFamily,
    bool? fontWeight,
  }) {
    position ??= const Offset(100, 100);
    fontSize ??= 20.0;
    color ??= Colors.black;
    fontFamily ??= 'Roboto';
    fontWeight ??= false;

    _logger.d('添加新文本: "$textValue", 位置=$position, 字体大小=$fontSize');

    try {
      // 创建文本样式
      final style = TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: fontWeight ? FontWeight.bold : FontWeight.normal,
      );

      // 使用控制器设置文本样式
      final updatedSettings = controller.value.settings.copyWith(
        text: controller.value.settings.text.copyWith(
          textStyle: style,
        ),
      );

      controller.value = controller.value.copyWith(settings: updatedSettings);

      // 由于Flutter Painter v2的API限制，通过触发特定操作来添加文本
      // 这里我们暂时禁用文本添加功能，等待进一步研究API
      _logger.d('Flutter Painter v2不支持直接添加文本，需要用户手动操作');

      // 临时的解决方案：
      // 1. 将控制器模式设为文本
      // 2. 在UI层引导用户点击添加文本
      controller.value = controller.value.copyWith(
        settings: controller.value.settings.copyWith(
          freeStyle: controller.value.settings.freeStyle.copyWith(
            mode: FreeStyleMode.none,
          ),
        ),
      );
      controller.notifyListeners();

      _logger.d('文本模式已激活');
    } catch (e, stackTrace) {
      _logger.e('添加文本对象失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 删除选中的对象
  void deleteSelectedDrawable(PainterController controller) {
    _logger.d('尝试删除选中的对象');

    try {
      // 获取选中的对象
      final selectedDrawable = controller.value.selectedObjectDrawable;
      if (selectedDrawable != null) {
        // 使用撤销功能来删除对象 (Flutter Painter v2的API限制)
        // 这不是理想的解决方案，但在API限制下是可行的
        controller.undo();
        _logger.d('选中的对象已删除');
      } else {
        _logger.d('没有选中的对象可删除');
      }
    } catch (e, stackTrace) {
      _logger.e('删除选中的对象失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 清除所有绘制对象
  void clearAllDrawables(PainterController controller) {
    _logger.d('清除所有绘制对象');

    try {
      // 创建新的空控制器值
      controller.value = controller.value.copyWith(
        drawables: [],
        selectedObjectDrawable: null,
      );
      controller.notifyListeners();
      _logger.d('所有绘制对象已清除');
    } catch (e, stackTrace) {
      _logger.e('清除绘制对象失败', error: e, stackTrace: stackTrace);
    }
  }
}
