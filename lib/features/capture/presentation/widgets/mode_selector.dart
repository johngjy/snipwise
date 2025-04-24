import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/capture_mode.dart';
import '../providers/capture_mode_provider.dart';

/// 模式选择器弹出菜单
class ModeSelectorPopup extends StatelessWidget {
  const ModeSelectorPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureModeProvider>(
      builder: (context, provider, child) {
        return PopupMenuButton<CaptureMode>(
          tooltip: 'Select capture mode',
          position: PopupMenuPosition.under,
          onSelected: (CaptureMode mode) {
            provider.setMode(mode);
          },
          itemBuilder: (BuildContext context) {
            return CaptureMode.values.map((CaptureMode mode) {
              final config = CaptureModeConfigs.configs[mode]!;
              return PopupMenuItem<CaptureMode>(
                value: mode,
                child: Row(
                  children: [
                    Icon(
                      config.icon,
                      color: provider.isMode(mode)
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.label,
                            style: TextStyle(
                              color: provider.isMode(mode)
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                              fontWeight: provider.isMode(mode)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            config.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      config.shortcut,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          child: _buildModeButton(context, provider),
        );
      },
    );
  }

  Widget _buildModeButton(BuildContext context, CaptureModeProvider provider) {
    final config = provider.currentConfig;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 20,
            color: const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 8),
          Text(
            config.label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }
}
