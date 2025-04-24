import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 工具栏组件 - 显示在顶部的功能按钮
class Toolbar extends StatelessWidget {
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

  /// OCR功能回调
  final VoidCallback onPerformOCR;

  /// 打开图片回调
  final VoidCallback onOpenImage;

  /// 显示历史记录回调
  final VoidCallback onShowHistory;

  /// 构造函数
  const Toolbar({
    super.key,
    required this.onCaptureRegion,
    required this.onCaptureHDScreen,
    required this.onCaptureVideo,
    required this.onCaptureWindow,
    required this.onDelayCapture,
    required this.onPerformOCR,
    required this.onOpenImage,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // 新建按钮
          _buildToolbarItem(
            icon: Icons.add_outlined,
            label: 'New',
            onPressed: onCaptureRegion,
          ),

          // HD截图按钮
          _buildToolbarItem(
            icon: Icons.hd_outlined,
            label: 'HD Snip',
            onPressed: onCaptureHDScreen,
          ),

          // 视频按钮
          _buildToolbarItem(
            icon: Icons.videocam_outlined,
            label: 'Video',
            showDropdown: true,
            onPressed: onCaptureVideo,
          ),

          // 模式按钮
          _buildToolbarItem(
            icon: Icons.grid_view_outlined,
            label: 'Modle',
            showDropdown: true,
            onPressed: onCaptureWindow,
          ),

          // 延迟按钮
          _buildToolbarItem(
            icon: Icons.timer_outlined,
            label: 'Delay',
            showDropdown: true,
            onPressed: onDelayCapture,
          ),

          // OCR按钮
          _buildToolbarItem(
            icon: Icons.text_fields_outlined,
            label: 'OCR',
            onPressed: onPerformOCR,
          ),

          // 打开按钮
          _buildToolbarItem(
            icon: Icons.folder_outlined,
            label: 'Open',
            onPressed: onOpenImage,
          ),

          // 历史按钮
          _buildToolbarItem(
            icon: Icons.history_outlined,
            label: 'History',
            onPressed: onShowHistory,
          ),
        ],
      ),
    );
  }

  /// 构建工具栏项
  Widget _buildToolbarItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool showDropdown = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showDropdown) ...[
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.keyboard_arrow_down_outlined,
                            size: 12,
                            color: AppColors.primaryText,
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
