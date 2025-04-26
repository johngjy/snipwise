import 'package:flutter/material.dart';

/// 延时捕获的子菜单，显示不同的延时选项
class DelayMenu extends StatelessWidget {
  /// 点击3秒延迟的回调
  final VoidCallback onDelay3Seconds;

  /// 点击5秒延迟的回调
  final VoidCallback onDelay5Seconds;

  /// 点击10秒延迟的回调
  final VoidCallback onDelay10Seconds;

  const DelayMenu({
    super.key,
    required this.onDelay3Seconds,
    required this.onDelay5Seconds,
    required this.onDelay10Seconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDelayOption('3 seconds', onDelay3Seconds),
          const Divider(height: 1),
          _buildDelayOption('5 seconds', onDelay5Seconds),
          const Divider(height: 1),
          _buildDelayOption('10 seconds', onDelay10Seconds),
        ],
      ),
    );
  }

  Widget _buildDelayOption(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
