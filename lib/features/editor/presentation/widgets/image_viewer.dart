import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;

/// 图像查看器组件
///
/// 用于在编辑器中显示和操作图像
class ImageViewer extends StatefulWidget {
  /// 图像数据
  final Uint8List? imageData;

  /// 截图时的设备像素比
  final double capturedScale;

  /// 变换控制器
  final TransformationController transformController;

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

  /// 背景颜色
  final Color backgroundColor;

  const ImageViewer({
    super.key,
    required this.imageData,
    this.capturedScale = 1.0,
    required this.transformController,
    this.minZoom = 0.1,
    this.maxZoom = 5.0,
    this.zoomLevel = 1.0,
    this.onMouseScroll,
    this.onZoomChanged,
    this.backgroundColor = Colors.white,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  ui.Image? _uiImage;
  Size? _imageSize;
  Size? _logicalImageSize;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageData != widget.imageData) {
      _loadImage();
    }
  }

  /// 加载图像数据
  Future<void> _loadImage() async {
    if (widget.imageData == null) {
      setState(() {
        _isLoading = false;
        _uiImage = null;
        _imageSize = null;
        _logicalImageSize = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 解码图像
      final codec = await ui.instantiateImageCodec(widget.imageData!);
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _uiImage = frame.image;
          _imageSize = Size(
            _uiImage!.width.toDouble(),
            _uiImage!.height.toDouble(),
          );

          // 计算逻辑尺寸（考虑设备像素比）
          _logicalImageSize = Size(
            _imageSize!.width / widget.capturedScale,
            _imageSize!.height / widget.capturedScale,
          );

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_uiImage == null || _logicalImageSize == null) {
      return const Center(
        child: Text('无法加载图像'),
      );
    }

    // 计算缩放后的逻辑尺寸
    final double logicalWidth = _logicalImageSize!.width * widget.zoomLevel;
    final double logicalHeight = _logicalImageSize!.height * widget.zoomLevel;

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent &&
            widget.onMouseScroll != null) {
          widget.onMouseScroll!(pointerSignal);
        }
      },
      child: InteractiveViewer(
        transformationController: widget.transformController,
        minScale: widget.minZoom,
        maxScale: widget.maxZoom,
        onInteractionUpdate: (details) {
          // 从变换矩阵中提取缩放值
          if (widget.onZoomChanged != null) {
            final scale = widget.transformController.value.getMaxScaleOnAxis();
            widget.onZoomChanged!(scale);
          }
        },
        child: Container(
          color: widget.backgroundColor,
          alignment: Alignment.center,
          child: SizedBox(
            width: logicalWidth,
            height: logicalHeight,
            child: Image.memory(
              widget.imageData!,
              fit: BoxFit.contain,
              scale: widget.capturedScale,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
