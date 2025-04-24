import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/services/file_service.dart';

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
  // 图片数据
  Uint8List? _imageData;

  // 选择的工具
  String _selectedTool = 'select';

  // 导出服务
  final ExportService _exportService = ExportService(FileService());

  @override
  void initState() {
    super.initState();
    _imageData = widget.imageData;
    _loadImageIfNeeded();
  }

  /// 如果提供了图片路径而不是数据，则加载图片
  Future<void> _loadImageIfNeeded() async {
    if (_imageData == null && widget.imagePath != null) {
      final fileService = FileService();
      final data = await fileService.loadImageFromPath(widget.imagePath!);
      if (data != null && mounted) {
        setState(() {
          _imageData = data;
        });
      }
    }
  }

  /// 保存编辑后的图片
  Future<void> _saveImage() async {
    if (_imageData != null) {
      final result = await _exportService.exportImage(
        _imageData!,
        'snipwise_${DateTime.now().millisecondsSinceEpoch}',
        format: ExportFormat.png,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片已保存到: $result')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SNIPWISE',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.minimize),
            onPressed: () {
              // 最小化窗口逻辑
            },
          ),
          IconButton(
            icon: const Icon(Icons.crop_square),
            onPressed: () {
              // 窗口最大化/还原逻辑
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 主工具栏
          _buildMainToolbar(),

          // 编辑工具栏
          _buildEditingToolbar(),

          // 图片编辑区域
          Expanded(
            child: _imageData != null
                ? _buildImageEditor()
                : const Center(
                    child: Text(
                      'No image to edit',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
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
          _buildToolbarButton(
            icon: Icons.add_circle_outline,
            label: 'New',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          _buildToolbarButton(
            icon: Icons.high_quality,
            label: 'HD Snip',
            onPressed: () {},
          ),
          _buildToolbarButton(
            icon: Icons.videocam_outlined,
            label: 'Video',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildToolbarButton(
            icon: Icons.grid_view,
            label: 'Mode',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildToolbarButton(
            icon: Icons.timer_outlined,
            label: 'Delay',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildToolbarButton(
            icon: Icons.folder_open_outlined,
            label: 'Open',
            onPressed: () {},
            showDropdown: true,
          ),
          _buildToolbarButton(
            icon: Icons.history,
            label: 'History',
            onPressed: () {},
            showDropdown: true,
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
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
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
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
                Icon(icon, size: 22, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (showDropdown) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: Colors.black54),
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
    final isSelected = _selectedTool == tool && !isAction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isSelected ? Colors.blue.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onPressed ??
                () {
                  if (!isAction) {
                    _setTool(tool);
                  }
                },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
