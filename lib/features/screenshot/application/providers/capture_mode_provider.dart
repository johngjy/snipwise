import 'package:flutter/material.dart';
import '../../domain/entities/capture_mode.dart';

/// 截图模式状态管理
class CaptureModeProvider extends ChangeNotifier {
  // 当前选择的模式
  CaptureMode _currentMode = CaptureMode.rectangle;

  // 固定尺寸模式的预设尺寸
  Size? _fixedSize;

  // 获取当前模式
  CaptureMode get currentMode => _currentMode;

  // 获取当前模式的配置
  CaptureModeConfig get currentConfig =>
      CaptureModeConfigs.configs[_currentMode]!;

  // 获取固定尺寸
  Size? get fixedSize => _fixedSize;

  // 设置截图模式
  void setMode(CaptureMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  // 设置固定尺寸
  void setFixedSize(Size size) {
    _fixedSize = size;
    if (_currentMode != CaptureMode.fixedSize) {
      _currentMode = CaptureMode.fixedSize;
    }
    notifyListeners();
  }

  // 重置为默认模式
  void resetToDefault() {
    _currentMode = CaptureMode.rectangle;
    _fixedSize = null;
    notifyListeners();
  }

  // 检查是否为特定模式
  bool isMode(CaptureMode mode) => _currentMode == mode;
}
