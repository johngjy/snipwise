import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/routes/app_routes.dart';

/// 截图选择页面 - 打开软件时显示的主页面
class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  bool _isLoadingCapture = false;

  @override
  void initState() {
    super.initState();
    // 注册快捷键
    _registerShortcuts();
  }

  /// 注册快捷键
  void _registerShortcuts() {
    // 实际实现会更复杂一些，这里只是示意
    // 需要使用平台特定的方法注册全局快捷键
  }

  /// 执行截图
  Future<void> _captureScreen() async {
    setState(() {
      _isLoadingCapture = true;
    });

    try {
      // 实际截图逻辑
      // 截图完成后，导航到编辑页面

      // 模拟截图过程
      await Future.delayed(const Duration(seconds: 1));

      // 截图成功后跳转到编辑页面
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.editor,
          arguments: {
            'imageData': null, // 实际应用中会传递截图数据
            'imagePath': null,
          },
        );
      }
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCapture = false;
        });
      }
    }
  }

  /// 执行高清截图
  void _captureHDScreen() {
    // 实现高清截图逻辑
  }

  /// 录制视频
  void _captureVideo() {
    // 实现录制视频逻辑
  }

  /// 打开现有图片
  void _openImage() {
    // 实现打开图片逻辑
  }

  /// 查看历史记录
  void _showHistory() {
    // 实现查看历史记录逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SNIPWISE',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // 在实际应用中，这可能会是最小化窗口而不是关闭应用
              SystemNavigator.pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 工具栏
          _buildToolbar(),

          // 主内容区
          Expanded(
            child: Center(
              child: _isLoadingCapture
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Press Win + Shift + S to take a screenshot',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _captureScreen,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                          ),
                          child: const Text('Take Screenshot Now'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
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
            onPressed: _captureScreen,
          ),
          _buildToolbarButton(
            icon: Icons.high_quality,
            label: 'HD Snip',
            onPressed: _captureHDScreen,
          ),
          _buildToolbarButton(
            icon: Icons.videocam_outlined,
            label: 'Video',
            onPressed: _captureVideo,
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
            icon: Icons.document_scanner_outlined,
            label: 'OCR',
            onPressed: () {},
          ),
          _buildToolbarButton(
            icon: Icons.folder_open_outlined,
            label: 'Open',
            onPressed: _openImage,
          ),
          _buildToolbarButton(
            icon: Icons.history,
            label: 'History',
            onPressed: _showHistory,
          ),
        ],
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
}
