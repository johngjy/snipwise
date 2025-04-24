import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/clipboard_service.dart';

/// 截图预览浮窗组件
class ScreenshotPreview extends StatefulWidget {
  /// 截图数据
  final Uint8List imageData;

  /// 截图路径
  final String? imagePath;

  /// 关闭回调
  final VoidCallback onClose;

  /// 窗口宽度
  final double width;

  const ScreenshotPreview({
    super.key,
    required this.imageData,
    this.imagePath,
    required this.onClose,
    this.width = 300,
  });

  @override
  State<ScreenshotPreview> createState() => _ScreenshotPreviewState();
}

class _ScreenshotPreviewState extends State<ScreenshotPreview> {
  bool _isImageValid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateImage();
  }

  // 验证图像数据是否有效
  void _validateImage() {
    try {
      if (widget.imageData.isEmpty) {
        setState(() {
          _isImageValid = false;
          _errorMessage = '截图数据为空';
        });
        return;
      }

      // 图像数据有效性检查
      if (widget.imageData.length < 100) {
        // 一个基本的PNG图像至少需要100字节
        developer.log('图像数据异常小: ${widget.imageData.length} 字节',
            name: 'ScreenshotPreview');
      }

      setState(() {
        _isImageValid = true;
        _errorMessage = null;
      });
    } catch (e) {
      developer.log('验证图像数据时出错: $e', name: 'ScreenshotPreview', error: e);
      setState(() {
        _isImageValid = false;
        _errorMessage = '无效的图像数据: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      constraints: const BoxConstraints(
        maxHeight: 600, // 最大高度限制
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          _buildTitleBar(context),

          // 图片预览区域
          Flexible(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child:
                  _isImageValid ? _buildImagePreview() : _buildErrorDisplay(),
            ),
          ),
        ],
      ),
    );
  }

  // 构建图像预览
  Widget _buildImagePreview() {
    return Image.memory(
      widget.imageData,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        developer.log('图像渲染错误: $error',
            name: 'ScreenshotPreview', error: error, stackTrace: stackTrace);
        return _buildErrorDisplay(message: '无法显示图像: $error');
      },
    );
  }

  // 构建错误显示
  Widget _buildErrorDisplay({String? message}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? _errorMessage ?? '截图数据无效',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧标题
          const Text(
            '截图预览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          // 右侧操作按钮
          Row(
            children: [
              if (_isImageValid) ...[
                _buildActionButton(
                  icon: Icons.copy,
                  tooltip: '复制到剪贴板',
                  onPressed: () => _copyToClipboard(context),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  tooltip: '编辑',
                  onPressed: () => _openEditor(context),
                ),
              ],
              _buildActionButton(
                icon: Icons.close,
                tooltip: '关闭',
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        color: Colors.grey.shade800,
        splashRadius: 20,
      ),
    );
  }

  /// 复制图片到剪贴板
  void _copyToClipboard(BuildContext context) async {
    try {
      // 使用ClipboardService复制图像
      final clipboardService = ClipboardService();
      final success = await clipboardService.copyImage(widget.imageData);

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '截图已复制到剪贴板' : '复制截图失败'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('复制到剪贴板失败: $e', name: 'ScreenshotPreview', error: e);
      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 打开编辑器
  void _openEditor(BuildContext context) {
    try {
      Navigator.pushNamed(
        context,
        AppRoutes.editor,
        arguments: {
          'imageData': widget.imageData,
          'imagePath': widget.imagePath,
        },
      );
    } catch (e) {
      developer.log('打开编辑器失败: $e', name: 'ScreenshotPreview', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法打开编辑器: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
