import 'package:flutter/material.dart';

/// 设置滑块组件 - 用于调整各种值
class SettingSlider extends StatelessWidget {
  /// 当前值
  final double value;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 值变化回调
  final ValueChanged<double> onChanged;

  /// 是否显示值
  final bool showValue;

  /// 显示方式 - 百分比或者数值
  final bool showAsPercentage;

  /// 构造函数
  const SettingSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.showValue = true,
    this.showAsPercentage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14.0),
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: Colors.white,
                overlayColor: Colors.blue.withOpacity(0.2),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          if (showValue) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                showAsPercentage
                    ? '${(value * 100).round()}%'
                    : value.round().toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
