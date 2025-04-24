// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/delay_dropdown_menu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/clipboard_service.dart';

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

  // 图片尺寸
  Size? _imageSize;

  // 选择的工具
  String _selectedTool = 'select';

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
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
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
    setState(() {
      _selectedTool = tool;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 计算编辑器宽度和高度
    final double editorWidth = _calculateEditorWidth();
    final double editorHeight = _calculateEditorHeight(editorWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SNIPWISE',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.minimize, color: Color(0xFF9E9E9E)),
            onPressed: () {
              // 最小化窗口逻辑
            },
          ),
          IconButton(
            icon: const Icon(Icons.crop_square, color: Color(0xFF9E9E9E)),
            onPressed: () {
              // 窗口最大化/还原逻辑
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SizedBox(
        width: editorWidth,
        height: editorHeight + 120, // 加上工具栏高度
        child: Column(
          children: [
            // 主工具栏
            _buildMainToolbar(),

            // 编辑工具栏
            _buildEditingToolbar(),

            // 图片编辑区域
            Expanded(
              child: _buildImageEditor(),
            ),
          ],
        ),
      ),
    );
  }

  /// 计算编辑器宽度
  double _calculateEditorWidth() {
    // 如果没有图像尺寸，使用最小宽度1000
    if (_imageSize == null) return 1000;

    // 根据图像宽度计算，但确保最小宽度为1000
    return math.max(1000, _imageSize!.width);
  }

  /// 计算编辑器高度
  double _calculateEditorHeight(double width) {
    // 如果没有图像尺寸，使用默认高度600
    if (_imageSize == null) return 600;

    // 如果图像宽度需要缩放，按比例缩放高度
    if (_imageSize!.width > width) {
      final scale = width / _imageSize!.width;
      return _imageSize!.height * scale;
    }

    // 否则使用原始高度
    return _imageSize!.height;
  }

  /// 构建主工具栏
  Widget _buildMainToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildMenuButton(
            icon: Icons.add_circle_outline,
            label: 'New',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          _buildMenuButton(
            icon: Icons.high_quality,
            label: 'HD Snip',
            onPressed: () {},
          ),
          _buildMenuButton(
            icon: Icons.videocam_outlined,
            label: 'Video',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildMenuButton(
            icon: Icons.grid_view,
            label: 'Mode',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildDelayButton(),
          _buildMenuButton(
            icon: Icons.folder_open_outlined,
            label: 'Open',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildMenuButton(
            icon: Icons.history,
            label: 'History',
            onPressed: () {},
            showDropdown: true,
          ),
        ],
      ),
    );
  }

  /// 构建延时按钮
  Widget _buildDelayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            final BuildContext currentContext = context;
            final RenderBox button =
                currentContext.findRenderObject() as RenderBox;
            final Offset offset = button.localToGlobal(Offset.zero);

            showMenu<Duration>(
              context: currentContext,
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + button.size.height,
                offset.dx + button.size.width,
                offset.dy + button.size.height + 200,
              ),
              items: [
                PopupMenuItem<Duration>(
                  padding: EdgeInsets.zero,
                  child: DelayDropdownMenu(
                    onDelaySelected: (duration) {
                      // 处理延时选择
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Selected delay: ${duration.inSeconds} seconds'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined, size: 22, color: Color(0xFF9E9E9E)),
                SizedBox(width: 8),
                Text(
                  'Delay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF9E9E9E)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建编辑工具栏
  Widget _buildEditingToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildEditingToolButton(
            icon: Icons.chat_bubble_outline,
            tooltip: '文字标注',
            tool: 'callout',
          ),
          _buildEditingToolButton(
            icon: Icons.crop_square,
            tooltip: '绘制矩形',
            tool: 'rect',
          ),
          _buildEditingToolButton(
            icon: Icons.straighten,
            tooltip: '测量',
            tool: 'measure',
          ),
          _buildEditingToolButton(
            icon: Icons.filter_b_and_w,
            tooltip: '灰度遮罩',
            tool: 'graymask',
          ),
          _buildEditingToolButton(
            icon: Icons.highlight_alt,
            tooltip: '高亮',
            tool: 'highlight',
          ),
          _buildEditingToolButton(
            icon: Icons.search,
            tooltip: '放大镜',
            tool: 'magnifier',
          ),
          _buildEditingToolButton(
            icon: Icons.document_scanner,
            tooltip: 'OCR文字识别',
            tool: 'ocr',
          ),
          _buildEditingToolButton(
            icon: Icons.auto_fix_high,
            tooltip: '橡皮擦',
            tool: 'rubber',
          ),
          _buildEditingToolButton(
            icon: Icons.undo,
            tooltip: '撤销',
            tool: 'undo',
            isAction: true,
          ),
          _buildEditingToolButton(
            icon: Icons.replay,
            tooltip: '重做',
            tool: 'redo',
            isAction: true,
          ),
          _buildEditingToolButton(
            icon: Icons.zoom_in,
            tooltip: '缩放',
            tool: 'zoom',
            isAction: true,
          ),
          _buildEditingToolButton(
            icon: Icons.copy,
            tooltip: '复制',
            tool: 'copy',
            isAction: true,
            onPressed: _copyImage,
          ),
          _buildEditingToolButton(
            icon: Icons.save,
            tooltip: '保存',
            tool: 'save',
            isAction: true,
            onPressed: _saveImage,
          ),
        ],
      ),
    );
  }

  /// 构建图片编辑区域
  Widget _buildImageEditor() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: _imageData == null
            ? const Text('没有图片数据',
                style: TextStyle(fontSize: 18, color: Colors.grey))
            : Stack(
                children: [
                  // 图片显示区域
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.memory(
                        _imageData!,
                        fit: BoxFit.none, // 不进行缩放，显示原始尺寸
                      ),
                    ),
                  ),

                  // 工具框
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Row(
                      children: [
                        _buildToolButton(Icons.crop, '裁剪'),
                        _buildToolButton(Icons.rotate_right, '旋转'),
                        _buildToolButton(Icons.text_fields, '文字'),
                      ],
                    ),
                  ),

                  // 右上角工具按钮
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      children: [
                        _buildToolButton(Icons.save, '保存', onTap: _saveImage),
                        _buildToolButton(Icons.copy, '复制', onTap: _copyImage),
                        _buildToolButton(Icons.close, '关闭',
                            onTap: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 构建工具按钮
  Widget _buildToolButton(IconData icon, String tooltip,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// 构建菜单按钮
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool showDropdown = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: const Color(0xFF9E9E9E)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                if (showDropdown) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: Color(0xFF9E9E9E)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建编辑工具按钮
  Widget _buildEditingToolButton({
    required IconData icon,
    required String tooltip,
    required String tool,
    bool isAction = false,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed ?? () => _setTool(tool),
        color: _selectedTool == tool ? Colors.blue : Colors.grey.shade700,
        splashRadius: 20,
      ),
    );
  }
}
