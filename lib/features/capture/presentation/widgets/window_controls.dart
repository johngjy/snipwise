import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 窗口控制按钮组件
class WindowControls extends StatelessWidget {
  /// 最小化窗口回调
  final VoidCallback onMinimize;

  /// 关闭窗口回调
  final VoidCallback onClose;

  /// 构造函数
  const WindowControls({
    super.key,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: IconButton(
            icon: const Icon(Icons.minimize,
                color: AppColors.primaryText, size: 18),
            onPressed: onMinimize,
            padding: const EdgeInsets.all(4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: IconButton(
            icon:
                const Icon(Icons.close, color: AppColors.primaryText, size: 18),
            onPressed: onClose,
            padding: const EdgeInsets.all(4),
          ),
        ),
      ],
    );
  }
}
