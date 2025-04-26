import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../../data/models/capture_result.dart';

/// 自由形状选择结果
class FreeformSelectionResult {
  final CaptureRegion? region;
  final Path? path;

  FreeformSelectionResult({this.region, this.path});
}

/// 自由形状选择组件
class FreeformSelection extends StatefulWidget {
  final Function(FreeformSelectionResult) onSelectionComplete;
  final VoidCallback onSelectionCancel;
  final Uint8List backgroundImageBytes;

  const FreeformSelection({
    super.key,
    required this.onSelectionComplete,
    required this.onSelectionCancel,
    required this.backgroundImageBytes,
  });

  @override
  State<FreeformSelection> createState() => _FreeformSelectionState();
}

class _FreeformSelectionState extends State<FreeformSelection> {
  final List<Offset> _points = [];
  Path? _currentPath;
  Rect? _boundingBox;

  void _onPanStart(DragStartDetails details) {
    developer.log('Freeform pan start: ${details.localPosition}',
        name: 'FreeformSelection');
    _points.clear();
    _points.add(details.localPosition);
    _currentPath = Path()
      ..moveTo(details.localPosition.dx, details.localPosition.dy);
    _updateBoundingBox();
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _points.add(details.localPosition);
    _currentPath?.lineTo(details.localPosition.dx, details.localPosition.dy);
    _updateBoundingBox();
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_points.isNotEmpty && _currentPath != null && _boundingBox != null) {
      _currentPath?.close();
      developer.log('Freeform pan end, bounds: $_boundingBox',
          name: 'FreeformSelection');
      widget.onSelectionComplete(FreeformSelectionResult(
        region: CaptureRegion(
          x: _boundingBox!.left,
          y: _boundingBox!.top,
          width: _boundingBox!.width,
          height: _boundingBox!.height,
        ),
        path: _currentPath,
      ));
    } else {
      developer.log('Freeform pan end - invalid selection',
          name: 'FreeformSelection');
      widget.onSelectionCancel();
    }
  }

  void _updateBoundingBox() {
    if (_points.isEmpty) {
      _boundingBox = null;
      return;
    }
    double minX = _points[0].dx;
    double minY = _points[0].dy;
    double maxX = _points[0].dx;
    double maxY = _points[0].dy;
    for (final point in _points.skip(1)) {
      minX = math.min(minX, point.dx);
      minY = math.min(minY, point.dy);
      maxX = math.max(maxX, point.dx);
      maxY = math.max(maxY, point.dy);
    }
    _boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building FreeformSelection UI', name: 'FreeformSelection');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        maintainBottomViewPadding: false,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: widget.onSelectionCancel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.memory(
                  widget.backgroundImageBytes,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    developer.log('Failed to load background image: $error',
                        name: 'FreeformSelection');
                    return Center(
                      child: Text(
                        '无法加载背景图像',
                        style: TextStyle(color: Colors.white.withAlpha(178)),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withAlpha(77)),
              ),
              if (_currentPath != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FreeformSelectionPainter(
                      path: _currentPath!,
                      boundingBox: _boundingBox,
                    ),
                    isComplex: true,
                    willChange: true,
                  ),
                ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '拖动鼠标绘制自由形状，按ESC取消',
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
}

class _FreeformSelectionPainter extends CustomPainter {
  final Path path;
  final Rect? boundingBox;

  _FreeformSelectionPainter({
    required this.path,
    this.boundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    if (boundingBox != null) {
      final boundsPaint = Paint()
        ..color = Colors.red.withAlpha(128)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(boundingBox!, boundsPaint);
    }
  }

  @override
  bool shouldRepaint(_FreeformSelectionPainter oldDelegate) {
    return path != oldDelegate.path || boundingBox != oldDelegate.boundingBox;
  }
}
