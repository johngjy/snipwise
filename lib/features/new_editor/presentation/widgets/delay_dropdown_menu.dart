import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// 延时选择下拉菜单
class DelayDropdownMenu extends StatelessWidget {
  /// 选择回调
  final Function(Duration) onDelaySelected;

  const DelayDropdownMenu({
    super.key,
    required this.onDelaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDelayOption(context, const Duration(seconds: 3), '3 秒'),
          _buildDelayOption(context, const Duration(seconds: 5), '5 秒'),
          _buildDelayOption(context, const Duration(seconds: 10), '10 秒'),
        ],
      ),
    );
  }

  Widget _buildDelayOption(
      BuildContext context, Duration duration, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onDelaySelected(duration);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.timer(PhosphorIconsStyle.light),
                size: 18,
                color: const Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
