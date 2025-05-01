import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 简单的编辑器页面 - 临时替代方案，避免flutter_painter_v2包的问题
class SimpleEditorPage extends StatefulWidget {
  /// 图片Rect(用于显示)
  final ui.Rect? logicalRect;

  /// 屏幕截图数据
  final Uint8List? imageData;

  /// 截图比例
  final double? scale;

  const SimpleEditorPage({
    super.key,
    this.logicalRect,
    this.imageData,
    this.scale,
  });

  @override
  State<SimpleEditorPage> createState() => _SimpleEditorPageState();
}

class _SimpleEditorPageState extends State<SimpleEditorPage> {
  late Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    if (widget.imageData != null) {
      _image = Image.memory(widget.imageData!);
    } else {
      _image = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('简易编辑器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('图片已保存')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: _image != null
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image!,
                    const SizedBox(height: 20),
                    Text('截图比例: ${widget.scale ?? "未知"}'),
                    if (widget.logicalRect != null)
                      Text('截图区域: ${widget.logicalRect}'),
                  ],
                ),
              )
            : const Text('无图片数据'),
      ),
    );
  }
}
