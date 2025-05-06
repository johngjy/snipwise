import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// 集成缩放控制组件
class ZoomControl extends StatelessWidget {
  /// 当前缩放比例
  final double zoomLevel;

  /// 最小缩放比例
  final double minZoom;

  /// 最大缩放比例
  final double maxZoom;

  /// 缩放比例变化回调
  final Function(double) onZoomChanged;

  /// 缩放菜单点击回调
  final VoidCallback onZoomMenuTap;

  /// 用于缩放菜单的LayerLink
  final LayerLink zoomLayerLink;

  /// 按钮Key
  final GlobalKey? buttonKey;

  /// 缩放按钮尺寸
  final double buttonSize;

  /// 是否显示缩放值的文本
  final bool showZoomText;

  /// 适合窗口的缩放级别
  final double fitZoomLevel;

  const ZoomControl({
    super.key,
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    required this.onZoomMenuTap,
    required this.zoomLayerLink,
    required this.fitZoomLevel,
    this.buttonKey,
    this.buttonSize = 30.0,
    this.showZoomText = true,
  });

  @override
  Widget build(BuildContext context) {
    final int zoomPercent = (zoomLevel * 100).round();
    final String zoomText = '$zoomPercent%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: zoomLayerLink,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFDFDFDF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.03 * 255).round()),
                  blurRadius: 0.5,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: buttonKey,
                borderRadius: BorderRadius.circular(5),
                onTap: onZoomMenuTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        zoomText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        PhosphorIcons.caretDown(PhosphorIconsStyle.light),
                        size: 12,
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: SizedBox(
            width: 100,
            child: Slider(
              value: zoomLevel,
              min: minZoom,
              max: maxZoom,
              onChanged: onZoomChanged,
              activeColor: Colors.grey[700],
              inactiveColor: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }
}

/// 缩放菜单组件
class ZoomMenu extends StatelessWidget {
  /// 缩放选项列表
  final List<String> zoomOptions;

  /// 当前缩放级别
  final double currentZoom;

  /// 选项选择回调
  final Function(String) onOptionSelected;

  /// 适合窗口的缩放级别
  final double fitZoomLevel;

  const ZoomMenu({
    super.key,
    required this.zoomOptions,
    required this.currentZoom,
    required this.onOptionSelected,
    required this.fitZoomLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: zoomOptions.map((option) {
          final bool isSelected = option == '${(currentZoom * 100).toInt()}%' ||
              (option == 'Fit window' && currentZoom == fitZoomLevel);

          return InkWell(
            onTap: () => onOptionSelected(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFF5F5F5) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? PhosphorIcons.check(PhosphorIconsStyle.fill)
                        : PhosphorIcons.checkCircle(PhosphorIconsStyle.light),
                    size: 14,
                    color: isSelected ? Colors.blue : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.blue : Colors.grey[800],
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
