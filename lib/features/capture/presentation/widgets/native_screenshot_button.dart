import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/platform_channel.dart';

/// 原生截图按钮 - 使用orderOut方式隐藏窗口的实现
class NativeScreenshotButton extends StatelessWidget {
  final VoidCallback? onScreenshotTaken;
  final double? width;
  final double? height;

  final Logger _logger = Logger();

  NativeScreenshotButton({
    Key? key,
    this.onScreenshotTaken,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _handleScreenshot(context),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.screenshot,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '原生截图',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleScreenshot(BuildContext context) async {
    _logger.d('开始原生截图流程');

    try {
      // 显示加载指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('开始截图，窗口将隐藏...'),
          duration: Duration(milliseconds: 800),
        ),
      );

      // 使用平台通道服务执行截图
      final PlatformChannelService service = PlatformChannelService.instance;
      final String? imagePath = await service.startScreenshotFlow();

      if (!context.mounted) return;

      if (imagePath != null && File(imagePath).existsSync()) {
        _logger.d('截图成功: $imagePath');

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('截图成功: ${imagePath.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );

        // 触发回调
        onScreenshotTaken?.call();
      } else {
        _logger.w('截图失败或已取消');

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('截图未完成或已取消'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _logger.e('截图过程中发生错误', error: e);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('截图失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
