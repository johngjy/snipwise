import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;

/// 矩形选择组件
class RectangleSelection extends StatefulWidget {
  /// 背景图片数据
  final Uint8List backgroundImage;

  /// 选择完成回调
  final Function(Rect) onSelected;

  /// 取消选择回调
  final VoidCallback onCancel;

  const RectangleSelection({
    super.key,
    required this.backgroundImage,
    required this.onSelected,
    required this.onCancel,
  });

  @override
  State<RectangleSelection> createState() => _RectangleSelectionState();
}

class _RectangleSelectionState extends State<RectangleSelection> {
  Offset? _start;
  Offset? _current;

  @override
  void initState() {
    super.initState();
    developer.log('RectangleSelection 初始化', name: 'RectangleSelection');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    developer.log(
        'RectangleSelection 构建，屏幕尺寸: ${screenSize.width}x${screenSize.height}',
        name: 'RectangleSelection');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        maintainBottomViewPadding: false,
        child: GestureDetector(
          onPanStart: (details) {
            developer.log('开始绘制选择框: ${details.localPosition}',
                name: 'RectangleSelection');
            setState(() {
              _start = details.localPosition;
              _current = _start;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _current = details.localPosition;
            });
          },
          onPanEnd: (_) {
            if (_start != null && _current != null) {
              final rect = Rect.fromPoints(_start!, _current!);
              developer.log('完成选择，区域: $rect', name: 'RectangleSelection');
              widget.onSelected(rect);
            } else {
              developer.log('无效的选择', name: 'RectangleSelection');
              widget.onCancel();
            }
            _resetSelection();
          },
          onPanCancel: () {
            developer.log('取消选择', name: 'RectangleSelection');
            _resetSelection();
            widget.onCancel();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景图片
              Positioned.fill(
                child: Image.memory(
                  widget.backgroundImage,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    developer.log('加载背景图片失败: $error',
                        name: 'RectangleSelection', error: error);
                    return const Center(
                      child: Text('无法加载背景图片',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    );
                  },
                ),
              ),

              // 半透明遮罩，始终显示
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha((255 * 0.3).round()),
                ),
              ),

              // 选择区域
              if (_start != null && _current != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SelectionPainter(
                      selectionRect: Rect.fromPoints(_start!, _current!),
                    ),
                    isComplex: true,
                    willChange: true,
                  ),
                ),

              // 提示文本
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((255 * 0.6).round()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '拖动鼠标选择截图区域，按ESC取消',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetSelection() {
    setState(() {
      _start = null;
      _current = null;
    });
  }
}

/// 选择区域绘制器
class _SelectionPainter extends CustomPainter {
  final Rect selectionRect;

  _SelectionPainter({required this.selectionRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha(76)
      ..style = PaintingStyle.fill;

    // 清除选择区域的遮罩
    canvas.save();
    canvas.clipRect(selectionRect);
    canvas.restore();

    // 绘制选择区域
    canvas.drawRect(selectionRect, paint);

    // 绘制边框
    canvas.drawRect(
      selectionRect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 绘制四个角的标记
    const cornerSize = 8.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 左上角
    canvas.drawLine(selectionRect.topLeft,
        selectionRect.topLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(selectionRect.topLeft,
        selectionRect.topLeft.translate(0, cornerSize), cornerPaint);

    // 右上角
    canvas.drawLine(selectionRect.topRight,
        selectionRect.topRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(selectionRect.topRight,
        selectionRect.topRight.translate(0, cornerSize), cornerPaint);

    // 左下角
    canvas.drawLine(selectionRect.bottomLeft,
        selectionRect.bottomLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(selectionRect.bottomLeft,
        selectionRect.bottomLeft.translate(0, -cornerSize), cornerPaint);

    // 右下角
    canvas.drawLine(selectionRect.bottomRight,
        selectionRect.bottomRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(selectionRect.bottomRight,
        selectionRect.bottomRight.translate(0, -cornerSize), cornerPaint);

    // 显示尺寸信息
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      backgroundColor: Color(0x99000000),
    );
    final textSpan = TextSpan(
      text: '${selectionRect.width.toInt()} x ${selectionRect.height.toInt()}',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas,
        selectionRect.bottomRight.translate(10, -textPainter.height - 5));
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) =>
      selectionRect != oldDelegate.selectionRect;
}
