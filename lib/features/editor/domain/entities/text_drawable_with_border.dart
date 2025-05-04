import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';

/// 带边框和背景的文本组件
class TextDrawableWithBorder extends TextDrawable {
  /// 边框颜色
  final Color borderColor;

  /// 边框宽度
  final double borderWidth;

  /// 背景颜色
  final Color backgroundColor;

  /// 背景圆角
  final double backgroundRadius;

  /// 背景填充
  final EdgeInsets backgroundPadding;

  /// 文本内边距
  final EdgeInsets padding;

  /// 是否显示背景
  final bool showBackground;

  /// 是否显示边框
  final bool showBorder;

  /// 创建带边框和背景的文本组件
  TextDrawableWithBorder({
    required String text,
    required Offset position,
    required TextStyle style,
    required Size size,
    required this.borderColor,
    required this.borderWidth,
    required this.backgroundColor,
    required this.backgroundRadius,
    required this.backgroundPadding,
    this.padding = const EdgeInsets.all(4.0),
    required this.showBackground,
    required this.showBorder,
    TextDirection textDirection = TextDirection.ltr,
    TextAlign textAlign = TextAlign.left,
    bool locked = false,
    Key? key,
  }) : super(
          text: text,
          position: position,
          style: style,
          size: size,
          textDirection: textDirection,
          textAlign: textAlign,
          locked: locked,
          key: key,
        );

  @override
  void draw(Canvas canvas, Size size) {
    if (text.isEmpty) return;
    
    // 创建文本绘制器
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textAlign: textAlign,
    );
    
    // 计算文本尺寸
    textPainter.layout(maxWidth: this.size.width);
    final textWidth = textPainter.width + backgroundPadding.horizontal;
    final textHeight = textPainter.height + backgroundPadding.vertical;
    
    // 绘制背景
    if (showBackground) {
      final backgroundPaint = Paint()..color = backgroundColor;
      final backgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - backgroundPadding.left,
          position.dy - backgroundPadding.top,
          textWidth,
          textHeight,
        ),
        Radius.circular(backgroundRadius),
      );
      canvas.drawRRect(backgroundRect, backgroundPaint);
    }

    // 绘制边框
    if (showBorder) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      final borderRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - backgroundPadding.left,
          position.dy - backgroundPadding.top,
          textWidth,
          textHeight,
        ),
        Radius.circular(backgroundRadius),
      );
      canvas.drawRRect(borderRect, borderPaint);
    }

    // 绘制文本
    textPainter.paint(
      canvas,
      position,
    );
  }

  @override
  Rect getRect(Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textAlign: textAlign,
    );
    textPainter.layout(maxWidth: this.size.width);
    final textWidth = textPainter.width + backgroundPadding.horizontal;
    final textHeight = textPainter.height + backgroundPadding.vertical;
    return Rect.fromLTWH(
      position.dx - backgroundPadding.left,
      position.dy - backgroundPadding.top,
      textWidth,
      textHeight,
    );
  }

  @override
  bool shouldRepaint(TextDrawableWithBorder oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.position != position ||
        oldDelegate.style != style ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.backgroundRadius != backgroundRadius ||
        oldDelegate.backgroundPadding != backgroundPadding ||
        oldDelegate.padding != padding ||
        oldDelegate.showBackground != showBackground ||
        oldDelegate.showBorder != showBorder;
  }

  @override
  TextDrawableWithBorder copyWith({
    String? text,
    Offset? position,
    TextStyle? style,
    Size? size,
    TextDirection? textDirection,
    TextAlign? textAlign,
    bool? locked,
    Color? borderColor,
    double? borderWidth,
    Color? backgroundColor,
    double? backgroundRadius,
    EdgeInsets? backgroundPadding,
    EdgeInsets? padding,
    bool? showBackground,
    bool? showBorder,
    Key? key,
  }) {
    return TextDrawableWithBorder(
      text: text ?? this.text,
      position: position ?? this.position,
      style: style ?? this.style,
      size: size ?? this.size,
      textDirection: textDirection ?? this.textDirection,
      textAlign: textAlign ?? this.textAlign,
      locked: locked ?? this.locked,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundRadius: backgroundRadius ?? this.backgroundRadius,
      backgroundPadding: backgroundPadding ?? this.backgroundPadding,
      padding: padding ?? this.padding,
      showBackground: showBackground ?? this.showBackground,
      showBorder: showBorder ?? this.showBorder,
      key: key ?? this.key,
    );
  }

  @override
  ui.Size getPreferredSize(Size canvasSize) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    textPainter.layout(maxWidth: canvasSize.width);

    // 计算文本实际尺寸（包含内边距）
    final textWidth = textPainter.width + padding.horizontal;
    final textHeight = textPainter.height + padding.vertical;

    return Size(textWidth, textHeight);
  }
}
