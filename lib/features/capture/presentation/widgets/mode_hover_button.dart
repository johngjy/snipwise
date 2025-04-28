import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart'; // Remove unused
import 'dart:async';

import '../widgets/mode_menu_item.dart';
import '../../data/models/capture_mode.dart';
// import '../../../../core/services/window_service.dart'; // Remove unused

class ModeHoverButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<ModeMenuItem> menuItems;
  final Function(CaptureMode) onModeSelected;

  const ModeHoverButton({
    super.key,
    required this.icon,
    required this.label,
    required this.menuItems,
    required this.onModeSelected,
  });

  @override
  State<ModeHoverButton> createState() => _ModeHoverButtonState();
}

class _ModeHoverButtonState extends State<ModeHoverButton> {
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _hideTimer?.cancel();
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 180,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40), // Position below the button
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            shadowColor: Colors.black.withAlpha(
                (0.1 * 255).round()), // Replace deprecated withOpacity
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: MouseRegion(
                onEnter: (event) => _cancelHideTimer(),
                onExit: (event) => _startHideTimer(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.menuItems
                      .map((item) => _buildMenuItem(context, item))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!); // context used synchronously
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 200), () {
      _removeOverlay();
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  Widget _buildMenuItem(BuildContext context, ModeMenuItem item) {
    return InkWell(
      onTap: () {
        widget.onModeSelected(item.mode);
        _removeOverlay();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 16,
              color: const Color(0xFF333333),
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (event) {
          setState(() {
            _isHovering = true;
          });
          _showOverlay();
        },
        onExit: (event) {
          setState(() {
            _isHovering = false;
          });
          _startHideTimer();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovering ? Colors.grey[200] : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.grey[800]),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
