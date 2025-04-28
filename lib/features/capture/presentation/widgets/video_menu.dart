import 'package:flutter/material.dart';

/// 视频录制的子菜单，显示视频录制和GIF录制选项
class VideoMenu extends StatelessWidget {
  /// 点击视频录制的回调
  final VoidCallback onVideoCapture;

  /// 点击GIF录制的回调
  final VoidCallback onGifCapture;

  const VideoMenu({
    super.key,
    required this.onVideoCapture,
    required this.onGifCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVideoOption('Video Recording', onVideoCapture),
          const Divider(height: 1, thickness: 0.5),
          _buildVideoOption('GIF Recording', onGifCapture),
        ],
      ),
    );
  }

  Widget _buildVideoOption(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
