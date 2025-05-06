import 'package:flutter/material.dart';

/// 精简的设置滑块组件
class SettingSlider extends StatelessWidget {
  /// 当前值
  final double value;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 值变化回调
  final ValueChanged<double> onChanged;

  /// 分段数 - 如果指定，则滑块会有分段效果
  final int? divisions;

  /// 滑块高度
  final double height;

  /// 设置项标题
  final String? title;

  /// 创建设置滑块
  const SettingSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.height = 16,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sliderValue = value.clamp(min, max);
    final normalizedValue = ((sliderValue - min) / (max - min)).clamp(0.0, 1.0);

    // 如果有标题，则显示带标题的布局
    if (title != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和值
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
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
          _buildSlider(sliderValue),
          const SizedBox(height: 8),
        ],
      );
    }

    // 无标题的布局
    return SizedBox(
      height: height,
      child: Row(
        children: [
          // 值显示
          SizedBox(
            width: 28,
            child: Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF777777),
              ),
            ),
          ),

          // 滑块
          Expanded(
            child: _buildSlider(sliderValue),
          ),
        ],
      ),
    );
  }

  /// 构建滑块组件
  Widget _buildSlider(double sliderValue) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6,
          disabledThumbRadius: 4,
        ),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: Colors.blue.shade400,
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: Colors.white,
        overlayColor: Colors.transparent,
      ),
      child: Slider(
        value: sliderValue,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  /// 格式化值显示
  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
