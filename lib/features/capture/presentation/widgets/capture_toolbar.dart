import 'package:flutter/material.dart';

/// 截图工具栏组件 - 简化版，专门用于测试 screen_capturer 功能
class CaptureToolbar extends StatelessWidget {
  /// 区域截图回调
  final VoidCallback onCaptureRegion;

  /// 高清屏幕截图回调
  final VoidCallback onCaptureHDScreen;

  /// 视频录制回调
  final VoidCallback onCaptureVideo;

  /// 窗口截图回调
  final VoidCallback onCaptureWindow;

  /// 延时截图回调
  final VoidCallback onDelayCapture;

  /// 构造函数
  const CaptureToolbar({
    super.key,
    required this.onCaptureRegion,
    required this.onCaptureHDScreen,
    required this.onCaptureVideo,
    required this.onCaptureWindow,
    required this.onDelayCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          // 区域截图按钮
          _buildToolbarButton(
            context,
            icon: Icons.crop_square_outlined,
            label: '区域截图',
            description: '使用 CaptureMode.region 选择区域',
            onPressed: onCaptureRegion,
          ),

          // 全屏截图按钮
          _buildToolbarButton(
            context,
            icon: Icons.fullscreen,
            label: '全屏截图',
            description: '使用 CaptureMode.screen 截取全屏',
            onPressed: onCaptureHDScreen,
          ),

          // 窗口截图按钮
          _buildToolbarButton(
            context,
            icon: Icons.window_outlined,
            label: '窗口截图',
            description: '使用 CaptureMode.window 截取活动窗口',
            onPressed: onCaptureWindow,
          ),

          // 延时截图按钮
          _buildToolbarButton(
            context,
            icon: Icons.timer_outlined,
            label: '延时截图',
            description: '3秒后截取全屏',
            onPressed: onDelayCapture,
          ),

          // 视频录制按钮 (未实现)
          _buildToolbarButton(
            context,
            icon: Icons.videocam_outlined,
            label: '视频录制',
            description: '功能尚未实现',
            onPressed: onCaptureVideo,
            isDisabled: true,
          ),
        ],
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
    bool isDisabled = false,
  }) {
    return Tooltip(
      message: description,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isDisabled
              ? Colors.grey.shade400
              : Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
