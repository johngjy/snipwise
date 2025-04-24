import 'package:flutter/material.dart';
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

  const FreeformSelection({
    super.key,
    required this.onSelectionComplete,
    required this.onSelectionCancel,
  });

  @override
  State<FreeformSelection> createState() => _FreeformSelectionState();
}

class _FreeformSelectionState extends State<FreeformSelection> {
  final List<Offset> _points = [];
  Path? _currentPath;
  Rect? _boundingBox;

  void _onPanStart(DragStartDetails details) {
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
      // 闭合路径
      _currentPath?.close();

      // 完成选择
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
      widget.onSelectionCancel();
    }
  }

  void _updateBoundingBox() {
    if (_points.isEmpty) return;

    double minX = _points[0].dx;
    double minY = _points[0].dy;
    double maxX = _points[0].dx;
    double maxY = _points[0].dy;

    for (final point in _points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    _boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.transparent,
        child: CustomPaint(
          painter: _FreeformSelectionPainter(
            points: _points,
            path: _currentPath,
            boundingBox: _boundingBox,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _FreeformSelectionPainter extends CustomPainter {
  final List<Offset> points;
  final Path? path;
  final Rect? boundingBox;

  _FreeformSelectionPainter({
    required this.points,
    this.path,
    this.boundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (path != null) {
      canvas.drawPath(path!, paint);
    }

    if (boundingBox != null) {
      canvas.drawRect(boundingBox!, paint);
    }
  }

  @override
  bool shouldRepaint(_FreeformSelectionPainter oldDelegate) {
    return points != oldDelegate.points ||
        path != oldDelegate.path ||
        boundingBox != oldDelegate.boundingBox;
  }
}
