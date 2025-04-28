import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A custom menu for zoom controls that appears above the zoom percentage display
class ZoomMenu extends StatelessWidget {
  /// The list of available zoom options
  final List<String> zoomOptions;

  /// The current zoom level as a percentage
  final double currentZoom;

  /// Callback when a zoom option is selected
  final Function(String) onOptionSelected;

  /// The fit zoom level for comparison
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
          // Determine if this option is currently selected
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
