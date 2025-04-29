import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../application/states/annotation_state.dart';
import '../../application/states/tool_state.dart';
import '../../application/notifiers/annotation_notifier.dart';
import 'image_viewer.dart';

/// 带标注功能的图像查看器组件
class ImageViewerWithAnnotations extends StatefulWidget {
  /// 图像数据
  final Uint8List? imageData;

  /// 截图时的设备像素比
  final double capturedScale;

  /// 变换控制器
  final TransformationController transformController;

  /// 标注列表
  final List<EditorObject> annotations;

  /// 选中的工具
  final EditorTool selectedTool;

  /// 是否按下Shift键
  final bool isShiftPressed;

  /// 最小缩放比例
  final double minZoom;

  /// 最大缩放比例
  final double maxZoom;

  /// 当前缩放比例
  final double zoomLevel;

  /// 鼠标滚轮事件回调
  final Function(PointerScrollEvent)? onMouseScroll;

  /// 缩放变化回调
  final Function(double)? onZoomChanged;

  /// 创建新标注的回调
  final Function(Rect)? onCreateAnnotation;

  /// 选择标注的回调
  final Function(String?)? onSelectAnnotation;

  /// 可用区域大小变化回调
  final Function(Size)? onAvailableSizeChanged;

  /// 背景颜色
  final Color backgroundColor;

  /// 构造函数
  const ImageViewerWithAnnotations({
    super.key,
    required this.imageData,
    this.capturedScale = 1.0,
    required this.transformController,
    this.annotations = const [],
    this.selectedTool = EditorTool.select,
    this.isShiftPressed = false,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.zoomLevel = 1.0,
    this.onMouseScroll,
    this.onZoomChanged,
    this.onCreateAnnotation,
    this.onSelectAnnotation,
    this.onAvailableSizeChanged,
    this.backgroundColor = Colors.white,
  });

  @override
  State<ImageViewerWithAnnotations> createState() =>
      _ImageViewerWithAnnotationsState();
}

class _ImageViewerWithAnnotationsState
    extends State<ImageViewerWithAnnotations> {
  Offset? _dragStartPoint;
  Offset? _dragEndPoint;
  String? _selectedAnnotationId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.onAvailableSizeChanged != null) {
          widget.onAvailableSizeChanged!(Size(
            constraints.maxWidth,
            constraints.maxHeight,
          ));
        }

        return Stack(
          children: [
            // 基础图像查看器
            ImageViewer(
              imageData: widget.imageData,
              capturedScale: widget.capturedScale,
              transformController: widget.transformController,
              minZoom: widget.minZoom,
              maxZoom: widget.maxZoom,
              zoomLevel: widget.zoomLevel,
              onMouseScroll: widget.onMouseScroll,
              onZoomChanged: widget.onZoomChanged,
              backgroundColor: widget.backgroundColor,
            ),

            // 标注层
            if (widget.annotations.isNotEmpty)
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: AnnotationPainter(
                  annotations: widget.annotations,
                  selectedId: _selectedAnnotationId,
                  transformController: widget.transformController,
                ),
              ),

            // 绘制中的标注预览
            if (_dragStartPoint != null &&
                _dragEndPoint != null &&
                widget.selectedTool != EditorTool.select)
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: DrawingPainter(
                  startPoint: _dragStartPoint!,
                  endPoint: _dragEndPoint!,
                  tool: widget.selectedTool,
                  isShiftPressed: widget.isShiftPressed,
                ),
              ),

            // 鼠标事件处理层
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                onTap: () {
                  // 点击背景取消选择
                  if (_selectedAnnotationId != null &&
                      widget.onSelectAnnotation != null) {
                    setState(() {
                      _selectedAnnotationId = null;
                    });
                    widget.onSelectAnnotation!(null);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.selectedTool == EditorTool.select) {
      // 选择工具 - 检查是否点击了某个标注
      final Offset localPosition = details.localPosition;
      _checkAndSelectAnnotation(localPosition);
    } else {
      // 绘图工具 - 开始绘制
      setState(() {
        _dragStartPoint = details.localPosition;
        _dragEndPoint = details.localPosition;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.selectedTool != EditorTool.select && _dragStartPoint != null) {
      setState(() {
        _dragEndPoint = details.localPosition;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.selectedTool != EditorTool.select &&
        _dragStartPoint != null &&
        _dragEndPoint != null &&
        widget.onCreateAnnotation != null) {
      // 创建标注矩形
      final Rect annotationRect =
          Rect.fromPoints(_dragStartPoint!, _dragEndPoint!);

      // 只有当矩形面积足够大时才创建标注
      if (annotationRect.width > 5 && annotationRect.height > 5) {
        // 转换为图像坐标系中的矩形
        final Matrix4 invMatrix =
            Matrix4.inverted(widget.transformController.value);
        final Offset startInImage =
            _transformToImageCoords(_dragStartPoint!, invMatrix);
        final Offset endInImage =
            _transformToImageCoords(_dragEndPoint!, invMatrix);
        final Rect imageRect = Rect.fromPoints(startInImage, endInImage);

        widget.onCreateAnnotation!(imageRect);
      }

      setState(() {
        _dragStartPoint = null;
        _dragEndPoint = null;
      });
    }
  }

  void _checkAndSelectAnnotation(Offset localPosition) {
    if (widget.annotations.isEmpty) return;

    // 转换点击位置到图像坐标系
    final Matrix4 invMatrix =
        Matrix4.inverted(widget.transformController.value);
    final Offset posInImage = _transformToImageCoords(localPosition, invMatrix);

    // 检查是否点击了某个标注
    for (final annotation in widget.annotations) {
      if (annotation.bounds.contains(posInImage)) {
        setState(() {
          _selectedAnnotationId = annotation.id;
        });
        if (widget.onSelectAnnotation != null) {
          widget.onSelectAnnotation!(annotation.id);
        }
        return;
      }
    }

    // 如果没有点击任何标注，取消选择
    if (_selectedAnnotationId != null && widget.onSelectAnnotation != null) {
      setState(() {
        _selectedAnnotationId = null;
      });
      widget.onSelectAnnotation!(null);
    }
  }

  Offset _transformToImageCoords(Offset viewportPoint, Matrix4 invMatrix) {
    final Vector4 transformedVec = invMatrix.transformed(Vector4(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
      1,
    ));
    return Offset(
      transformedVec.x / transformedVec.w,
      transformedVec.y / transformedVec.w,
    );
  }
}

/// 标注绘制器
class AnnotationPainter extends CustomPainter {
  final List<EditorObject> annotations;
  final String? selectedId;
  final TransformationController transformController;

  AnnotationPainter({
    required this.annotations,
    this.selectedId,
    required this.transformController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Matrix4 matrix = transformController.value;

    // Apply current transformation
    canvas.transform(matrix.storage);

    for (final annotation in annotations) {
      final bool isSelected = annotation.id == selectedId;
      // print('Painting annotation: ${annotation.id}, Selected: $isSelected');

      // Set paint properties based on selection and type
      final Paint paint = Paint()..strokeWidth = 2;

      if (annotation is RectangleAnnotation) {
        paint.color = annotation.strokeColor;
        paint.strokeWidth = annotation.strokeWidth;
        paint.style =
            annotation.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;
        if (annotation.isFilled) {
          paint.color = annotation.fillColor;
        }
        canvas.drawRect(annotation.bounds, paint);
        if (annotation.isFilled && annotation.strokeWidth > 0) {
          // Draw border if filled and strokeWidth > 0
          final borderPaint = Paint()
            ..color = annotation.strokeColor
            ..strokeWidth = annotation.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawRect(annotation.bounds, borderPaint);
        }
      } else if (annotation is EllipseAnnotation) {
        paint.color = annotation.strokeColor;
        paint.strokeWidth = annotation.strokeWidth;
        paint.style =
            annotation.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;
        if (annotation.isFilled) {
          paint.color = annotation.fillColor;
        }
        canvas.drawOval(annotation.bounds, paint);
        if (annotation.isFilled && annotation.strokeWidth > 0) {
          final borderPaint = Paint()
            ..color = annotation.strokeColor
            ..strokeWidth = annotation.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawOval(annotation.bounds, borderPaint);
        }
      } else if (annotation is ArrowAnnotation) {
        paint.color = annotation.strokeColor;
        paint.strokeWidth = annotation.strokeWidth;
        paint.style = PaintingStyle.stroke;
        _drawArrow(canvas, annotation.start, annotation.end, paint);
      } else if (annotation is LineAnnotation) {
        paint.color = annotation.strokeColor;
        paint.strokeWidth = annotation.strokeWidth;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(annotation.start, annotation.end, paint);
      } else if (annotation is TextAnnotation) {
        // Draw background if enabled
        if (annotation.hasBackground) {
          final backgroundPaint = Paint()
            ..color = annotation.backgroundColor
            ..style = PaintingStyle.fill;
          canvas.drawRect(annotation.bounds.inflate(2),
              backgroundPaint); // Add small padding
        }
        // Draw text
        final textPainter = TextPainter(
          text: TextSpan(text: annotation.text, style: annotation.textStyle),
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: annotation.bounds.width);
        textPainter.paint(canvas, annotation.bounds.topLeft);

        // Draw border if selected
        if (isSelected) {
          final borderPaint = Paint()
            ..color = Colors.blue // Selection color
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
          _drawDashedRect(
              canvas, annotation.bounds.inflate(2), borderPaint, 4, 2);
        }
      }

      // Draw selection handles if selected
      if (isSelected && annotation is! TextAnnotation) {
        _drawSelectionHandles(canvas, annotation.bounds);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // ... arrow drawing logic ...
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, double dashWidth,
      double dashSpace) {
    // ... dashed rect logic ...
  }

  void _drawSelectionHandles(Canvas canvas, Rect bounds) {
    const double handleSize = 8.0;
    final Paint handlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Example: Top-left handle
    canvas.drawRect(
        Rect.fromLTWH(bounds.left - handleSize / 2, bounds.top - handleSize / 2,
            handleSize, handleSize),
        handlePaint);
    // ... draw other handles ...
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: Implement proper repaint logic
    return true;
  }
}

/// 绘制中的标注预览
class DrawingPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final EditorTool tool;
  final bool isShiftPressed;

  DrawingPainter({
    required this.startPoint,
    required this.endPoint,
    required this.tool,
    this.isShiftPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Debug print for drawing
    // print(
    //     'Drawing preview: Tool=${tool}, Start=${startPoint}, End=${endPoint}, isShift=${isShiftPressed}');

    // Example: Draw rectangle
    if (tool == EditorTool.rectangle) {
      final rect = Rect.fromPoints(startPoint, endPoint);
      canvas.drawRect(rect, paint);
    } else if (tool == EditorTool.ellipse) {
      final rect = Rect.fromPoints(startPoint, endPoint);
      canvas.drawOval(rect, paint);
    } else if (tool == EditorTool.arrow) {
      _drawArrow(canvas, startPoint, endPoint, paint);
    } else if (tool == EditorTool.line) {
      canvas.drawLine(startPoint, endPoint, paint);
    } else if (tool == EditorTool.text) {
      // Draw text bounding box preview
      final rect = Rect.fromPoints(startPoint, endPoint);
      final textPainter = TextPainter(
        text:
            const TextSpan(text: 'Text', style: TextStyle(color: Colors.black)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, rect.topLeft);
      // Draw dashed border for text box
      final dashPaint = Paint()
        ..color = Colors.grey.withOpacity(0.8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      _drawDashedRect(canvas, rect, dashPaint, 5, 3);
    }
    // Add other tools as needed
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // ... arrow drawing logic ...
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, double dashWidth,
      double dashSpace) {
    // ... dashed rect logic ...
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
