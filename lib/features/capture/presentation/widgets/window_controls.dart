import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:io' show Platform;

/// 窗口控制组件 - 最小化和关闭按钮
class WindowControls extends StatelessWidget {
  /// 最小化回调
  final VoidCallback onMinimize;

  /// 关闭回调
  final VoidCallback onClose;

  /// 构造函数
  const WindowControls({
    super.key,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // 在 macOS 上完全隐藏自定义按钮，使用系统原生按钮
    if (Platform.isMacOS) {
      return const SizedBox.shrink(); // 返回空组件，完全不显示
    }

    // 非 macOS 平台使用自定义按钮
    return Row(
      children: [
        // 最小化按钮
        _buildControlButton(
          icon: PhosphorIcons.minus(PhosphorIconsStyle.light),
          color: Colors.transparent,
          iconColor: const Color(0xFF666666),
          onPressed: onMinimize,
        ),

        // 关闭按钮
        _buildControlButton(
          icon: PhosphorIcons.x(PhosphorIconsStyle.light),
          color: Colors.transparent,
          iconColor: const Color(0xFF666666),
          onPressed: onClose,
        ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
