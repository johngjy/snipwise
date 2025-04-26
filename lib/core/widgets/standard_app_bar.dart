import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/window_service.dart';

/// 标准应用顶部栏 - 用于所有页面共享相同的顶部栏风格
class StandardAppBar extends StatelessWidget {
  /// 是否居中标题
  final bool centerTitle;

  /// 额外的操作按钮
  final List<Widget>? extraActions;

  /// 背景颜色
  final Color? backgroundColor;

  /// 标题颜色
  final Color titleColor;

  /// 控制按钮颜色
  final Color controlsColor;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 返回按钮点击回调
  final VoidCallback? onBackPressed;

  /// 是否强制显示窗口控制按钮（最小化和关闭）
  final bool forceShowWindowControls;

  /// 构造函数
  const StandardAppBar({
    super.key,
    this.centerTitle = true,
    this.extraActions,
    this.backgroundColor,
    this.titleColor = const Color(0xFF333333),
    this.controlsColor = const Color(0xFF9E9E9E),
    this.showBackButton = false,
    this.onBackPressed,
    this.forceShowWindowControls = false,
  });

  @override
  Widget build(BuildContext context) {
    // 检查平台 - 在macOS上默认不显示窗口控制按钮，除非强制显示
    final bool showWindowControls =
        forceShowWindowControls || !Platform.isMacOS;

    return Container(
      height: 36,
      color: backgroundColor,
      child: Stack(
        children: [
          // 可拖拽区域
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                WindowService.instance.startDragging();
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // 标题和控制按钮
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 2.0),
            child: Row(
              children: [
                // 返回按钮（如果需要）
                if (showBackButton)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: controlsColor),
                    onPressed:
                        onBackPressed ?? () => Navigator.of(context).pop(),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),

                // 标题
                if (centerTitle) const Spacer(),
                Text(
                  'SNIPWISE',
                  style: TextStyle(
                    fontFamily: 'Bruno Ace',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                if (centerTitle) const Spacer(),

                // 额外的操作按钮
                if (extraActions != null && extraActions!.isNotEmpty)
                  ...extraActions!,

                // 窗口控制按钮 - 仅在非macOS或强制显示时显示
                if (showWindowControls) ...[
                  IconButton(
                    icon: Icon(Icons.minimize, color: controlsColor, size: 16),
                    onPressed: () => WindowService.instance.minimizeWindow(),
                    tooltip: '最小化',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 14,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, color: controlsColor, size: 16),
                    onPressed: () => WindowService.instance.closeWindow(),
                    tooltip: '关闭',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 14,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
