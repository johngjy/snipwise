import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;

import '../states/annotation_state.dart';
import '../notifiers/annotation_notifier.dart';
import '../states/tool_state.dart';
import 'core_providers.dart';

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

/// Painter工具实用类提供者
final painterProvidersUtilsProvider = Provider<PainterProvidersUtils>((ref) {
  return PainterProvidersUtils();
});

/// 当前绘制模式提供者
final currentDrawingModeProvider =
    StateProvider<DrawingMode>((ref) => DrawingMode.none);

/// 更新绘制模式
void updateDrawingMode(WidgetRef ref, DrawingMode mode) {
  // 更新当前绘制模式
  ref.read(currentDrawingModeProvider.notifier).state = mode;

  // 获取PainterController
  final controller = ref.read(painterControllerProvider);

  // 根据模式设置绘制器
  switch (mode) {
    case DrawingMode.none:
    case DrawingMode.selection:
      controller.freeStyleMode = FreeStyleMode.none;
      controller.shapeFactory = null;
      break;
    case DrawingMode.pen:
      controller.freeStyleMode = FreeStyleMode.draw;
      controller.shapeFactory = null;
      break;
    case DrawingMode.line:
      controller.freeStyleMode = FreeStyleMode.none;
      controller.shapeFactory = LineFactory();
      break;
    case DrawingMode.rectangle:
      controller.freeStyleMode = FreeStyleMode.none;
      controller.shapeFactory = RectangleFactory();
      break;
    case DrawingMode.oval:
      controller.freeStyleMode = FreeStyleMode.none;
      controller.shapeFactory = OvalFactory();
      break;
    case DrawingMode.arrow:
      controller.freeStyleMode = FreeStyleMode.none;
      controller.shapeFactory = ArrowFactory();
      break;
    case DrawingMode.text:
      controller.freeStyleMode = FreeStyleMode.none;
      controller.shapeFactory = null;
      break;
    case DrawingMode.eraser:
      controller.freeStyleMode = FreeStyleMode.erase;
      controller.shapeFactory = null;
      break;
  }
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

      // 创建自定义背景
      final background = CustomBackgroundDrawable(uiImage);
      _logger.d('自定义背景已创建');

      // 设置背景到控制器
      controller.background = background;
      _logger.d('背景已设置到FlutterPainter控制器');
    } catch (e, stackTrace) {
      _logger.e('更新FlutterPainter背景图像失败', error: e, stackTrace: stackTrace);
      // 失败时保持现有背景不变
    }
  }

  // 创建新文本对象
  void addNewText(
    PainterController controller,
    String text, {
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

    // 创建文本样式
    final style = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ? FontWeight.bold : FontWeight.normal,
    );

    // 创建文本绘图对象
    final textDrawable = TextDrawable(
      position: position,
      text: text,
      style: style,
    );

    try {
      // 添加到画布
      controller.addDrawables([textDrawable]);

      // 设置选中的对象
      // 直接使用setter设置选中对象
      controller.value = controller.value.copyWith(
        selectedObjectDrawable: textDrawable,
      );
    } catch (e) {
      if (kDebugMode) {
        _logger.e('添加文本对象失败: $e');
      }
    }
  }
}

/// 自定义背景绘制类
class CustomBackgroundDrawable extends BackgroundDrawable {
  final ui.Image image;
  final Logger _logger = Logger();

  CustomBackgroundDrawable(this.image) {
    _logger.d('CustomBackgroundDrawable创建: ${image.width}x${image.height}');
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size) {
    _logger.d(
        'CustomBackgroundDrawable.draw被调用: 画布大小=${size.width}x${size.height}');
    try {
      // 不使用paintImage，而是直接绘制
      final paint = Paint();
      // 计算适合的矩形
      final imageAspect = image.width / image.height;
      final canvasAspect = size.width / size.height;

      Rect destRect;
      if (imageAspect > canvasAspect) {
        // 图像更宽，以宽度为基准
        final scaledHeight = size.width / imageAspect;
        final offsetY = (size.height - scaledHeight) / 2;
        destRect = Rect.fromLTWH(0, offsetY, size.width, scaledHeight);
      } else {
        // 图像更高，以高度为基准
        final scaledWidth = size.height * imageAspect;
        final offsetX = (size.width - scaledWidth) / 2;
        destRect = Rect.fromLTWH(offsetX, 0, scaledWidth, size.height);
      }

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        destRect,
        paint,
      );
      _logger.d('图像绘制完成: $destRect');
    } catch (e, stack) {
      _logger.e('绘制图像时出错', error: e, stackTrace: stack);
    }
  }
}
