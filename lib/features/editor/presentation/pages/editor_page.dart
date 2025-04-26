// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
// import 'dart:math' as math; // Unused import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart'; // No longer needed here
// import '../widgets/delay_dropdown_menu.dart'; // Removed unused import
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/clipboard_service.dart';
import '../../../../core/widgets/standard_app_bar.dart'; // 导入标准化顶部栏
import '../../../capture/presentation/widgets/toolbar.dart';
import '../widgets/editing_toolbar.dart'; // Import the new toolbar

/// 图片编辑页面 - 截图完成后的编辑界面
class EditorPage extends StatefulWidget {
  /// 图片数据
  final Uint8List? imageData;

  /// 图片路径
  final String? imagePath;

  const EditorPage({
    super.key,
    this.imageData,
    this.imagePath,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _logger = Logger();
  // 图片数据
  Uint8List? _imageData;

  // 选择的工具
  String _selectedTool = 'select'; // Default tool

  @override
  void initState() {
    super.initState();
    _imageData = widget.imageData;
    _loadImageIfNeeded();
  }

  /// 如果提供了图片路径而不是数据，则加载图片
  Future<void> _loadImageIfNeeded() async {
    if (_imageData == null && widget.imagePath != null) {
      try {
        final bytes = await File(widget.imagePath!).readAsBytes();
        if (!mounted) return;
        setState(() {
          _imageData = bytes;
        });
        await _calculateImageSize();
      } catch (e) {
        _logger.e('Error loading image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载图片失败: $e')),
          );
        }
      }
    } else if (widget.imageData != null) {
      _imageData = widget.imageData;
      await _calculateImageSize();
    }
  }

  /// 计算图片尺寸
  Future<void> _calculateImageSize() async {
    if (_imageData != null) {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(_imageData!, (result) {
        completer.complete(result);
      });
      final image = await completer.future;
      if (!mounted) return;
      _logger.d('Image size calculated: ${image.width}x${image.height}');
    }
  }

  /// 保存编辑后的图片
  Future<void> _saveImage() async {
    if (_imageData == null) return;

    try {
      final fileName =
          'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      await File(filePath).writeAsBytes(_imageData!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片已保存至 $filePath')),
      );
    } catch (e) {
      _logger.e('Error saving image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存图片失败')),
      );
    }
  }

  /// 复制图片到剪贴板
  Future<void> _copyImage() async {
    if (_imageData == null) return;

    try {
      // 使用ClipboardService复制图像
      final clipboardService = ClipboardService();
      final success = await clipboardService.copyImage(_imageData!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '图片已复制到剪贴板' : '复制图片失败'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _logger.e('Error copying image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制图片失败')),
      );
    }
  }

  /// 设置当前工具
  void _setTool(String tool) {
    // Add logic here if needed when a tool is selected (e.g., change cursor)
    _logger.i('Tool selected: $tool');
    setState(() {
      _selectedTool = tool;
    });
  }

  // Placeholder action methods for Undo, Redo, Zoom
  void _handleUndo() => _logger.i('Undo action triggered');
  void _handleRedo() => _logger.i('Redo action triggered');
  void _handleZoom() => _logger.i('Zoom action triggered');

  @override
  Widget build(BuildContext context) {
    // 计算编辑器宽度和高度
    // final double editorWidth = _calculateEditorWidth(); // Unused variable
    // final double editorHeight = _calculateEditorHeight(editorWidth); // Unused variable

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 使用标准化顶部栏 - 移除返回按钮
          const StandardAppBar(
            backgroundColor: Color(0xFFF5F5F5), // 浅灰色背景
            centerTitle: true,
            showBackButton: false, // 不显示返回按钮
          ),

          // Capture Toolbar (Top)
          Container(
            color: const Color(0xFFF5F5F5),
            child: Row(
              children: [
                Expanded(
                  child: Toolbar(
                    onCaptureRegion: () => Navigator.pop(context),
                    onCaptureHDScreen: () => _logger.i(
                        'Capture HDScreen triggered from Editor - No action'),
                    onCaptureVideo: () => _logger
                        .i('Capture Video triggered from Editor - No action'),
                    onCaptureWindow: () => _logger
                        .i('Capture Window triggered from Editor - No action'),
                    onCaptureFullscreen: () => _logger.i(
                        'Capture Fullscreen triggered from Editor - No action'),
                    onCaptureRectangle: () => _logger.i(
                        'Capture Rectangle triggered from Editor - No action'),
                    onDelayCapture: () => _logger
                        .i('Delay Capture triggered from Editor - No action'),
                    onPerformOCR: () => _logger.i('OCR triggered from Editor'),
                    onOpenImage: () =>
                        _logger.i('Open Image triggered from Editor'),
                    onShowHistory: () =>
                        _logger.i('Show History triggered from Editor'),
                  ),
                ),
              ],
            ),
          ),

          // Editing Toolbar - Use the new Widget
          EditingToolbar(
            selectedTool: _selectedTool,
            onToolSelected: _setTool,
            onUndo: _handleUndo, // Pass placeholder or real implementation
            onRedo: _handleRedo,
            onZoom: _handleZoom,
            onSave: _saveImage,
            onCopy: _copyImage,
          ),

          // 编辑器内容区域
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: _imageData == null
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(26, 0, 0, 0),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Image.memory(
                            _imageData!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Remove the _buildEditingToolButton method
  // Widget _buildEditingToolButton({ ... }) { ... }

  // 计算编辑器宽度 (Keep if needed elsewhere, otherwise remove)
  // double _calculateEditorWidth() {
  //   return MediaQuery.of(context).size.width;
  // }

  // /// 计算编辑器高度，考虑图像宽高比 // Removed unused method
  // double _calculateEditorHeight(double width) { ... }
}
