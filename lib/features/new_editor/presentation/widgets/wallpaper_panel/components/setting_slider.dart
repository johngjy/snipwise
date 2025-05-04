import 'package:flutter/material.dart';

/// 设置滑块组件
/// 用于壁纸面板中的各种滑块设置
class SettingSlider extends StatelessWidget {
  /// 标题
  final String title;

  /// 当前值
  final double value;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 分段数，如果为空则不使用分段
  final int? divisions;

  /// 值变化回调
  final ValueChanged<double> onChanged;

  /// 构造函数
  const SettingSlider({
    Key? key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和值
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555),
              ),
            ),
            // 值
            Text(
              _formatValue(value),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 滑块
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 12,
            ),
            activeTrackColor: Colors.blue.shade400,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.blue.shade500,
            overlayColor: Colors.blue.shade200.withOpacity(0.3),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// 格式化值，使用适当的精度
  String _formatValue(double value) {
    // 如果值是整数，则显示整数
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    // 否则显示一位小数
    return value.toStringAsFixed(1);
  }
}
