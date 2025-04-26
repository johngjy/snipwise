import 'package:flutter/material.dart';

/// 截图模式枚举
enum CaptureMode {
  rectangle, // 矩形选择
  freeform, // 自由形状
  window, // 窗口截图
  fullscreen, // 全屏截图
  fixedSize, // 固定尺寸
  scrolling, // 滚动截图
  region, // 区域截图
  longscroll, // 长截图（滚动截图）
}

/// 截图模式配置
class CaptureModeConfig {
  final CaptureMode mode;
  final IconData icon;
  final String label;
  final String description;
  final String shortcut;

  const CaptureModeConfig({
    required this.mode,
    required this.icon,
    required this.label,
    required this.description,
    required this.shortcut,
  });
}

/// 截图模式配置列表
class CaptureModeConfigs {
  static const Map<CaptureMode, CaptureModeConfig> configs = {
    CaptureMode.rectangle: CaptureModeConfig(
      mode: CaptureMode.rectangle,
      icon: Icons.crop_square_outlined,
      label: 'Rectangle',
      description: 'Capture a rectangular area',
      shortcut: '⌘ + Shift + R',
    ),
    CaptureMode.freeform: CaptureModeConfig(
      mode: CaptureMode.freeform,
      icon: Icons.gesture,
      label: 'Freeform',
      description: 'Capture a freeform area',
      shortcut: '⌘ + Shift + F',
    ),
    CaptureMode.window: CaptureModeConfig(
      mode: CaptureMode.window,
      icon: Icons.window_outlined,
      label: 'Window',
      description: 'Capture active window',
      shortcut: '⌘ + Shift + W',
    ),
    CaptureMode.fullscreen: CaptureModeConfig(
      mode: CaptureMode.fullscreen,
      icon: Icons.fullscreen,
      label: 'Fullscreen',
      description: 'Capture entire screen',
      shortcut: '⌘ + Shift + S',
    ),
    CaptureMode.fixedSize: CaptureModeConfig(
      mode: CaptureMode.fixedSize,
      icon: Icons.aspect_ratio,
      label: 'Fixed Size',
      description: 'Capture with preset dimensions',
      shortcut: '⌘ + Shift + X',
    ),
    CaptureMode.scrolling: CaptureModeConfig(
      mode: CaptureMode.scrolling,
      icon: Icons.vertical_align_bottom,
      label: 'Scrolling',
      description: 'Capture scrolling content',
      shortcut: '⌘ + Shift + L',
    ),
    CaptureMode.region: CaptureModeConfig(
      mode: CaptureMode.region,
      icon: Icons.screenshot_monitor,
      label: 'Region',
      description: 'Capture a specific region',
      shortcut: '⌘ + Shift + G',
    ),
    CaptureMode.longscroll: CaptureModeConfig(
      mode: CaptureMode.longscroll,
      icon: Icons.vertical_align_center,
      label: 'Long Screenshot',
      description: 'Capture and stitch multiple screenshots',
      shortcut: '⌘ + Shift + J',
    ),
  };
}
