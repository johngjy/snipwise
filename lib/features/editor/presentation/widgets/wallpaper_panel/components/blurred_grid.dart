import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/core_providers.dart';
import '../../../../application/states/wallpaper_settings_state.dart';

/// 模糊背景网格组件 - 显示并选择模糊背景预设
class BlurredGrid extends ConsumerWidget {
  const BlurredGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
    final selectedIndex = wallpaperSettings.selectedBlurIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Blurred',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              blurredPresets.length,
              (index) => _buildBlurredItem(
                context,
                ref,
                blurredPresets[index],
                index,
                selectedIndex == index,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个模糊背景项
  Widget _buildBlurredItem(
    BuildContext context,
    WidgetRef ref,
    Color baseColor,
    int index,
    bool isSelected,
  ) {
    final isWhite = baseColor == Colors.white;

    return GestureDetector(
      onTap: () => ref
          .read(wallpaperSettingsProvider.notifier)
          .selectBlurredPreset(index),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (isWhite ? Colors.grey.shade300 : Colors.transparent),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 添加模糊效果示意
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  painter: _BlurPatternPainter(baseColor),
                ),
              ),
            ),

            // 选中指示器
            if (isSelected)
              const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 模糊效果绘制器
class _BlurPatternPainter extends CustomPainter {
  final Color baseColor;

  _BlurPatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = _isDarkColor(baseColor);
    final paint = Paint();

    // 绘制一些随机形状模拟模糊效果
    // 圆形1
    paint.color =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.4,
      paint,
    );

    // 圆形2
    paint.color = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.3,
      paint,
    );

    // 矩形
    paint.color = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.5,
          size.width * 0.6,
          size.height * 0.3,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  /// 判断是否是深色
  bool _isDarkColor(Color color) {
    return (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114) < 128;
  }
}
